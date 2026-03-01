import 'package:flutter/material.dart';

import '../../../domain/models/question.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.selectedChoice,
    required this.onChoiceSelected,
    required this.isLocked,
    required this.feedbackText,
    required this.onNextPressed,
    required this.isLastQuestion,
    super.key,
  });

  final Question question;
  final int questionIndex;
  final int totalQuestions;
  final int? selectedChoice;
  final ValueChanged<int> onChoiceSelected;
  final bool isLocked;
  final String feedbackText;
  final VoidCallback onNextPressed;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${questionIndex + 1}/$totalQuestions',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(question.question, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: question.choices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isSelected = selectedChoice == index;
                      return FilledButton.tonal(
                        onPressed: isLocked
                            ? null
                            : () => onChoiceSelected(index),
                        style: FilledButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        child: Text(question.choices[index]),
                      );
                    },
                  ),
                ),
                if (feedbackText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(feedbackText, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 10),
                if (isLocked)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: onNextPressed,
                      child: Text(
                        isLastQuestion
                            ? 'Voir le resultat'
                            : 'Question suivante',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
