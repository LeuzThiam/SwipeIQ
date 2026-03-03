import 'package:flutter/material.dart';

class QuizLoadingView extends StatelessWidget {
  const QuizLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1B4A), Color(0xFF07132E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.psychology_alt_outlined,
              size: 72,
              color: Colors.cyanAccent.shade200,
            ),
            const SizedBox(height: 14),
            const Text(
              'GENERATION EN COURS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x2215D6FF),
                border: Border.all(color: Colors.cyanAccent, width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                'Le moteur IA prepare tes questions en fonction du theme selectionne.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xCC102A60),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.cyanAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connexion n8n + LLM active',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
