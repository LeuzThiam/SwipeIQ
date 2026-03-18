import json
import uuid
from pathlib import Path
from typing import Any

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Max, Sum
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import AuthenticationFailed

from .models import PlayerProfile, QuizAttempt


def load_questions() -> list[dict[str, Any]]:
    questions_file = Path(settings.SWIPEIQ_QUESTIONS_FILE)
    if not questions_file.exists():
        return []

    payload = json.loads(questions_file.read_text(encoding="utf-8"))
    return payload.get("questions", [])


def filter_questions(theme: str | None, level: str | None, limit: int) -> list[dict[str, Any]]:
    items = load_questions()

    if theme:
        items = [item for item in items if item.get("theme") == theme]

    if level:
        items = [item for item in items if item.get("level") == level]

    return items[:limit]


def build_stats() -> dict[str, Any]:
    items = load_questions()
    themes = sorted({item.get("theme", "unknown") for item in items})
    levels = sorted({item.get("level", "unknown") for item in items})
    return {
        "totalQuestions": len(items),
        "themes": themes,
        "levels": levels,
    }


def build_profile_payload(profile: PlayerProfile) -> dict[str, Any]:
    attempts = QuizAttempt.objects.filter(profile=profile)
    discovered_themes = sorted({attempt.theme for attempt in attempts if attempt.theme})
    aggregate = attempts.aggregate(
        xp=Sum("score_points"),
        best_streak=Max("best_streak"),
    )
    xp = aggregate.get("xp") or 0
    best_streak = aggregate.get("best_streak") or 0
    quizzes_played = attempts.count()
    level = max(1, xp // 1000 + 1)

    return {
        "name": profile.name,
        "username": profile.user.username if profile.user else "",
        "isGuest": profile.is_guest,
        "level": level,
        "xp": xp,
        "bestStreak": best_streak,
        "quizzesPlayed": quizzes_played,
        "discoveredThemes": len(discovered_themes),
        "availableThemes": discovered_themes,
        "badges": [
            {"icon": "🔥", "label": f"Serie {min(best_streak, 30)}"},
            {"icon": "🧠", "label": f"{len(discovered_themes)} themes"},
            {"icon": "🎯", "label": f"{quizzes_played} quiz"},
        ],
        "dailyGoals": [
            {"label": "Finir 1 defi du jour", "status": "En cours"},
            {"label": f"Explorer {max(1, len(discovered_themes))} theme(s)", "status": "Pret"},
            {"label": f"Jouer {max(3, quizzes_played + 1)} quiz", "status": "A faire"},
        ],
    }


def get_profile_for_user(user: User) -> PlayerProfile:
    if not user or not user.is_authenticated:
        raise AuthenticationFailed("Authentification requise.")

    profile, _ = PlayerProfile.objects.get_or_create(
        user=user,
        defaults={
            "name": user.first_name or user.username,
            "avatar_initial": (user.first_name or user.username or "J")[:1].upper(),
            "is_guest": False,
        },
    )
    return profile


def ensure_unique_display_name(base_name: str) -> str:
    candidate = base_name.strip() or "Joueur"
    if not PlayerProfile.objects.filter(name=candidate).exists():
        return candidate

    suffix = 2
    while PlayerProfile.objects.filter(name=f"{candidate} {suffix}").exists():
        suffix += 1
    return f"{candidate} {suffix}"


def create_guest_session(display_name: str) -> dict[str, Any]:
    safe_name = ensure_unique_display_name(display_name)
    username = f"guest_{uuid.uuid4().hex[:10]}"
    user = User.objects.create(username=username, first_name=safe_name)
    user.set_unusable_password()
    user.save()
    profile = PlayerProfile.objects.create(
        user=user,
        name=safe_name,
        is_guest=True,
        avatar_initial=safe_name[:1].upper(),
    )
    token, _ = Token.objects.get_or_create(user=user)
    return {"token": token.key, "profile": build_profile_payload(profile)}


def register_simple_account(username: str, password: str, display_name: str | None = None) -> dict[str, Any]:
    if User.objects.filter(username=username).exists():
        raise AuthenticationFailed("Ce nom d'utilisateur existe deja.")

    resolved_name = ensure_unique_display_name(display_name or username)
    user = User.objects.create_user(username=username, password=password, first_name=resolved_name)
    profile = PlayerProfile.objects.create(
        user=user,
        name=resolved_name,
        is_guest=False,
        avatar_initial=resolved_name[:1].upper(),
    )
    token, _ = Token.objects.get_or_create(user=user)
    return {"token": token.key, "profile": build_profile_payload(profile)}


def login_simple_account(username: str, password: str) -> dict[str, Any]:
    user = authenticate(username=username, password=password)
    if user is None:
        raise AuthenticationFailed("Identifiants invalides.")

    profile = get_profile_for_user(user)
    token, _ = Token.objects.get_or_create(user=user)
    return {"token": token.key, "profile": build_profile_payload(profile)}


def logout_user(user: User) -> None:
    if not user or not user.is_authenticated:
        return
    Token.objects.filter(user=user).delete()


def build_leaderboard(period: str) -> dict[str, Any]:
    valid_periods = {"daily", "weekly", "global"}
    selected_period = period if period in valid_periods else "weekly"
    current_profile = None
    attempts = QuizAttempt.objects.select_related("profile")

    if selected_period == "daily":
        attempts = attempts.filter(completed_at__gte=timezone.now() - timezone.timedelta(days=1))
    elif selected_period == "weekly":
        attempts = attempts.filter(completed_at__gte=timezone.now() - timezone.timedelta(days=7))

    aggregated = (
        attempts.values("profile_id", "profile__name")
        .annotate(score=Sum("score_points"), streak=Max("best_streak"))
        .order_by("-score", "-streak", "profile__name")
    )

    badge_by_rank = ["🏆", "🔥", "⭐", "⚡", "🎯"]
    entries: list[dict[str, Any]] = []
    for index, row in enumerate(aggregated[:5]):
        entries.append(
            {
                "rank": index + 1,
                "name": row["profile__name"],
                "score": row["score"] or 0,
                "streak": row["streak"] or 0,
                "badge": badge_by_rank[index] if index < len(badge_by_rank) else "•",
                "isCurrentUser": False,
            }
        )

    entries = sorted(entries, key=lambda entry: (-entry["score"], -entry["streak"], entry["name"]))
    for index, entry in enumerate(entries, start=1):
        entry["rank"] = index
        entry["badge"] = badge_by_rank[index - 1] if index - 1 < len(badge_by_rank) else "•"
    return {
        "period": selected_period,
        "generatedFromQuestions": QuizAttempt.objects.count(),
        "currentUser": None,
        "entries": entries,
    }


def build_leaderboard_for_profile(period: str, profile: PlayerProfile) -> dict[str, Any]:
    leaderboard = build_leaderboard(period)
    entries = leaderboard["entries"]
    matching_entry = next((entry for entry in entries if entry["name"] == profile.name), None)

    if matching_entry is None:
        attempts = QuizAttempt.objects.filter(profile=profile)
        score = attempts.aggregate(score=Sum("score_points")).get("score") or 0
        streak = attempts.aggregate(streak=Max("best_streak")).get("streak") or 0
        matching_entry = {
            "rank": len(entries) + 1,
            "name": profile.name,
            "score": score,
            "streak": streak,
            "badge": "•",
            "isCurrentUser": True,
        }
        entries.append(matching_entry)

    for entry in entries:
        entry["isCurrentUser"] = entry["name"] == profile.name

    entries.sort(key=lambda entry: (-entry["score"], -entry["streak"], entry["name"]))
    badge_by_rank = ["🏆", "🔥", "⭐", "⚡", "🎯"]
    for index, entry in enumerate(entries, start=1):
        entry["rank"] = index
        entry["badge"] = badge_by_rank[index - 1] if index - 1 < len(badge_by_rank) else "•"

    leaderboard["entries"] = entries
    leaderboard["currentUser"] = next(entry for entry in entries if entry["isCurrentUser"])
    return leaderboard


def build_profile(profile: PlayerProfile) -> dict[str, Any]:
    return build_profile_payload(profile)


def create_quiz_attempt(profile: PlayerProfile, payload: dict[str, Any]) -> QuizAttempt:
    return QuizAttempt.objects.create(
        profile=profile,
        mode=payload["mode"],
        theme=payload.get("theme") or "",
        level=payload.get("level") or "",
        lang=payload.get("lang") or "fr",
        total_questions=payload["totalQuestions"],
        correct_answers=payload["correctAnswers"],
        best_streak=payload["bestStreak"],
        score_points=payload["scorePoints"],
    )


def normalize_limit(raw_limit: str | None, default: int = 20, max_limit: int = 50) -> int:
    if raw_limit is None:
        return default

    try:
        limit = int(raw_limit)
    except (TypeError, ValueError):
        return default

    return max(1, min(limit, max_limit))
