import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../data/sources/question_source.dart';
import '../../data/sources/remote_question_source.dart';
import '../../domain/models/question.dart';
import 'widgets/question_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.source});

  final QuestionSource? source;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const List<_ThemeOption> _availableThemes = [
    _ThemeOption(label: '🌍 Culture G', value: 'culture_g'),
    _ThemeOption(label: '🧪 Sciences', value: 'sciences'),
    _ThemeOption(label: '💻 Tech', value: 'tech'),
    _ThemeOption(label: '📊 Business', value: 'business'),
    _ThemeOption(label: '🎨 Arts & Pop', value: 'arts_pop'),
    _ThemeOption(label: '⚽ Sport', value: 'sport'),
    _ThemeOption(label: '🌱 Vie pratique', value: 'vie_pratique'),
    _ThemeOption(label: '🌎 Langues', value: 'langues'),
  ];
  static const List<_ChoiceOption> _availableLevels = [
    _ChoiceOption(label: 'Facile', value: 'facile'),
    _ChoiceOption(label: 'Moyen', value: 'moyen'),
    _ChoiceOption(label: 'Difficile', value: 'difficile'),
  ];
  static const List<_ChoiceOption> _availableLangs = [
    _ChoiceOption(label: 'Francais', value: 'fr'),
    _ChoiceOption(label: 'Anglais', value: 'en'),
  ];

  late final PageController _pageController;

  List<Question> _questions = const [];
  List<int?> _selectedChoices = const [];
  bool _isLoading = false;
  bool _isThemeSelectionStep = true;
  String? _error;
  _ThemeOption? _selectedTheme;
  _ChoiceOption _selectedLevel = _availableLevels[0];
  _ChoiceOption _selectedLang = _availableLangs[0];
  int _currentPageIndex = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  QuestionSource _resolveSource() {
    if (!AppConfig.hasRemoteQuestions) {
      throw StateError(
        'SWIPEIQ_QUESTIONS_URL est requis en mode backend strict.',
      );
    }
    return RemoteQuestionSource(endpoint: AppConfig.questionsUrl);
  }

  Future<void> _startQuiz() async {
    final selectedTheme = _selectedTheme;
    if (selectedTheme == null || selectedTheme.value.trim().isEmpty) {
      setState(() {
        _error = 'Choisis un theme avant de commencer.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isThemeSelectionStep = false;
      _error = null;
      _questions = const [];
      _selectedChoices = const [];
      _currentPageIndex = 0;
      _currentStreak = 0;
      _bestStreak = 0;
    });

    try {
      final source = widget.source ?? _resolveSource();
      final questions = await source.loadQuestions(
        theme: selectedTheme.value,
        level: _selectedLevel.value,
        lang: _selectedLang.value,
      );
      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _error =
              'Aucune question retournee pour le theme "${selectedTheme.label}".';
          _isLoading = false;
          _isThemeSelectionStep = true;
        });
        return;
      }

      setState(() {
        _questions = questions;
        _selectedChoices = List<int?>.filled(questions.length, null);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger les questions depuis le backend n8n pour le theme "${selectedTheme.label}".';
        _isLoading = false;
        _isThemeSelectionStep = true;
      });
      debugPrint('Erreur chargement questions: $error');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _score {
    var total = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selectedChoices[i] == _questions[i].answer) {
        total++;
      }
    }
    return total;
  }

  int get _answeredCount =>
      _selectedChoices.where((choice) => choice != null).length;

  double get _progressValue {
    if (_questions.isEmpty) {
      return 0;
    }
    return (_currentPageIndex + 1) / _questions.length;
  }

  bool _isQuestionLocked(int index) => _selectedChoices[index] != null;

  void _selectChoice(int questionIndex, int choiceIndex) {
    if (_isQuestionLocked(questionIndex)) return;

    final isCorrect = _questions[questionIndex].answer == choiceIndex;
    final nextStreak = isCorrect ? _currentStreak + 1 : 0;
    final nextBestStreak = nextStreak > _bestStreak ? nextStreak : _bestStreak;

    setState(() {
      _selectedChoices[questionIndex] = choiceIndex;
      _currentStreak = nextStreak;
      _bestStreak = nextBestStreak;
    });

    _triggerHapticFeedback(isCorrect);
  }

  String _feedbackForQuestion(int index) {
    final selected = _selectedChoices[index];
    if (selected == null) return '';
    final question = _questions[index];
    if (selected == question.answer) {
      return 'Bonne reponse. ${question.explanation}';
    }
    final goodChoice = question.choices[question.answer];
    return 'Mauvaise reponse. Bonne reponse: $goodChoice. ${question.explanation}';
  }

  Future<void> _triggerHapticFeedback(bool isCorrect) async {
    try {
      if (isCorrect) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Ignore haptic errors on unsupported platforms.
    }
  }

  Future<void> _goToNextQuestion(int currentIndex) async {
    if (currentIndex == _questions.length - 1) {
      await _showResultDialog();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showResultDialog() async {
    final successRate = _questions.isEmpty
        ? 0
        : (_score * 100 / _questions.length).round();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resultat de la partie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $_score/${_questions.length}'),
              Text('Taux de reussite: $successRate%'),
              Text('Meilleure streak: $_bestStreak'),
              Text('Questions repondues: $_answeredCount/${_questions.length}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text('Rejouer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      _isThemeSelectionStep = true;
      _questions = const [];
      _selectedChoices = const [];
      _currentPageIndex = 0;
      _currentStreak = 0;
      _bestStreak = 0;
      _error = null;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isThemeSelectionStep ? 'Choisir un theme' : 'SwipeIQ - Feed'),
        actions: _isThemeSelectionStep
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(child: Text('Score $_score')),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                          child: child,
                        );
                      },
                      child: Text(
                        'Streak $_currentStreak',
                        key: ValueKey<int>(_currentStreak),
                      ),
                    ),
                  ),
                ),
              ],
        bottom: _isThemeSelectionStep
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 6,
                  borderRadius: const BorderRadius.all(Radius.circular(100)),
                ),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isThemeSelectionStep) {
      return _buildThemeSelector();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('Aucune question disponible.'));
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return QuestionCard(
          question: _questions[index],
          questionIndex: index,
          totalQuestions: _questions.length,
          selectedChoice: _selectedChoices[index],
          onChoiceSelected: (choice) => _selectChoice(index, choice),
          isLocked: _isQuestionLocked(index),
          feedbackText: _feedbackForQuestion(index),
          onNextPressed: () => _goToNextQuestion(index),
          isLastQuestion: index == _questions.length - 1,
        );
      },
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisis un theme puis appuie sur Generer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableThemes.map((theme) {
              return ChoiceChip(
                label: Text(theme.label),
                selected: _selectedTheme == theme,
                onSelected: (_) {
                  setState(() {
                    _selectedTheme = theme;
                    _error = null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<_ChoiceOption>(
            initialValue: _selectedLevel,
            decoration: const InputDecoration(
              labelText: 'Niveau',
              border: OutlineInputBorder(),
            ),
            items: _availableLevels
                .map(
                  (level) => DropdownMenuItem<_ChoiceOption>(
                    value: level,
                    child: Text(level.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLevel = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_ChoiceOption>(
            initialValue: _selectedLang,
            decoration: const InputDecoration(
              labelText: 'Langue',
              border: OutlineInputBorder(),
            ),
            items: _availableLangs
                .map(
                  (lang) => DropdownMenuItem<_ChoiceOption>(
                    value: lang,
                    child: Text(lang.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLang = value;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isLoading ? null : _startQuiz,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Generer les questions'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _ChoiceOption {
  const _ChoiceOption({required this.label, required this.value});

  final String label;
  final String value;
}
