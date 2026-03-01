import '../../domain/models/question.dart';

abstract class QuestionSource {
  Future<List<Question>> loadQuestions();
}
