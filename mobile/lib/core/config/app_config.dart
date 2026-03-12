import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  // URL base optionnelle fournie au build, par exemple :
  // flutter run --dart-define=SWIPEIQ_API_BASE_URL=http://192.168.1.42:5678
  static const String _envApiBaseUrl = String.fromEnvironment(
    'SWIPEIQ_API_BASE_URL',
    defaultValue: '',
  );

  // URL optionnelle fournie au build, par exemple :
  // flutter run --dart-define=SWIPEIQ_QUESTIONS_URL=https://.../questions
  static const String _envQuestionsUrl = String.fromEnvironment(
    'SWIPEIQ_QUESTIONS_URL',
    defaultValue: '',
  );
  static const String _envLeaderboardUrl = String.fromEnvironment(
    'SWIPEIQ_LEADERBOARD_URL',
    defaultValue: '',
  );
  static const String _envProfileUrl = String.fromEnvironment(
    'SWIPEIQ_PROFILE_URL',
    defaultValue: '',
  );
  static const String _envQuizResultUrl = String.fromEnvironment(
    'SWIPEIQ_QUIZ_RESULT_URL',
    defaultValue: '',
  );
  static const String _envUserId = String.fromEnvironment(
    'SWIPEIQ_USER_ID',
    defaultValue: 'modou',
  );

  static String? get _apiBaseUrl {
    final raw = _envApiBaseUrl.trim();
    if (raw.isEmpty) {
      return null;
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String _endpointFromBase(String path) {
    final base = _apiBaseUrl;
    if (base == null) {
      throw StateError('SWIPEIQ_API_BASE_URL est vide');
    }
    return '$base$path';
  }

  static String get questionsUrl {
    final fromEnv = _envQuestionsUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (_apiBaseUrl != null) {
      return _endpointFromBase('/webhook/questions');
    }

    // Default local n8n production webhook endpoint for dev.
    if (kIsWeb) {
      return 'http://localhost:5678/webhook/questions';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5678/webhook/questions',
      _ => 'http://localhost:5678/webhook/questions',
    };
  }

  static bool get hasRemoteQuestions => questionsUrl.trim().isNotEmpty;

  static String get leaderboardUrl {
    final fromEnv = _envLeaderboardUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (_apiBaseUrl != null) {
      return _endpointFromBase('/webhook/leaderboard');
    }

    if (kIsWeb) {
      return 'http://localhost:5678/webhook/leaderboard';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5678/webhook/leaderboard',
      _ => 'http://localhost:5678/webhook/leaderboard',
    };
  }

  static String get profileUrl {
    final fromEnv = _envProfileUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (_apiBaseUrl != null) {
      return _endpointFromBase('/webhook/profile');
    }

    if (kIsWeb) {
      return 'http://localhost:5678/webhook/profile';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5678/webhook/profile',
      _ => 'http://localhost:5678/webhook/profile',
    };
  }

  static String get quizResultUrl {
    final fromEnv = _envQuizResultUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (_apiBaseUrl != null) {
      return _endpointFromBase('/webhook/quiz-result');
    }

    if (kIsWeb) {
      return 'http://localhost:5678/webhook/quiz-result';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5678/webhook/quiz-result',
      _ => 'http://localhost:5678/webhook/quiz-result',
    };
  }

  static String get userId => _envUserId.trim().isEmpty ? 'modou' : _envUserId;
}
