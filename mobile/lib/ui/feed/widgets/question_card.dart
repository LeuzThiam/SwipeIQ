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
    required this.onSkipPressed,
    required this.isLastQuestion,
    required this.score,
    required this.progressValue,
    required this.remainingSeconds,
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
  final VoidCallback onSkipPressed;
  final bool isLastQuestion;
  final int score;
  final double progressValue;
  final int remainingSeconds;

  bool _isCorrectOption(int index) => index == question.answer;
  bool _isWrongSelectedOption(int index) =>
      selectedChoice == index && selectedChoice != question.answer;

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
    final width = MediaQuery.of(context).size.width;
    final questionSize = width < 420 ? 24.0 : 44.0;
    final themeSize = width < 420 ? 20.0 : 28.0;
    final answerTextSize = width < 420 ? 17.0 : 22.0;
    final scoreSize = width < 420 ? 18.0 : 25.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1B4A), Color(0xFF07132E)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Icon(
                      Icons.psychology_alt_outlined,
                      color: Colors.cyanAccent.shade200,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.theme.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: themeSize,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                minHeight: 18,
                                value: progressValue,
                                backgroundColor: Colors.white24,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.cyanAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _formatTime(remainingSeconds),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: questionSize,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: question.choices.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.05,
                            ),
                        itemBuilder: (context, index) {
                          return _AnswerCard(
                            label: question.choices[index],
                            color: _baseColorForIndex(index),
                            isLocked: isLocked,
                            isCorrect: _isCorrectOption(index),
                            isWrongSelected: _isWrongSelectedOption(index),
                            trailingIcon: _choiceIcon(index),
                            trailingColor: _choiceIconColor(index),
                            answerTextSize: answerTextSize,
                            onTap: () => onChoiceSelected(index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: feedbackText.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(feedbackText),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                feedbackText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0x3300E5FF),
                            child: Icon(Icons.pause, color: Colors.cyanAccent),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'SCORE: $score',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: scoreSize,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onSkipPressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE5484D),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('SKIP'),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: onNextPressed,
                              child: Text(isLastQuestion ? 'FIN' : 'SUIVANT'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BottomStub(
                            icon: Icons.settings_outlined,
                            label: 'SETTINGS',
                          ),
                          _BottomStub(
                            icon: Icons.person_outline_rounded,
                            label: 'PROFILE',
                          ),
                          _BottomStub(
                            icon: Icons.shopping_cart_outlined,
                            label: 'STORE',
                          ),
                          _BottomStub(
                            icon: Icons.auto_awesome_outlined,
                            label: 'BONUS',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _baseColorForIndex(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF1EA5FF);
      case 1:
        return const Color(0xFF34C94A);
      case 2:
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFFF44336);
    }
  }

  String _formatTime(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    final sec = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$sec';
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.color,
    required this.isLocked,
    required this.isCorrect,
    required this.isWrongSelected,
    required this.onTap,
    required this.answerTextSize,
    this.trailingIcon,
    required this.trailingColor,
  });

  final String label;
  final Color color;
  final bool isLocked;
  final bool isCorrect;
  final bool isWrongSelected;
  final VoidCallback onTap;
  final double answerTextSize;
  final IconData? trailingIcon;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    final glow = isLocked && (isCorrect || isWrongSelected);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.96),
                color.withValues(alpha: 0.82),
              ],
            ),
            border: Border.all(
              color: glow
                  ? Colors.greenAccent
                  : Colors.white.withValues(alpha: 0.55),
              width: glow ? 3 : 2,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: answerTextSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: trailingColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomStub extends StatelessWidget {
  const _BottomStub({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
