import 'package:flutter/material.dart';

/// Progress indicator widget for learning modules
class LearningProgressIndicator extends StatelessWidget {
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final double height;
  final bool showPercentage;
  final bool showLessonCount;

  const LearningProgressIndicator({
    Key? key,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    this.height = 8,
    this.showPercentage = true,
    this.showLessonCount = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    final isComplete = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green[200]! : Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.trending_up,
                    size: 20,
                    color: isComplete ? Colors.green[700] : Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete ? 'Completed!' : 'In Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green[700] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isComplete ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.green[200]
                      : Colors.blue[200],
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                height: height,
                width: (MediaQuery.of(context).size.width - 64) *
                    progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isComplete
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isComplete ? Colors.green : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showLessonCount) ...[
            const SizedBox(height: 8),
            Text(
              '$completedLessons of $totalLessons lessons completed',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular progress indicator for dashboard/cards
class CircularLearningProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? progressColor;
  final Color? backgroundColor;

  const CircularLearningProgress({
    Key? key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.child,
    this.progressColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    final isComplete = progress >= 1.0;
    final color = progressColor ??
        (isComplete ? Colors.green : Colors.blue);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: backgroundColor ?? Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
          child ??
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: size / 4,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
        ],
      ),
    );
  }
}

/// Streak indicator widget
class StreakIndicator extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final bool isActiveToday;

  const StreakIndicator({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    required this.isActiveToday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActiveToday
              ? [Colors.orange[400]!, Colors.deepOrange[500]!]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActiveToday ? Colors.orange : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fire icon with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: isActiveToday ? value : 0.9,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak Day Streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActiveToday
                      ? 'Keep it up!'
                      : 'Learn today to continue!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Best streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Best',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '$longestStreak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// XP/Level progress bar
class LevelProgressBar extends StatelessWidget {
  final int currentLevel;
  final int currentXP;
  final int xpForNextLevel;

  const LevelProgressBar({
    Key? key,
    required this.currentLevel,
    required this.currentXP,
    required this.xpForNextLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / xpForNextLevel;
    final xpNeeded = xpForNextLevel - currentXP;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$currentLevel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    Text(
                      '$xpNeeded XP to Level ${currentLevel + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currentXP XP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.purple[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                  minHeight: 8,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
