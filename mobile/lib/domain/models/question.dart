class Question {
  const Question({
    required this.id,
    required this.theme,
    required this.level,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final String theme;
  final String level;
  final String question;
  final List<String> choices;
  final int answer;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      theme: json['theme'] as String,
      level: json['level'] as String,
      question: json['question'] as String,
      choices: List<String>.from(json['choices'] as List<dynamic>),
      answer: json['answer'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
