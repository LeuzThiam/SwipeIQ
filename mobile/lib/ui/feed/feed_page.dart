import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../data/sources/question_source.dart';
import '../../data/sources/remote_question_source.dart';
import '../../domain/models/question.dart';
import 'widgets/question_card.dart';
import 'widgets/quiz_error_view.dart';
import 'widgets/quiz_loading_view.dart';
import 'widgets/quiz_result_view.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.source});

  final QuestionSource? source;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _secondsPerQuestion = 45;
  static const List<_ThemeOption> _availableThemes = [
    _ThemeOption(label: 'Culture G', value: 'culture_g'),
    _ThemeOption(label: 'Sciences', value: 'sciences'),
    _ThemeOption(label: 'Tech', value: 'tech'),
    _ThemeOption(label: 'Business', value: 'business'),
    _ThemeOption(label: 'Arts & Pop', value: 'arts_pop'),
    _ThemeOption(label: 'Sport', value: 'sport'),
    _ThemeOption(label: 'Vie pratique', value: 'vie_pratique'),
    _ThemeOption(label: 'Langues', value: 'langues'),
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
  QuestionSource? _activeSource;
  Timer? _questionTimer;

  List<Question> _questions = const [];
  List<int?> _selectedChoices = const [];
  bool _isLoading = false;
  bool _isThemeSelectionStep = true;
  bool _isSoloThemeStep = false;
  bool _isAdventureMapStep = false;
  bool _isResultStep = false;
  bool _isAdventureMode = false;
  String? _error;
  _ThemeOption _selectedTheme = _availableThemes.first;
  _ChoiceOption? _selectedLevel;
  _ChoiceOption _selectedLang = _availableLangs[0];
  int? _questionLimit;
  String? _activeThemeValue;
  String? _activeLevelValue;
  String? _activeLangValue;
  int _currentPageIndex = 0;
  int _remainingSeconds = _secondsPerQuestion;
  bool _isAdvancingQuestion = false;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int? _currentAdventureLevelIndex;
  int? _nextAdventureLevelIndex;
  final List<_AdventureLevelState> _adventureLevels = [
    _AdventureLevelState(
      id: 1,
      title: 'Niveau 1',
      themeValue: 'culture_g',
      difficultyValue: 'facile',
      questionCount: 3,
      unlocked: true,
    ),
    _AdventureLevelState(
      id: 2,
      title: 'Niveau 2',
      themeValue: 'sciences',
      difficultyValue: 'facile',
      questionCount: 3,
      unlocked: false,
    ),
    _AdventureLevelState(
      id: 3,
      title: 'Niveau 3',
      themeValue: 'tech',
      difficultyValue: 'moyen',
      questionCount: 4,
      unlocked: false,
    ),
    _AdventureLevelState(
      id: 4,
      title: 'Niveau 4',
      themeValue: 'business',
      difficultyValue: 'moyen',
      questionCount: 4,
      unlocked: false,
    ),
    _AdventureLevelState(
      id: 5,
      title: 'Niveau 5',
      themeValue: 'sport',
      difficultyValue: 'difficile',
      questionCount: 5,
      unlocked: false,
    ),
  ];

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
    final source = widget.source ?? _resolveSource();
    _activeSource = source;
    _activeThemeValue = _selectedTheme.value;
    _activeLevelValue = _selectedLevel?.value;
    _activeLangValue = _selectedLang.value;

    setState(() {
      _isLoading = true;
      _isThemeSelectionStep = false;
      _isSoloThemeStep = false;
      _isAdventureMapStep = false;
      _isResultStep = false;
      _error = null;
      _questions = const [];
      _selectedChoices = const [];
      _currentPageIndex = 0;
      _remainingSeconds = _secondsPerQuestion;
      _currentStreak = 0;
      _bestStreak = 0;
    });

    try {
      final questions = await source.loadQuestions(
        theme: _activeThemeValue,
        level: _activeLevelValue,
        lang: _activeLangValue,
      );
      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _error =
              'Aucune question retournee pour le theme "${_selectedTheme.label}".';
          _isLoading = false;
          _isThemeSelectionStep = true;
        });
        return;
      }

      final target = _targetQuestionCount;
      final limitedQuestions = questions.length > target
          ? questions.take(target).toList()
          : questions;

      if (limitedQuestions.isEmpty) {
        setState(() {
          _error =
              'Aucune question disponible pour ce niveau. Verifie la reponse n8n.';
          _isLoading = false;
          _isThemeSelectionStep = true;
        });
        return;
      }

      setState(() {
        _questions = limitedQuestions;
        _selectedChoices = List<int?>.filled(limitedQuestions.length, null);
        _isLoading = false;
        _remainingSeconds = _secondsPerQuestion;
      });
      _startQuestionTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger les questions depuis le backend n8n pour le theme "${_selectedTheme.label}".';
        _isLoading = false;
        _isThemeSelectionStep = true;
      });
      debugPrint('Erreur chargement questions: $error');
    }
  }

  @override
  void dispose() {
    _stopQuestionTimer();
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
    _stopQuestionTimer();

    _triggerHapticFeedback(isCorrect);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _isResultStep || _isLoading) {
        return;
      }
      if (_currentPageIndex != questionIndex) {
        return;
      }
      if (!_isQuestionLocked(questionIndex)) {
        return;
      }
      _goToNextQuestion(questionIndex);
    });
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
    if (_isAdvancingQuestion) {
      return;
    }
    _isAdvancingQuestion = true;
    _stopQuestionTimer();
    try {
      if (currentIndex == _questions.length - 1) {
        final target = _targetQuestionCount;
        if (_questions.length < target) {
          final appended = await _appendOneQuestionFromBackend();
          if (appended) {
            await _pageController.nextPage(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
            _resetQuestionTimer();
            _startQuestionTimer();
            return;
          }
        }
        _applyAdventureProgressIfNeeded();
        setState(() {
          _isResultStep = true;
        });
        return;
      }

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      _resetQuestionTimer();
      _startQuestionTimer();
    } finally {
      _isAdvancingQuestion = false;
    }
  }

  void _restartGame() {
    _stopQuestionTimer();
    setState(() {
      _isThemeSelectionStep = true;
      _isSoloThemeStep = false;
      _isAdventureMapStep = false;
      _isResultStep = false;
      _isAdventureMode = false;
      _questions = const [];
      _selectedChoices = const [];
      _questionLimit = null;
      _activeThemeValue = null;
      _activeLevelValue = null;
      _activeLangValue = null;
      _activeSource = null;
      _currentAdventureLevelIndex = null;
      _nextAdventureLevelIndex = null;
      _currentPageIndex = 0;
      _remainingSeconds = _secondsPerQuestion;
      _currentStreak = 0;
      _bestStreak = 0;
      _error = null;
    });
    _pageController.jumpToPage(0);
  }

  void _retryCurrentConfig() {
    _startQuiz();
  }

  void _openSoloThemeSelection() {
    _stopQuestionTimer();
    setState(() {
      _isSoloThemeStep = true;
      _isAdventureMapStep = false;
      _isAdventureMode = false;
      _questionLimit = null;
      _activeThemeValue = null;
      _activeLevelValue = null;
      _activeLangValue = null;
      _activeSource = null;
      _currentAdventureLevelIndex = null;
      _nextAdventureLevelIndex = null;
      _error = null;
    });
  }

  void _backToHomeHub() {
    _stopQuestionTimer();
    setState(() {
      _isSoloThemeStep = false;
      _isAdventureMapStep = false;
    });
  }

  void _openAdventureMap() {
    _stopQuestionTimer();
    setState(() {
      _isAdventureMapStep = true;
      _isSoloThemeStep = false;
      _isAdventureMode = true;
      _questionLimit = null;
      _activeThemeValue = null;
      _activeLevelValue = null;
      _activeLangValue = null;
      _activeSource = null;
      _currentAdventureLevelIndex = null;
      _nextAdventureLevelIndex = null;
      _error = null;
    });
  }

  void _startAdventureLevel(int levelIndex) {
    final level = _adventureLevels[levelIndex];
    if (!level.unlocked) return;

    setState(() {
      _isAdventureMode = true;
      _currentAdventureLevelIndex = levelIndex;
      _nextAdventureLevelIndex = null;
      _questionLimit = level.questionCount;
      _selectedTheme = _themeByValue(level.themeValue);
      _selectedLevel = _levelByValue(level.difficultyValue);
    });
    _startQuiz();
  }

  void _goToAdventureMapFromResult() {
    _stopQuestionTimer();
    setState(() {
      _isThemeSelectionStep = true;
      _isAdventureMapStep = true;
      _isSoloThemeStep = false;
      _isResultStep = false;
      _isLoading = false;
      _questions = const [];
      _selectedChoices = const [];
      _currentPageIndex = 0;
      _remainingSeconds = _secondsPerQuestion;
      _error = null;
    });
  }

  void _nextAdventureRoundOrReplay() {
    if (_nextAdventureLevelIndex != null) {
      _startAdventureLevel(_nextAdventureLevelIndex!);
      return;
    }
    _retryCurrentConfig();
  }

  void _applyAdventureProgressIfNeeded() {
    if (!_isAdventureMode || _currentAdventureLevelIndex == null) return;
    final idx = _currentAdventureLevelIndex!;
    final level = _adventureLevels[idx];
    final successRate = _questions.isEmpty
        ? 0
        : (_score * 100 / _questions.length);
    final stars = successRate >= 90
        ? 3
        : successRate >= 75
        ? 2
        : successRate >= 60
        ? 1
        : 0;

    if (stars > level.stars) {
      level.stars = stars;
    }
    if (_score > level.bestScore) {
      level.bestScore = _score;
    }
    if (stars > 0 && idx + 1 < _adventureLevels.length) {
      _adventureLevels[idx + 1].unlocked = true;
      _nextAdventureLevelIndex = idx + 1;
    } else {
      _nextAdventureLevelIndex = null;
    }
  }

  void _resetQuestionTimer() {
    if (!mounted) return;
    setState(() {
      _remainingSeconds = _secondsPerQuestion;
    });
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  void _startQuestionTimer() {
    _stopQuestionTimer();
    if (!mounted || _isThemeSelectionStep || _isResultStep || _isLoading) {
      return;
    }
    if (_questions.isEmpty) {
      return;
    }
    if (_isQuestionLocked(_currentPageIndex)) {
      return;
    }

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isThemeSelectionStep || _isResultStep || _isLoading) {
        _stopQuestionTimer();
        return;
      }
      if (_isQuestionLocked(_currentPageIndex)) {
        _stopQuestionTimer();
        return;
      }
      if (_remainingSeconds <= 1) {
        _stopQuestionTimer();
        _remainingSeconds = 0;
        _goToNextQuestion(_currentPageIndex);
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label arrive bientot')));
  }

  Future<void> _openAdvancedOptions() async {
    var tempLevel = _selectedLevel;
    var tempLang = _selectedLang;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Options avancees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Niveau'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Auto'),
                          selected: tempLevel == null,
                          onSelected: (_) => setModalState(() {
                            tempLevel = null;
                          }),
                        ),
                        ..._availableLevels.map(
                          (level) => ChoiceChip(
                            label: Text(level.label),
                            selected: tempLevel == level,
                            onSelected: (_) => setModalState(() {
                              tempLevel = level;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<_ChoiceOption>(
                      initialValue: tempLang,
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
                        setModalState(() {
                          tempLang = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedLevel = tempLevel;
                            _selectedLang = tempLang;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isThemeSelectionStep) {
      return Scaffold(
        body: _isSoloThemeStep
            ? _buildSoloThemeSelection()
            : (_isAdventureMapStep
                  ? _buildAdventureMap()
                  : _buildThemeSelector()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isResultStep ? 'Resultat' : 'SwipeIQ - Feed'),
        actions: _isResultStep
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
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1,
                          ).animate(animation),
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
        bottom: _isResultStep
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
      return _isSoloThemeStep
          ? _buildSoloThemeSelection()
          : (_isAdventureMapStep
                ? _buildAdventureMap()
                : _buildThemeSelector());
    }

    if (_isLoading) {
      return const QuizLoadingView();
    }

    if (_error != null) {
      return QuizErrorView(
        message: _error!,
        onRetry: _retryCurrentConfig,
        onBackToThemes: _restartGame,
      );
    }

    if (_isResultStep) {
      return QuizResultView(
        themeLabel: _selectedTheme.label,
        score: _score,
        total: _questions.length,
        bestStreak: _bestStreak,
        answeredCount: _answeredCount,
        onNextRound: _isAdventureMode
            ? _nextAdventureRoundOrReplay
            : _retryCurrentConfig,
        onChangeTheme: _isAdventureMode
            ? _goToAdventureMapFromResult
            : _restartGame,
        onBack: _isAdventureMode ? _goToAdventureMapFromResult : _restartGame,
        nextRoundLabel: _isAdventureMode && _nextAdventureLevelIndex == null
            ? 'REPLAY LEVEL'
            : 'NEXT ROUND',
        secondaryLabel: _isAdventureMode ? 'ADVENTURE MAP' : 'THEME SELECTION',
      );
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
        _resetQuestionTimer();
        _startQuestionTimer();
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
          onSkipPressed: () => _goToNextQuestion(index),
          isLastQuestion: _isSessionLastQuestionIndex(index),
          score: _score,
          progressValue: _progressValue,
          remainingSeconds: _remainingSeconds,
        );
      },
    );
  }

  Widget _buildThemeSelector() {
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
            const Spacer(flex: 1),
            Icon(
              Icons.psychology_alt_outlined,
              size: 76,
              color: Colors.cyanAccent.shade200,
            ),
            const SizedBox(height: 10),
            const Text(
              'NEURON QUEST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Defie ton cerveau, une question a la fois.',
              style: TextStyle(color: Colors.white70),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeActionButton(
                      key: const Key('play_solo_button'),
                      label: 'PLAY SOLO',
                      icon: Icons.help_outline_rounded,
                      color: const Color(0xFF1AA9FF),
                      onTap: _openSoloThemeSelection,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeActionButton(
                      label: 'ADVENTURE',
                      icon: Icons.map_rounded,
                      color: const Color(0xFF8B39FF),
                      onTap: _openAdventureMap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeActionButton(
                      label: 'LEADERBOARD',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFF39CC5B),
                      onTap: () => _showComingSoon('Leaderboard'),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              color: Colors.black.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomIconItem(
                    icon: Icons.settings_outlined,
                    label: 'SETTINGS',
                    onTap: _openAdvancedOptions,
                  ),
                  _BottomIconItem(
                    icon: Icons.person_outline_rounded,
                    label: 'PROFILE',
                    onTap: () => _showComingSoon('Profile'),
                  ),
                  _BottomIconItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'STORE',
                    onTap: () => _showComingSoon('Store'),
                  ),
                  _BottomIconItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'BONUS',
                    onTap: () => _showComingSoon('Bonus'),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloThemeSelection() {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _backToHomeHub,
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
            const Text(
              'THEME SELECTION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableThemes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.93,
                ),
                itemBuilder: (context, index) {
                  final option = _availableThemes[index];
                  final visual = _themeVisual(index);
                  return _ThemeSquareCard(
                    key: Key('theme_card_${option.value}'),
                    title: option.label.toUpperCase(),
                    color: visual.color,
                    icon: visual.icon,
                    onTap: () {
                      setState(() {
                        _selectedTheme = option;
                      });
                      _startQuiz();
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              color: Colors.black.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomIconItem(
                    icon: Icons.settings_outlined,
                    label: 'SETTINGS',
                    onTap: _openAdvancedOptions,
                  ),
                  _BottomIconItem(
                    icon: Icons.person_outline_rounded,
                    label: 'PROFILE',
                    onTap: () => _showComingSoon('Profile'),
                  ),
                  _BottomIconItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'STORE',
                    onTap: () => _showComingSoon('Store'),
                  ),
                  _BottomIconItem(
                    icon: Icons.auto_awesome_outlined,
                    label: 'BONUS',
                    onTap: () => _showComingSoon('Bonus'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdventureMap() {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _backToHomeHub,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.route_rounded, color: Colors.cyanAccent.shade200),
                  const SizedBox(width: 8),
                  const Text(
                    'ADVENTURE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _adventureLevels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final level = _adventureLevels[index];
                  final theme = _themeByValue(level.themeValue);
                  final unlocked = level.unlocked;
                  return Material(
                    color: unlocked
                        ? const Color(0xCC16356E)
                        : const Color(0xCC3B4A62),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: unlocked
                          ? () => _startAdventureLevel(index)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: unlocked
                                  ? Colors.cyanAccent.withValues(alpha: 0.2)
                                  : Colors.white12,
                              child: Text(
                                '${level.id}',
                                style: TextStyle(
                                  color: unlocked
                                      ? Colors.cyanAccent
                                      : Colors.white54,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level.title,
                                    style: TextStyle(
                                      color: unlocked
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${theme.label} • ${level.difficultyValue.toUpperCase()} • ${level.questionCount} questions',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(3, (starIdx) {
                                      final filled = starIdx < level.stars;
                                      return Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 20,
                                        color: filled
                                            ? Colors.amberAccent
                                            : Colors.white30,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!unlocked)
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white54,
                              )
                            else
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.cyanAccent,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ThemeVisual _themeVisual(int index) {
    const visuals = [
      _ThemeVisual(
        color: Color(0xFF1EA5FF),
        icon: Icons.account_balance_rounded,
      ),
      _ThemeVisual(color: Color(0xFF34C94A), icon: Icons.sports_soccer_rounded),
      _ThemeVisual(color: Color(0xFF9344FF), icon: Icons.science_outlined),
      _ThemeVisual(color: Color(0xFFFFA726), icon: Icons.music_note_rounded),
      _ThemeVisual(color: Color(0xFFFF7043), icon: Icons.settings_rounded),
      _ThemeVisual(
        color: Color(0xFFF44336),
        icon: Icons.movie_creation_outlined,
      ),
      _ThemeVisual(color: Color(0xFF7C8798), icon: Icons.lock_outline_rounded),
      _ThemeVisual(color: Color(0xFFF2C22D), icon: Icons.public_rounded),
    ];
    return visuals[index % visuals.length];
  }

  _ThemeOption _themeByValue(String value) {
    return _availableThemes.firstWhere(
      (theme) => theme.value == value,
      orElse: () => _availableThemes.first,
    );
  }

  _ChoiceOption? _levelByValue(String value) {
    for (final level in _availableLevels) {
      if (level.value == value) return level;
    }
    return null;
  }

  bool _isSessionLastQuestionIndex(int index) {
    return index >= _targetQuestionCount - 1;
  }

  int get _targetQuestionCount => _questionLimit ?? 10;

  Future<bool> _appendOneQuestionFromBackend() async {
    final source = _activeSource;
    final theme = _activeThemeValue;
    final lang = _activeLangValue;
    if (source == null || theme == null || lang == null) {
      return false;
    }

    try {
      final fresh = await source.loadQuestions(
        theme: theme,
        level: _activeLevelValue,
        lang: lang,
      );
      if (fresh.isEmpty) {
        return false;
      }

      final next = _ensureUniqueQuestion(fresh.first);
      if (!mounted) {
        return false;
      }
      setState(() {
        _questions = [..._questions, next];
        _selectedChoices = [..._selectedChoices, null];
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Question _ensureUniqueQuestion(Question question) {
    final ids = _questions.map((q) => q.id).toSet();
    if (!ids.contains(question.id)) {
      return question;
    }
    var suffix = 2;
    var candidate = '${question.id}-$suffix';
    while (ids.contains(candidate)) {
      suffix++;
      candidate = '${question.id}-$suffix';
    }
    return Question(
      id: candidate,
      theme: question.theme,
      level: question.level,
      question: question.question,
      choices: question.choices,
      answer: question.answer,
      explanation: question.explanation,
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

class _ThemeVisual {
  const _ThemeVisual({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

class _AdventureLevelState {
  _AdventureLevelState({
    required this.id,
    required this.title,
    required this.themeValue,
    required this.difficultyValue,
    required this.questionCount,
    required this.unlocked,
  });

  final int id;
  final String title;
  final String themeValue;
  final String difficultyValue;
  final int questionCount;
  bool unlocked;
  int stars = 0;
  int bestScore = 0;
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.78),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 34),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomIconItem extends StatelessWidget {
  const _BottomIconItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }
}

class _ThemeSquareCard extends StatelessWidget {
  const _ThemeSquareCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 42, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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
