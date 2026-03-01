import '../../domain/models/question.dart';

abstract class QuestionSource {
  Future<List<Question>> loadQuestions({
    String? theme,
    String? level,
    String? lang,
  });
}
