import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import 'question_source.dart';

class RemoteQuestionSource implements QuestionSource {
  RemoteQuestionSource({required this.endpoint, http.Client? client})
    : _client = client ?? http.Client();

  final String endpoint;
  final http.Client _client;

  @override
  Future<List<Question>> loadQuestions({String? theme}) async {
    final uri = Uri.parse(endpoint);
    final payload = _buildPayload(theme: theme);
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Requete distante echouee: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final jsonQuestions = _extractQuestionsArray(decoded);
    if (jsonQuestions == null) {
      throw Exception('Format JSON distant invalide');
    }

    return jsonQuestions.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      if (item is! Map<String, dynamic>) {
        throw Exception('Question distante invalide a l index $index');
      }

      final normalized = _normalizeQuestion(item, index);
      return Question.fromJson(normalized);
    }).toList();
  }

  Map<String, dynamic> _buildPayload({String? theme}) {
    return {
      'theme': (theme == null || theme.trim().isEmpty) ? 'general' : theme.trim(),
      'level': 'facile',
      'lang': 'fr',
    };
  }

  List<dynamic>? _extractQuestionsArray(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded['question'] is String) {
        return [decoded];
      }
      final direct = decoded['questions'];
      if (direct is List<dynamic>) {
        return direct;
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic> && data['question'] is String) {
        return [data];
      }
      if (data is Map<String, dynamic> && data['questions'] is List<dynamic>) {
        return data['questions'] as List<dynamic>;
      }
      if (data is List<dynamic>) {
        return data;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeQuestion(Map<String, dynamic> raw, int index) {
    final choicesRaw = raw['choices'] ?? raw['answers'];
    final answerRaw = raw['answer'] ?? raw['correctIndex'] ?? raw['answerId'];

    if (choicesRaw is! List || choicesRaw.length != 4) {
      throw Exception('Question distante invalide: choices/answers manquant');
    }

    final choices = choicesRaw.map((choice) {
      if (choice is Map<String, dynamic>) {
        final label = choice['text']?.toString().trim();
        if (label != null && label.isNotEmpty) {
          return label;
        }
      }
      return choice.toString();
    }).toList();
    final answer = _parseAnswerIndex(answerRaw);

    if (answer == null || answer < 0 || answer > 3) {
      throw Exception('Question distante invalide: answer/correctIndex');
    }

    final questionText = raw['question']?.toString() ?? '';
    if (questionText.trim().isEmpty) {
      throw Exception('Question distante invalide: question vide');
    }

    return {
      'id': raw['id']?.toString() ?? 'n8n-${index + 1}',
      'theme':
          raw['theme']?.toString() ?? raw['category']?.toString() ?? 'general',
      'level':
          raw['level']?.toString() ??
          raw['difficulty']?.toString() ??
          'facile',
      'question': questionText,
      'choices': choices,
      'answer': answer,
      'explanation':
          raw['explanation']?.toString() ?? 'Question importee depuis n8n.',
    };
  }

  int? _parseAnswerIndex(dynamic answerRaw) {
    if (answerRaw is int) {
      return answerRaw;
    }
    final asString = answerRaw?.toString().trim();
    if (asString == null || asString.isEmpty) {
      return null;
    }
    final direct = int.tryParse(asString);
    if (direct != null) {
      return direct;
    }
    switch (asString.toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return null;
    }
  }
}
