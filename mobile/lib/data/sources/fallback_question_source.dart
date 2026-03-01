import '../../domain/models/question.dart';
import 'question_source.dart';

class FallbackQuestionSource implements QuestionSource {
  const FallbackQuestionSource({required this.primary, required this.fallback});

  final QuestionSource primary;
  final QuestionSource fallback;

  @override
  Future<List<Question>> loadQuestions({String? theme}) async {
    try {
      final primaryQuestions = await primary.loadQuestions(theme: theme);
      if (primaryQuestions.isNotEmpty) {
        return primaryQuestions;
      }
    } catch (_) {
      // Fallback silencieux: l'app continue avec la source locale.
    }
    return fallback.loadQuestions(theme: theme);
  }
}
