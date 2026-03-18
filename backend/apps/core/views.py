from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from .serializers import (
    GuestAuthSerializer,
    LeaderboardSerializer,
    LoginAuthSerializer,
    ProfileSerializer,
    QuestionSerializer,
    QuizResultCreateSerializer,
    RegisterAuthSerializer,
    SessionSerializer,
    StatsSerializer,
)
from .services import (
    build_leaderboard_for_profile,
    build_leaderboard,
    build_profile,
    build_stats,
    create_guest_session,
    create_quiz_attempt,
    filter_questions,
    get_profile_for_user,
    login_simple_account,
    logout_user,
    normalize_limit,
    register_simple_account,
)


class HealthView(APIView):
    authentication_classes = []
    permission_classes = []

    def get(self, request):
        return Response({"status": "ok"})


class QuestionsView(APIView):
    authentication_classes = []
    permission_classes = []

    def get(self, request):
        theme = request.query_params.get("theme")
        level = request.query_params.get("level")
        limit = normalize_limit(request.query_params.get("limit"))
        items = filter_questions(theme, level, limit)
        serializer = QuestionSerializer(items, many=True)

        return Response(
            {
                "items": serializer.data,
                "meta": {
                    "count": len(serializer.data),
                    "limit": limit,
                    "theme": theme,
                    "level": level,
                },
            }
        )


class StatsView(APIView):
    authentication_classes = []
    permission_classes = []

    def get(self, request):
        serializer = StatsSerializer(build_stats())
        return Response(serializer.data)


class LeaderboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        period = request.query_params.get("period", "weekly")
        profile = get_profile_for_user(request.user)
        serializer = LeaderboardSerializer(build_leaderboard_for_profile(period, profile))
        return Response(serializer.data)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = ProfileSerializer(build_profile(get_profile_for_user(request.user)))
        return Response(serializer.data)


class QuizResultView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = QuizResultCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = get_profile_for_user(request.user)
        attempt = create_quiz_attempt(profile, serializer.validated_data)

        return Response(
            {
                "saved": True,
                "attemptId": attempt.id,
                "profile": ProfileSerializer(build_profile(profile)).data,
                "leaderboard": LeaderboardSerializer(build_leaderboard_for_profile("weekly", profile)).data,
            },
            status=201,
        )


class GuestLoginView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        serializer = GuestAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session = create_guest_session(serializer.validated_data["displayName"])
        return Response(SessionSerializer(session).data, status=201)


class RegisterView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        serializer = RegisterAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session = register_simple_account(
            serializer.validated_data["username"],
            serializer.validated_data["password"],
            serializer.validated_data.get("displayName"),
        )
        return Response(SessionSerializer(session).data, status=201)


class LoginView(APIView):
    authentication_classes = []
    permission_classes = []

    def post(self, request):
        serializer = LoginAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session = login_simple_account(
            serializer.validated_data["username"],
            serializer.validated_data["password"],
        )
        return Response(SessionSerializer(session).data)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        logout_user(request.user)
        return Response({"loggedOut": True})
