import 'package:flutter/material.dart';

import '../feed/feed_page.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2A74), Color(0xFF05164A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PlayerHeader(),
                const SizedBox(height: 16),
                const _ProgressPanel(),
                const SizedBox(height: 20),
                _PrimaryActionCard(
                  label: 'Aventure',
                  icon: Icons.explore_rounded,
                  onTap: () => _openFeed(
                    context,
                    FeedEntryMode.adventureMap,
                    'Aventure',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        label: 'Choisir\ntheme',
                        icon: Icons.view_list_rounded,
                        colorA: const Color(0xFF3BA4FF),
                        colorB: const Color(0xFF2267D8),
                        onTap: () => _openFeed(
                          context,
                          FeedEntryMode.themeSelection,
                          'Choisir un theme',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        label: 'Quiz rapide',
                        icon: Icons.bolt_rounded,
                        colorA: const Color(0xFF9156FF),
                        colorB: const Color(0xFF6A37DA),
                        onTap: () => _openFeed(
                          context,
                          FeedEntryMode.themeSelection,
                          'Quiz rapide',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        label: 'Defi du jour',
                        icon: Icons.gpp_good_rounded,
                        colorA: const Color(0xFF79D75E),
                        colorB: const Color(0xFF3FAA4A),
                        onTap: () => _openInfoPage(
                          context,
                          'Defi du jour',
                          'Quiz quotidien en cours de construction.',
                          Icons.today_rounded,
                          const Color(0xFF46BA53),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        label: 'Classement',
                        icon: Icons.emoji_events_rounded,
                        colorA: const Color(0xFF335FD2),
                        colorB: const Color(0xFF183D99),
                        onTap: () => _openInfoPage(
                          context,
                          'Classement',
                          'Le leaderboard global arrive bientot.',
                          Icons.emoji_events_rounded,
                          const Color(0xFF2548AE),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  label: 'Profil',
                  icon: Icons.person_rounded,
                  colorA: const Color(0xFF2D72D8),
                  colorB: const Color(0xFF2354AB),
                  onTap: () => _openInfoPage(
                    context,
                    'Profil',
                    'La personnalisation du profil arrive bientot.',
                    Icons.person_rounded,
                    const Color(0xFF2C63C3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFeed(BuildContext context, FeedEntryMode mode, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedPage(entryMode: mode, title: title),
      ),
    );
  }

  void _openInfoPage(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color accent,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InfoPage(
          title: title,
          subtitle: subtitle,
          icon: icon,
          accent: accent,
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF58B7FF), Color(0xFF216CE2)],
            ),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 48),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nv. 7',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF2B5BBC),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD54F),
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '8120',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF123B8A).withValues(alpha: 0.78),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFD54F),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Progression',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: LinearProgressIndicator(
                    value: 0.82,
                    minHeight: 12,
                    backgroundColor: Color(0xFF1B2F63),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC107),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '8120',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.white12, height: 1),
          SizedBox(height: 12),
          Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Continue ton aventure !\nNiveau suivant: 8',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFC54A), Color(0xFFE2851D)],
            ),
            border: Border.all(color: const Color(0xFFFFE082), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FFC107),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 54),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 126,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorA, colorB],
            ),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorA.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withValues(alpha: 0.22), const Color(0xFFF9FBFF)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 80, color: accent),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
