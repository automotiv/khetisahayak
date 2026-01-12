import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kheti_sahayak_app/models/learning_module.dart';
import 'package:kheti_sahayak_app/providers/learning_provider.dart';
import 'package:kheti_sahayak_app/screens/education/quiz_screen.dart';
import 'package:kheti_sahayak_app/screens/education/lesson_content_screen.dart';
import 'package:kheti_sahayak_app/widgets/education/progress_indicator_widget.dart';

/// Detailed view of a learning module with lessons list
class ModuleDetailScreen extends StatefulWidget {
  final int moduleId;

  const ModuleDetailScreen({Key? key, required this.moduleId}) : super(key: key);

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  Future<void> _loadModule() async {
    await context.read<LearningProvider>().loadModuleDetails(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LearningProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          final module = provider.currentModule;
          if (module == null) {
            return const Center(child: Text('Module not found'));
          }

          return _buildContent(module, provider);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadModule,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LearningModule module, LearningProvider provider) {
    return CustomScrollView(
      slivers: [
        // Hero header with image
        _buildSliverAppBar(module),

        // Module info and progress
        SliverToBoxAdapter(
          child: _buildModuleInfo(module),
        ),

        // Lessons list
        SliverToBoxAdapter(
          child: _buildLessonsSection(module, provider),
        ),

        // Quiz section
        if (module.quiz != null)
          SliverToBoxAdapter(
            child: _buildQuizSection(module),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(LearningModule module) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.green[700],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          module.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (module.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: module.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.green[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.green[200],
                  child: const Icon(Icons.school, size: 64, color: Colors.white),
                ),
              )
            else
              Container(
                color: Colors.green[200],
                child: const Icon(Icons.school, size: 64, color: Colors.white),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Download button
        IconButton(
          icon: Icon(
            module.isDownloaded ? Icons.download_done : Icons.download,
          ),
          onPressed: () => _handleDownload(module),
          tooltip: module.isDownloaded ? 'Downloaded' : 'Download for offline',
        ),
        // Share button
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _handleShare(module),
        ),
      ],
    );
  }

  Widget _buildModuleInfo(LearningModule module) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                icon: Icons.signal_cellular_alt,
                label: module.difficulty.capitalize(),
                color: _getDifficultyColor(module.difficulty),
              ),
              _buildChip(
                icon: Icons.timer,
                label: '${module.estimatedDuration} min',
                color: Colors.blue,
              ),
              _buildChip(
                icon: Icons.star,
                label: '${module.pointsReward} pts',
                color: Colors.amber[700]!,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            module.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Progress card
          LearningProgressIndicator(
            progress: module.progress,
            completedLessons: module.completedLessons,
            totalLessons: module.totalLessons,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsSection(LearningModule module, LearningProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Lessons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${module.completedLessons}/${module.totalLessons}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lessons list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: module.lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = module.lessons[index];
              final isLocked =
                  index > 0 && !module.lessons[index - 1].isCompleted;

              return _buildLessonTile(lesson, isLocked, provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(
    LearningLesson lesson,
    bool isLocked,
    LearningProvider provider,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: isLocked
            ? null
            : () => _navigateToLesson(lesson),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lesson.isCompleted
                      ? Colors.green[100]
                      : isLocked
                          ? Colors.grey[200]
                          : Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lesson.isCompleted
                      ? Icons.check_circle
                      : isLocked
                          ? Icons.lock
                          : _getLessonIcon(lesson.type),
                  color: lesson.isCompleted
                      ? Colors.green
                      : isLocked
                          ? Colors.grey
                          : Colors.blue,
                ),
              ),

              const SizedBox(width: 16),

              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isLocked ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getLessonIcon(lesson.type),
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.type.value.capitalize(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.duration} min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: isLocked ? Colors.grey[300] : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizSection(LearningModule module) {
    final allLessonsCompleted = module.isCompleted;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.deepOrange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Module Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${module.quiz!.questions.length} questions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            allLessonsCompleted
                ? 'Test your knowledge and earn ${module.pointsReward} points!'
                : 'Complete all lessons to unlock the quiz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: allLessonsCompleted
                  ? () => _navigateToQuiz(module)
                  : null,
              icon: Icon(allLessonsCompleted ? Icons.play_arrow : Icons.lock),
              label: Text(allLessonsCompleted ? 'Start Quiz' : 'Locked'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                disabledBackgroundColor: Colors.white38,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLesson(LearningLesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonContentScreen(lesson: lesson),
      ),
    );
    // Refresh module to update progress
    _loadModule();
  }

  void _navigateToQuiz(LearningModule module) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          quiz: module.quiz!,
          moduleId: module.id,
          moduleTitle: module.title,
        ),
      ),
    );

    if (result != null) {
      // Refresh module after quiz
      _loadModule();
    }
  }

  void _handleDownload(LearningModule module) async {
    final provider = context.read<LearningProvider>();

    if (module.isDownloaded) {
      // Show remove dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Download?'),
          content: const Text(
            'This will remove the offline content. You can download it again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await provider.removeDownloadedModule(module.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download removed')),
          );
        }
      }
    } else {
      // Download module
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading module for offline use...')),
      );
      await provider.downloadModule(module.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Module downloaded successfully!')),
        );
      }
    }
  }

  void _handleShare(LearningModule module) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share "${module.title}"')),
    );
  }

  IconData _getLessonIcon(LessonType type) {
    switch (type) {
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.article:
        return Icons.article_outlined;
      case LessonType.infographic:
        return Icons.image_outlined;
      case LessonType.interactive:
        return Icons.touch_app_outlined;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
