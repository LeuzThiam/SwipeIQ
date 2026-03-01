import 'package:flutter/material.dart';

class QuizErrorView extends StatelessWidget {
  const QuizErrorView({
    required this.message,
    required this.onRetry,
    required this.onBackToThemes,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBackToThemes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reessayer'),
                ),
                OutlinedButton(
                  onPressed: onBackToThemes,
                  child: const Text('Changer de theme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
