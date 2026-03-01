import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../data/sources/fallback_question_source.dart';
import '../../data/sources/local_question_source.dart';
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
  late final QuestionSource _source;
  late final PageController _pageController;

  List<Question> _questions = const [];
  List<int?> _selectedChoices = const [];
  bool _isLoading = true;
  String? _error;
  int _currentPageIndex = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? _resolveSource();
    _pageController = PageController();
    _loadQuestions();
  }

  QuestionSource _resolveSource() {
    const local = LocalQuestionSource();
    if (!AppConfig.hasRemoteQuestions) {
      return local;
    }
    return FallbackQuestionSource(
      primary: RemoteQuestionSource(endpoint: AppConfig.questionsUrl),
      fallback: local,
    );
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _source.loadQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _selectedChoices = List<int?>.filled(questions.length, null);
        _currentPageIndex = 0;
        _currentStreak = 0;
        _bestStreak = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les questions.';
        _isLoading = false;
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
  }

  String _feedbackForQuestion(int index) {
    final selected = _selectedChoices[index];
    if (selected == null) return '';
    final question = _questions[index];
    if (selected == question.answer) {
      return 'Bonne reponse. ${question.explanation}';
    }
    return 'Mauvaise reponse. ${question.explanation}';
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
      _selectedChoices = List<int?>.filled(_questions.length, null);
      _currentPageIndex = 0;
      _currentStreak = 0;
      _bestStreak = 0;
    });
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SwipeIQ - Feed'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(child: Text('Score $_score')),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('Streak $_currentStreak')),
          ),
        ],
        bottom: PreferredSize(
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
}
