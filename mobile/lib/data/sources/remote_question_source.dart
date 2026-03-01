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
  Future<List<Question>> loadQuestions() async {
    final response = await _client.get(Uri.parse(endpoint));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Requete distante echouee: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final jsonQuestions = _extractQuestionsArray(decoded);
    if (jsonQuestions == null) {
      throw Exception('Format JSON distant invalide');
    }

    return jsonQuestions
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<dynamic>? _extractQuestionsArray(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final direct = decoded['questions'];
      if (direct is List<dynamic>) {
        return direct;
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic> && data['questions'] is List<dynamic>) {
        return data['questions'] as List<dynamic>;
      }
      if (data is List<dynamic>) {
        return data;
      }
    }
    return null;
  }
}
