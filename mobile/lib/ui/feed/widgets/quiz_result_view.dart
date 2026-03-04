import 'package:flutter/material.dart';

class QuizResultView extends StatelessWidget {
  const QuizResultView({
    required this.themeLabel,
    required this.score,
    required this.total,
    required this.bestStreak,
    required this.answeredCount,
    required this.onNextRound,
    required this.onChangeTheme,
    required this.onBack,
    this.nextRoundLabel = 'NEXT ROUND',
    this.secondaryLabel = 'THEME SELECTION',
    super.key,
  });

  final String themeLabel;
  final int score;
  final int total;
  final int bestStreak;
  final int answeredCount;
  final VoidCallback onNextRound;
  final VoidCallback onChangeTheme;
  final VoidCallback onBack;
  final String nextRoundLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final successRate = total == 0 ? 0 : (score * 100 / total).round();
    final incorrect = answeredCount - score;
    final displayedScore = score * 250;

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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.psychology_alt_outlined,
                            color: Colors.cyanAccent.shade200,
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                    Text(
                      themeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ROUND COMPLETE!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF102E6A),
                        border: Border.all(color: Colors.cyanAccent, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.star_border_rounded,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC102A60),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'FINAL SCORE: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$displayedScore',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xB8142F66),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatRow('Questions repondues', '$answeredCount'),
                          const SizedBox(height: 8),
                          _StatRow('Bonnes reponses', '$score'),
                          const SizedBox(height: 8),
                          _StatRow('Mauvaises reponses', '$incorrect'),
                          const SizedBox(height: 8),
                          _StatRow('Precision', '$successRate%'),
                          const SizedBox(height: 8),
                          _StatRow('Meilleure streak', '$bestStreak'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onNextRound,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF34C94A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                nextRoundLabel,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: onChangeTheme,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1EA5FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                secondaryLabel,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BottomStub(icon: Icons.settings_outlined, label: 'SETTINGS'),
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
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
