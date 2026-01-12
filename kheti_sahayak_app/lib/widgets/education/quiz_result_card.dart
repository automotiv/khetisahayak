import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/quiz.dart';

/// Card showing quiz results after submission
class QuizResultCard extends StatelessWidget {
  final QuizAttempt attempt;
  final Quiz quiz;
  final String moduleTitle;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const QuizResultCard({
    Key? key,
    required this.attempt,
    required this.quiz,
    required this.moduleTitle,
    required this.onRetry,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = attempt.percentage;
    final passed = attempt.passed;

    return Container(
      color: passed ? Colors.green[50] : Colors.red[50],
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Result animation/icon
                _buildResultIcon(passed),

                const SizedBox(height: 24),

                // Result text
                Text(
                  passed ? 'Congratulations!' : 'Keep Learning!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green[800] : Colors.red[800],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  passed
                      ? 'You passed the quiz!'
                      : 'You need ${quiz.passingScore}% to pass',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Score card
                _buildScoreCard(percentage, passed),

                const SizedBox(height: 24),

                // Stats grid
                _buildStatsGrid(),

                const SizedBox(height: 24),

                // Question breakdown
                _buildQuestionBreakdown(),

                const SizedBox(height: 32),

                // Action buttons
                _buildActionButtons(context, passed),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon(bool passed) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: passed ? Colors.green[100] : Colors.red[100],
              boxShadow: [
                BoxShadow(
                  color: (passed ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              passed ? Icons.emoji_events : Icons.school,
              size: 64,
              color: passed ? Colors.amber[700] : Colors.red[400],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(double percentage, bool passed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: percentage / 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          passed ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: passed ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Points earned
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 24),
              const SizedBox(width: 8),
              Text(
                '${attempt.score} / ${attempt.totalPoints} points',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final correctCount = attempt.answers.where((a) => a.isCorrect).length;
    final incorrectCount = attempt.answers.length - correctCount;
    final timeTaken = _formatTime(attempt.timeTaken);

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.check_circle,
          value: '$correctCount',
          label: 'Correct',
          color: Colors.green,
        ),
        _buildStatItem(
          icon: Icons.cancel,
          value: '$incorrectCount',
          label: 'Incorrect',
          color: Colors.red,
        ),
        _buildStatItem(
          icon: Icons.timer,
          value: timeTaken,
          label: 'Time',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(quiz.questions.length, (index) {
              final answer = attempt.answers.firstWhere(
                (a) => a.questionId == quiz.questions[index].id,
                orElse: () => QuestionAnswer(
                  questionId: quiz.questions[index].id,
                  selectedOptionIds: [],
                  isCorrect: false,
                  pointsEarned: 0,
                ),
              );

              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: answer.isCorrect ? Colors.green[100] : Colors.red[100],
                  border: Border.all(
                    color: answer.isCorrect ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: answer.isCorrect
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Correct', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Incorrect', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color[100],
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool passed) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onContinue,
            icon: Icon(passed ? Icons.arrow_forward : Icons.school),
            label: Text(passed ? 'Continue Learning' : 'Review Lessons'),
            style: ElevatedButton.styleFrom(
              backgroundColor: passed ? Colors.green[700] : Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Retry button (if not passed or always available)
        if (!passed || quiz.maxAttempts == 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Share button (if passed)
        if (passed)
          TextButton.icon(
            onPressed: () {
              // TODO: Share result
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share your achievement!')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Achievement'),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}
