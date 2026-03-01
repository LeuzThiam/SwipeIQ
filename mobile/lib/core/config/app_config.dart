class AppConfig {
  const AppConfig._();

  // URL optionnelle fournie au build, par exemple :
  // flutter run --dart-define=SWIPEIQ_QUESTIONS_URL=https://.../questions
  static const String questionsUrl = String.fromEnvironment(
    'SWIPEIQ_QUESTIONS_URL',
    defaultValue: '',
  );

  static bool get hasRemoteQuestions => questionsUrl.trim().isNotEmpty;
}
