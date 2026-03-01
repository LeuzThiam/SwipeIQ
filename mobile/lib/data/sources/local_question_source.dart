import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/question.dart';
import 'question_source.dart';

class LocalQuestionSource implements QuestionSource {
  const LocalQuestionSource({this.assetPath = 'assets/questions_seed.json'});

  final String assetPath;

  @override
  Future<List<Question>> loadQuestions() async {
    final raw = await rootBundle.loadString(assetPath);
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    final jsonQuestions = jsonMap['questions'] as List<dynamic>;
    return jsonQuestions
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
