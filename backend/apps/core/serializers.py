from rest_framework import serializers


class QuestionSerializer(serializers.Serializer):
    id = serializers.CharField()
    theme = serializers.CharField()
    level = serializers.CharField()
    question = serializers.CharField()
    choices = serializers.ListField(child=serializers.CharField())
    answer = serializers.IntegerField()
    explanation = serializers.CharField()


class StatsSerializer(serializers.Serializer):
    totalQuestions = serializers.IntegerField()
    themes = serializers.ListField(child=serializers.CharField())
    levels = serializers.ListField(child=serializers.CharField())


class LeaderboardEntrySerializer(serializers.Serializer):
    rank = serializers.IntegerField()
    name = serializers.CharField()
    score = serializers.IntegerField()
    streak = serializers.IntegerField()
    badge = serializers.CharField()
    isCurrentUser = serializers.BooleanField()


class LeaderboardSerializer(serializers.Serializer):
    period = serializers.CharField()
    generatedFromQuestions = serializers.IntegerField()
    currentUser = LeaderboardEntrySerializer()
    entries = LeaderboardEntrySerializer(many=True)


class DailyGoalSerializer(serializers.Serializer):
    label = serializers.CharField()
    status = serializers.CharField()


class ProfileSerializer(serializers.Serializer):
    name = serializers.CharField()
    username = serializers.CharField(allow_blank=True)
    isGuest = serializers.BooleanField()
    level = serializers.IntegerField()
    xp = serializers.IntegerField()
    bestStreak = serializers.IntegerField()
    quizzesPlayed = serializers.IntegerField()
    discoveredThemes = serializers.IntegerField()
    availableThemes = serializers.ListField(child=serializers.CharField())
    badges = serializers.ListField(child=serializers.DictField())
    dailyGoals = DailyGoalSerializer(many=True)


class SessionSerializer(serializers.Serializer):
    token = serializers.CharField()
    profile = ProfileSerializer()


class GuestAuthSerializer(serializers.Serializer):
    displayName = serializers.CharField(min_length=2, max_length=120)


class RegisterAuthSerializer(serializers.Serializer):
    username = serializers.CharField(min_length=3, max_length=150)
    password = serializers.CharField(min_length=4, max_length=128)
    displayName = serializers.CharField(min_length=2, max_length=120, required=False, allow_blank=True)


class LoginAuthSerializer(serializers.Serializer):
    username = serializers.CharField(min_length=3, max_length=150)
    password = serializers.CharField(min_length=4, max_length=128)


class QuizResultCreateSerializer(serializers.Serializer):
    mode = serializers.ChoiceField(choices=["theme", "quick", "adventure", "daily"])
    theme = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    level = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    lang = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    totalQuestions = serializers.IntegerField(min_value=1)
    correctAnswers = serializers.IntegerField(min_value=0)
    bestStreak = serializers.IntegerField(min_value=0)
    scorePoints = serializers.IntegerField(min_value=0)

    def validate(self, attrs):
        total_questions = attrs["totalQuestions"]
        correct_answers = attrs["correctAnswers"]
        if correct_answers > total_questions:
            raise serializers.ValidationError("correctAnswers ne peut pas depasser totalQuestions.")
        if attrs["bestStreak"] > total_questions:
            raise serializers.ValidationError("bestStreak ne peut pas depasser totalQuestions.")
        return attrs
