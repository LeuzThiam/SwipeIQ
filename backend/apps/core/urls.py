from django.urls import path

from .views import (
    GuestLoginView,
    HealthView,
    LeaderboardView,
    LoginView,
    LogoutView,
    ProfileView,
    QuestionsView,
    QuizResultView,
    RegisterView,
    StatsView,
)

urlpatterns = [
    path("auth/guest/", GuestLoginView.as_view(), name="auth-guest"),
    path("auth/register/", RegisterView.as_view(), name="auth-register"),
    path("auth/login/", LoginView.as_view(), name="auth-login"),
    path("auth/logout/", LogoutView.as_view(), name="auth-logout"),
    path("health/", HealthView.as_view(), name="health"),
    path("questions/", QuestionsView.as_view(), name="questions"),
    path("stats/", StatsView.as_view(), name="stats"),
    path("leaderboard/", LeaderboardView.as_view(), name="leaderboard"),
    path("profile/", ProfileView.as_view(), name="profile"),
    path("quiz-results/", QuizResultView.as_view(), name="quiz-results"),
]
