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

  bool _isCorrectOption(int index) => index == question.answer;
  bool _isWrongSelectedOption(int index) =>
      selectedChoice == index && selectedChoice != question.answer;

  Color _choiceBackgroundColor(ThemeData theme, int index) {
    if (!isLocked) {
      return selectedChoice == index
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest;
    }
    if (_isCorrectOption(index)) {
      return Colors.green.shade100;
    }
    if (_isWrongSelectedOption(index)) {
      return Colors.red.shade100;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _choiceBorderColor(ThemeData theme, int index) {
    if (!isLocked) {
      return selectedChoice == index
          ? theme.colorScheme.primary
          : Colors.transparent;
    }
    if (_isCorrectOption(index)) {
      return Colors.green.shade700;
    }
    if (_isWrongSelectedOption(index)) {
      return Colors.red.shade700;
    }
    return Colors.transparent;
  }

  IconData? _choiceIcon(int index) {
    if (!isLocked) return null;
    if (_isCorrectOption(index)) return Icons.check_circle;
    if (_isWrongSelectedOption(index)) return Icons.cancel;
    return null;
  }

  Color _choiceIconColor(int index) {
    if (_isCorrectOption(index)) return Colors.green.shade700;
    if (_isWrongSelectedOption(index)) return Colors.red.shade700;
    return Colors.transparent;
  }

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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: _choiceBackgroundColor(theme, index),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _choiceBorderColor(theme, index),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onChoiceSelected(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(question.choices[index]),
                                  ),
                                  if (_choiceIcon(index) case final icon?)
                                    Icon(icon, color: _choiceIconColor(index)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: feedbackText.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          feedbackText,
                          key: ValueKey(feedbackText),
                          style: theme.textTheme.bodyMedium,
                        ),
                ),
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
