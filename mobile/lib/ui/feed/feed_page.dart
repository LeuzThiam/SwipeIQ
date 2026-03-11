import 'dart:async';
import 'dart:math' as math;

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

enum FeedEntryMode { themeSelection, adventureMap }

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    this.source,
    this.entryMode = FeedEntryMode.themeSelection,
    this.title = 'Quiz rapide',
  });

  final QuestionSource? source;
  final FeedEntryMode entryMode;
  final String title;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _secondsPerQuestion = 45;
  static const int _adventureTotalLevels = 100;
  static const List<_ThemeOption> _availableThemes = [
    _ThemeOption(label: 'Culture generale', value: 'culture_g'),
    _ThemeOption(label: 'Sciences', value: 'sciences'),
    _ThemeOption(label: 'Histoire', value: 'business'),
    _ThemeOption(label: 'Geographie', value: 'langues'),
    _ThemeOption(label: 'Sport', value: 'sport'),
    _ThemeOption(label: 'Cinema & series', value: 'arts_pop'),
    _ThemeOption(label: 'Technologie', value: 'tech'),
    _ThemeOption(label: 'Musique', value: 'vie_pratique'),
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
  bool _isAdventureMapStep = false;
  bool _isResultStep = false;
  bool _isAdventureMode = false;
  String? _error;
  _ThemeOption _selectedTheme = _availableThemes.first;
  _ChoiceOption? _selectedLevel;
  final _ChoiceOption _selectedLang = _availableLangs[0];
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
  late final List<_AdventureLevelState> _adventureLevels;
  int _adventureTotalStars = 0;
  int _adventureTotalScore = 0;
  int _adventureTotalCoins = 0;
  int _adventureCompletedLevels = 0;
  int _lastAdventureStars = 0;
  bool _lastAdventurePassed = false;
  int _lastAdventureRewardPoints = 0;
  int _lastAdventureRewardCoins = 0;
  String? _lastAdventureUnlockedMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _adventureLevels = _buildAdventureLevels();
    if (widget.entryMode == FeedEntryMode.adventureMap) {
      _isAdventureMapStep = true;
      _isAdventureMode = true;
    }
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
      _isAdventureMapStep = false;
      _isResultStep = false;
      _error = null;
      _questions = const [];
      _selectedChoices = const [];
      _currentPageIndex = 0;
      _remainingSeconds = _secondsPerQuestion;
      _currentStreak = 0;
      _bestStreak = 0;
      _lastAdventureStars = 0;
      _lastAdventurePassed = false;
      _lastAdventureRewardPoints = 0;
      _lastAdventureRewardCoins = 0;
      _lastAdventureUnlockedMessage = null;
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

  void _backToHomeHub() {
    _stopQuestionTimer();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isAdventureMapStep = false;
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
    final score = _score;
    final passed = score >= level.minCorrectToPass;
    var stars = 0;
    if (passed) {
      stars = 1;
      if (score >= level.minCorrectToPass + 1) stars = 2;
      if (score == level.questionCount) stars = 3;
    }

    final wasCompleted = level.completed;
    final previousStars = level.stars;
    if (stars > level.stars) {
      level.stars = stars;
    }
    if (score > level.bestScore) {
      level.bestScore = score;
    }
    if (passed) {
      level.completed = true;
    }

    _lastAdventurePassed = passed;
    _lastAdventureStars = stars;
    _lastAdventureRewardPoints = 0;
    _lastAdventureRewardCoins = 0;
    _lastAdventureUnlockedMessage = null;

    if (passed) {
      final points = level.rewardPoints;
      final coins = level.rewardCoins;
      _adventureTotalScore += points;
      _adventureTotalCoins += coins;
      _lastAdventureRewardPoints = points;
      _lastAdventureRewardCoins = coins;
    }

    if (!wasCompleted && level.completed) {
      _adventureCompletedLevels++;
    }
    if (level.stars != previousStars) {
      _adventureTotalStars += (level.stars - previousStars);
    }

    if (passed && idx + 1 < _adventureLevels.length) {
      final nextLevel = _adventureLevels[idx + 1];
      final wasUnlocked = nextLevel.unlocked;
      nextLevel.unlocked = true;
      _nextAdventureLevelIndex = idx + 1;
      if (!wasUnlocked) {
        _lastAdventureUnlockedMessage = 'Niveau ${nextLevel.id} debloque !';
      }
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

  @override
  Widget build(BuildContext context) {
    if (_isThemeSelectionStep) {
      return Scaffold(
        body: _isAdventureMapStep
            ? _buildAdventureMap()
            : _buildSoloThemeSelection(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isResultStep ? 'Resultat' : widget.title),
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
      return _isAdventureMapStep
          ? _buildAdventureMap()
          : _buildSoloThemeSelection();
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
      final currentLevel = _currentAdventureLevel;
      return QuizResultView(
        themeLabel: _isAdventureMode && currentLevel != null
            ? currentLevel.title
            : _selectedTheme.label,
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
        adventurePassed: _isAdventureMode ? _lastAdventurePassed : null,
        adventureStars: _isAdventureMode ? _lastAdventureStars : null,
        adventureObjective: _isAdventureMode && currentLevel != null
            ? 'Objectif: ${currentLevel.minCorrectToPass}/${currentLevel.questionCount}'
            : null,
        rewardPoints: _isAdventureMode ? _lastAdventureRewardPoints : null,
        rewardCoins: _isAdventureMode ? _lastAdventureRewardCoins : null,
        unlockedMessage: _isAdventureMode
            ? _lastAdventureUnlockedMessage
            : null,
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

  Widget _buildSoloThemeSelection() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 46) / 2;
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
              'Choisir un theme',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._availableThemes.map((option) {
                      final visual = _themeVisual(option.value);
                      return SizedBox(
                        width: cardWidth,
                        child: _ThemeWideCard(
                          key: Key('theme_card_${option.value}'),
                          title: option.label,
                          color: visual.color,
                          icon: visual.icon,
                          onTap: () {
                            setState(() {
                              _selectedTheme = option;
                            });
                            _startQuiz();
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 2, width: double.infinity),
                    _RandomThemeCard(
                      onTap: () {
                        final random = math.Random();
                        final option =
                            _availableThemes[random.nextInt(
                              _availableThemes.length,
                            )];
                        setState(() {
                          _selectedTheme = option;
                        });
                        _startQuiz();
                      },
                    ),
                  ],
                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _AdventureProgressPanel(
                completedLevels: _adventureCompletedLevels,
                totalLevels: _adventureLevels.length,
                totalStars: _adventureTotalStars,
                totalScore: _adventureTotalScore,
                totalCoins: _adventureTotalCoins,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _adventureLevels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final level = _adventureLevels[index];
                  final theme = _themeByValue(level.themeValue);
                  final unlocked = level.unlocked;
                  final statusLabel = level.completed
                      ? 'Termine'
                      : unlocked
                      ? 'Disponible'
                      : 'Verrouille';
                  final statusColor = level.completed
                      ? const Color(0xFF6CCF4F)
                      : unlocked
                      ? const Color(0xFF1EA5FF)
                      : const Color(0xFF7A879A);
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
                                  const SizedBox(height: 2),
                                  Text(
                                    'Objectif: ${level.minCorrectToPass} bonnes reponses',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _AdventureTag(
                                        icon: Icons.workspace_premium_rounded,
                                        label:
                                            '+${level.rewardPoints} pts / +${level.rewardCoins} coins',
                                      ),
                                      _AdventureTag(
                                        icon: Icons.flag_rounded,
                                        label: statusLabel,
                                        color: statusColor,
                                      ),
                                    ],
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

  _ThemeVisual _themeVisual(String value) {
    return switch (value) {
      'culture_g' => const _ThemeVisual(
        color: Color(0xFFF7A900),
        icon: Icons.lightbulb_rounded,
      ),
      'sciences' => const _ThemeVisual(
        color: Color(0xFF49B95B),
        icon: Icons.science_rounded,
      ),
      'business' => const _ThemeVisual(
        color: Color(0xFFC57A39),
        icon: Icons.menu_book_rounded,
      ),
      'langues' => const _ThemeVisual(
        color: Color(0xFF2CAFD2),
        icon: Icons.public_rounded,
      ),
      'sport' => const _ThemeVisual(
        color: Color(0xFF56B04C),
        icon: Icons.sports_soccer_rounded,
      ),
      'arts_pop' => const _ThemeVisual(
        color: Color(0xFFE4513A),
        icon: Icons.movie_creation_rounded,
      ),
      'tech' => const _ThemeVisual(
        color: Color(0xFF2290D9),
        icon: Icons.smart_toy_rounded,
      ),
      _ => const _ThemeVisual(
        color: Color(0xFF8751E5),
        icon: Icons.music_note_rounded,
      ),
    };
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

  List<_AdventureLevelState> _buildAdventureLevels() {
    final levels = <_AdventureLevelState>[];
    for (var i = 1; i <= _adventureTotalLevels; i++) {
      final difficulty = _difficultyForLevel(i);
      final questionCount = _questionCountForLevel(i);
      final minCorrect = _minCorrectToPass(questionCount, difficulty);
      levels.add(
        _AdventureLevelState(
          id: i,
          title: 'Niveau $i',
          themeValue: _availableThemes[(i - 1) % _availableThemes.length].value,
          difficultyValue: difficulty,
          questionCount: questionCount,
          minCorrectToPass: minCorrect,
          rewardPoints: _rewardPointsForLevel(i, difficulty),
          rewardCoins: _rewardCoinsForLevel(i, difficulty),
          unlocked: i == 1,
        ),
      );
    }
    return levels;
  }

  String _difficultyForLevel(int levelId) {
    if (levelId <= 10) return 'facile';
    if (levelId <= 30) return 'moyen';
    return 'difficile';
  }

  int _questionCountForLevel(int levelId) {
    if (levelId <= 10) return 5 + ((levelId - 1) ~/ 5);
    if (levelId <= 30) return 7 + ((levelId - 11) ~/ 10);
    return 9 + ((levelId - 31) ~/ 20);
  }

  int _minCorrectToPass(int questionCount, String difficulty) {
    final ratio = switch (difficulty) {
      'facile' => 0.65,
      'moyen' => 0.7,
      _ => 0.75,
    };
    var minCorrect = (questionCount * ratio).ceil();
    if (minCorrect < 1) minCorrect = 1;
    if (minCorrect > questionCount) minCorrect = questionCount;
    return minCorrect;
  }

  int _rewardPointsForLevel(int levelId, String difficulty) {
    final base = switch (difficulty) {
      'facile' => 80,
      'moyen' => 140,
      _ => 220,
    };
    return base + (levelId * 5);
  }

  int _rewardCoinsForLevel(int levelId, String difficulty) {
    final base = switch (difficulty) {
      'facile' => 10,
      'moyen' => 18,
      _ => 25,
    };
    return base + (levelId ~/ 5);
  }

  bool _isSessionLastQuestionIndex(int index) {
    return index >= _targetQuestionCount - 1;
  }

  _AdventureLevelState? get _currentAdventureLevel {
    final idx = _currentAdventureLevelIndex;
    if (idx == null || idx < 0 || idx >= _adventureLevels.length) {
      return null;
    }
    return _adventureLevels[idx];
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
    required this.minCorrectToPass,
    required this.rewardPoints,
    required this.rewardCoins,
    required this.unlocked,
  });

  final int id;
  final String title;
  final String themeValue;
  final String difficultyValue;
  final int questionCount;
  final int minCorrectToPass;
  final int rewardPoints;
  final int rewardCoins;
  bool unlocked;
  bool completed = false;
  int stars = 0;
  int bestScore = 0;
}

class _AdventureProgressPanel extends StatelessWidget {
  const _AdventureProgressPanel({
    required this.completedLevels,
    required this.totalLevels,
    required this.totalStars,
    required this.totalScore,
    required this.totalCoins,
  });

  final int completedLevels;
  final int totalLevels;
  final int totalStars;
  final int totalScore;
  final int totalCoins;

  @override
  Widget build(BuildContext context) {
    final progress = totalLevels == 0 ? 0.0 : completedLevels / totalLevels;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xB8142F66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Progression aventure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$completedLevels/$totalLevels',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              color: const Color(0xFF34C94A),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _AdventureTag(
                icon: Icons.star_rounded,
                label: '$totalStars etoiles',
                color: const Color(0xFFFFC107),
              ),
              _AdventureTag(
                icon: Icons.trending_up_rounded,
                label: '$totalScore points',
                color: const Color(0xFF1EA5FF),
              ),
              _AdventureTag(
                icon: Icons.monetization_on_rounded,
                label: '$totalCoins coins',
                color: const Color(0xFF79D75E),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdventureTag extends StatelessWidget {
  const _AdventureTag({
    required this.icon,
    required this.label,
    this.color = Colors.white70,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeWideCard extends StatelessWidget {
  const _ThemeWideCard({
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
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 34, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.2,
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

class _RandomThemeCard extends StatelessWidget {
  const _RandomThemeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D5DB8), Color(0xFF1E3E8C)],
            ),
            border: Border.all(color: Colors.white38, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5DB8).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                'Aleatoire',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
