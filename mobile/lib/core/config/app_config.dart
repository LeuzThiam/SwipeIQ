import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  // URL optionnelle fournie au build, par exemple :
  // flutter run --dart-define=SWIPEIQ_QUESTIONS_URL=https://.../questions
  static const String _envQuestionsUrl = String.fromEnvironment(
    'SWIPEIQ_QUESTIONS_URL',
    defaultValue: '',
  );

  static String get questionsUrl {
    final fromEnv = _envQuestionsUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
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
}
