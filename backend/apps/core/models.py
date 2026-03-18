from django.contrib.auth.models import User
from django.db import models


class PlayerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="player_profile", null=True, blank=True)
    name = models.CharField(max_length=120, unique=True)
    is_guest = models.BooleanField(default=False)
    avatar_initial = models.CharField(max_length=4, default="M")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return self.name


class QuizAttempt(models.Model):
    MODE_CHOICES = [
        ("theme", "Theme"),
        ("quick", "Quick"),
        ("adventure", "Adventure"),
        ("daily", "Daily"),
    ]

    profile = models.ForeignKey(PlayerProfile, on_delete=models.CASCADE, related_name="attempts")
    mode = models.CharField(max_length=24, choices=MODE_CHOICES)
    theme = models.CharField(max_length=120, blank=True)
    level = models.CharField(max_length=60, blank=True)
    lang = models.CharField(max_length=10, default="fr")
    total_questions = models.PositiveIntegerField()
    correct_answers = models.PositiveIntegerField()
    best_streak = models.PositiveIntegerField(default=0)
    score_points = models.PositiveIntegerField(default=0)
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-completed_at"]

    def __str__(self) -> str:
        return f"{self.profile.name} - {self.mode} - {self.score_points}"
