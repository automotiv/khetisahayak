import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/models/quiz.dart';
import 'package:kheti_sahayak_app/providers/learning_provider.dart';
import 'package:kheti_sahayak_app/widgets/education/quiz_question_card.dart';
import 'package:kheti_sahayak_app/widgets/education/quiz_result_card.dart';

/// Interactive quiz screen for learning modules
class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final int moduleId;
  final String moduleTitle;

  const QuizScreen({
    Key? key,
    required this.quiz,
    required this.moduleId,
    required this.moduleTitle,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    // Initialize quiz in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().startQuiz(widget.quiz);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<LearningProvider>();
    if (provider.quizSubmitted) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text(
              'Your progress will be lost. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  provider.resetQuiz();
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleSubmit() async {
    final provider = context.read<LearningProvider>();

    // Check if all questions answered
    if (provider.answeredCount < widget.quiz.questions.length) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Quiz?'),
          content: Text(
            'You have answered ${provider.answeredCount} of ${widget.quiz.questions.length} questions. '
            'Unanswered questions will be marked incorrect.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    await provider.submitQuiz();
    setState(() => _showResults = true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _showResults ? null : _buildAppBar(),
        body: Consumer<LearningProvider>(
          builder: (context, provider, _) {
            if (_showResults && provider.lastQuizAttempt != null) {
              return QuizResultCard(
                attempt: provider.lastQuizAttempt!,
                quiz: widget.quiz,
                moduleTitle: widget.moduleTitle,
                onRetry: () {
                  provider.startQuiz(widget.quiz);
                  setState(() => _showResults = false);
                },
                onContinue: () {
                  Navigator.of(context).pop(provider.lastQuizAttempt);
                },
              );
            }

            if (provider.currentQuestion == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildQuizContent(provider),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green[700],
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.quiz.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Consumer<LearningProvider>(
            builder: (context, provider, _) => Text(
              'Question ${provider.currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.quiz.timeLimit > 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 18),
                    const SizedBox(width: 4),
                    Text('${widget.quiz.timeLimit} min'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuizContent(LearningProvider provider) {
    return Column(
      children: [
        // Progress indicator
        _buildProgressBar(provider),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: QuizQuestionCard(
              question: provider.currentQuestion!,
              questionNumber: provider.currentQuestionIndex + 1,
              selectedOptionIds:
                  provider.selectedAnswers[provider.currentQuestion!.id] ?? [],
              onOptionSelected: (optionId) {
                provider.selectAnswer(optionId);
              },
              showFeedback: false,
            ),
          ),
        ),

        // Navigation buttons
        _buildNavigationBar(provider),
      ],
    );
  }

  Widget _buildProgressBar(LearningProvider provider) {
    return Container(
      color: Colors.green[700],
      child: Column(
        children: [
          // Linear progress
          LinearProgressIndicator(
            value: provider.quizProgress,
            backgroundColor: Colors.green[900],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),

          // Question dots
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, index) {
                final isAnswered =
                    provider.selectedAnswers.containsKey(widget.quiz.questions[index].id);
                final isCurrent = index == provider.currentQuestionIndex;

                return GestureDetector(
                  onTap: () => provider.goToQuestion(index),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                              ? Colors.green[300]
                              : Colors.white24,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent || isAnswered
                              ? Colors.green[800]
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(LearningProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            if (provider.currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _animController.reset();
                    provider.previousQuestion();
                    _animController.forward();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 16),

            // Next/Submit button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (provider.isLastQuestion) {
                    _handleSubmit();
                  } else {
                    _animController.reset();
                    provider.nextQuestion();
                    _animController.forward();
                  }
                },
                icon: Icon(
                  provider.isLastQuestion ? Icons.check : Icons.arrow_forward,
                ),
                label: Text(provider.isLastQuestion ? 'Submit' : 'Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isLastQuestion
                      ? Colors.orange[700]
                      : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
