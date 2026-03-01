import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/data/sources/question_source.dart';
import 'package:mobile/domain/models/question.dart';
import 'package:mobile/ui/feed/feed_page.dart';

void main() {
  testWidgets('Le feed affiche une question et met a jour le score', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FeedPage(source: _FakeQuestionSource())),
    );
    await tester.pumpAndSettle();

    expect(find.text('SwipeIQ - Feed'), findsOneWidget);
    expect(find.text('Que signifie API ?'), findsOneWidget);
    expect(find.text('Score 0'), findsOneWidget);
    expect(find.text('Streak 0'), findsOneWidget);

    await tester.tap(find.text('Application Programming Interface'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bonne reponse'), findsOneWidget);
    expect(find.text('Score 1'), findsOneWidget);
    expect(find.text('Streak 1'), findsOneWidget);
  });
}

class _FakeQuestionSource implements QuestionSource {
  @override
  Future<List<Question>> loadQuestions() async {
    return const [
      Question(
        id: 'q-test-1',
        theme: 'informatique',
        level: 'facile',
        question: 'Que signifie API ?',
        choices: [
          'Application Programming Interface',
          'Advanced Program Input',
          'Automated Protocol Integration',
          'App Process Instance',
        ],
        answer: 0,
        explanation: 'API signifie Application Programming Interface.',
      ),
    ];
  }
}
