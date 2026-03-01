import 'package:flutter/material.dart';

import '../../data/sources/local_question_source.dart';
import '../../data/sources/question_source.dart';
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

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? const LocalQuestionSource();
    _pageController = PageController();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _source.loadQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _selectedChoices = List<int?>.filled(questions.length, null);
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

  bool _isQuestionLocked(int index) => _selectedChoices[index] != null;

  void _selectChoice(int questionIndex, int choiceIndex) {
    if (_isQuestionLocked(questionIndex)) return;
    setState(() {
      _selectedChoices[questionIndex] = choiceIndex;
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
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Partie terminee'),
            content: Text('Score: $_score/${_questions.length}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SwipeIQ - Feed'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Score: $_score')),
          ),
        ],
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
