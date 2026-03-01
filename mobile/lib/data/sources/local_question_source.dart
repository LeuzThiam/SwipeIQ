import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/question.dart';
import 'question_source.dart';

class LocalQuestionSource implements QuestionSource {
  const LocalQuestionSource({this.assetPath = 'assets/questions_seed.json'});

  final String assetPath;

  @override
  Future<List<Question>> loadQuestions({
    String? theme,
    String? level,
    String? lang,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    var jsonQuestions = (jsonMap['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final trimmedTheme = theme?.trim();
    if (trimmedTheme != null && trimmedTheme.isNotEmpty) {
      jsonQuestions = jsonQuestions
          .where((item) =>
              (item['theme']?.toString().toLowerCase() ?? '') ==
              trimmedTheme.toLowerCase())
          .toList();
    }

    return jsonQuestions.map(Question.fromJson).toList();
  }
}
