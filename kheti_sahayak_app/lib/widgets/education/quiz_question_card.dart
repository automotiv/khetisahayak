import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kheti_sahayak_app/models/quiz.dart';

/// Card widget displaying a quiz question with options
class QuizQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int questionNumber;
  final List<int> selectedOptionIds;
  final Function(int) onOptionSelected;
  final bool showFeedback;
  final bool? wasCorrect;

  const QuizQuestionCard({
    Key? key,
    required this.question,
    required this.questionNumber,
    required this.selectedOptionIds,
    required this.onOptionSelected,
    this.showFeedback = false,
    this.wasCorrect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header
        _buildQuestionHeader(context),

        const SizedBox(height: 16),

        // Question image if available
        if (question.imageUrl != null) ...[
          _buildQuestionImage(),
          const SizedBox(height: 20),
        ],

        // Options
        _buildOptions(context),

        // Feedback section (shown after submission)
        if (showFeedback && question.explanation != null) ...[
          const SizedBox(height: 20),
          _buildFeedback(context),
        ],
      ],
    );
  }

  Widget _buildQuestionHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${question.points} pts',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Question text
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          // Instruction for multiple choice
          if (question.type == QuestionType.multipleChoice) ...[
            const SizedBox(height: 8),
            Text(
              'Select all that apply',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    String label;
    IconData icon;
    Color color;

    switch (question.type) {
      case QuestionType.singleChoice:
        label = 'Single Choice';
        icon = Icons.radio_button_checked;
        color = Colors.blue;
        break;
      case QuestionType.multipleChoice:
        label = 'Multiple Choice';
        icon = Icons.check_box;
        color = Colors.purple;
        break;
      case QuestionType.trueFalse:
        label = 'True/False';
        icon = Icons.swap_horiz;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: question.imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 180,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 180,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    return Column(
      children: question.options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);
        final bool? isCorrectOption = showFeedback ? option.isCorrect : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OptionCard(
            option: option,
            isSelected: isSelected,
            questionType: question.type,
            isCorrect: isCorrectOption,
            showFeedback: showFeedback,
            onTap: showFeedback ? null : () => onOptionSelected(option.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedback(BuildContext context) {
    final isCorrect = wasCorrect ?? question.isCorrect(selectedOptionIds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (question.explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              question.explanation!,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual option card widget
class _OptionCard extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final QuestionType questionType;
  final bool? isCorrect;
  final bool showFeedback;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.questionType,
    this.isCorrect,
    required this.showFeedback,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    Color textColor;

    if (showFeedback) {
      if (option.isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
      } else if (isSelected && !option.isCorrect) {
        borderColor = Colors.red;
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
      } else {
        borderColor = Colors.grey[300]!;
        backgroundColor = Colors.white;
        textColor = Colors.grey[600]!;
      }
    } else {
      if (isSelected) {
        borderColor = Colors.green[700]!;
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
      } else {
        borderColor = Colors.grey[300]!;
        backgroundColor = Colors.white;
        textColor = Colors.black87;
      }
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              // Selection indicator
              _buildSelectionIndicator(borderColor),
              const SizedBox(width: 12),

              // Option content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (option.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: option.imageUrl!,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Feedback icon
              if (showFeedback && (option.isCorrect || (isSelected && !option.isCorrect)))
                Icon(
                  option.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: option.isCorrect ? Colors.green : Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(Color color) {
    if (questionType == QuestionType.multipleChoice) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 2),
          color: isSelected ? color : Colors.transparent,
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            )
          : null,
    );
  }
}
