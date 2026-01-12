import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kheti_sahayak_app/models/learning_module.dart';
import 'package:kheti_sahayak_app/providers/learning_provider.dart';

/// Screen displaying lesson content (article, video, infographic)
class LessonContentScreen extends StatefulWidget {
  final LearningLesson lesson;

  const LessonContentScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  bool _isCompleting = false;
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateReadProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateReadProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateReadProgress() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (maxScroll > 0) {
      setState(() {
        _readProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _markComplete() async {
    if (_isCompleting || widget.lesson.isCompleted) return;

    setState(() => _isCompleting = true);

    try {
      await context.read<LearningProvider>().completeLesson(widget.lesson.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Lesson completed! +10 points'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with progress
          _buildAppBar(),

          // Content based on lesson type
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: widget.lesson.hasImages ? 200 : 0,
      backgroundColor: Colors.green[700],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontSize: 16),
        ),
        background: widget.lesson.hasImages
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.lesson.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.green[200]),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.green[200]),
                  ),
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
              )
            : null,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: _readProgress,
          backgroundColor: Colors.green[900],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.lesson.type) {
      case LessonType.article:
        return _buildArticleContent();
      case LessonType.video:
        return _buildVideoContent();
      case LessonType.infographic:
        return _buildInfographicContent();
      case LessonType.interactive:
        return _buildInteractiveContent();
    }
  }

  Widget _buildArticleContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson metadata
          _buildMetadataRow(),
          const SizedBox(height: 24),

          // Content
          if (widget.lesson.content != null)
            _buildMarkdownContent(widget.lesson.content!),

          // Images gallery if multiple images
          if (widget.lesson.imageUrls.length > 1) ...[
            const SizedBox(height: 24),
            _buildImageGallery(),
          ],

          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Column(
      children: [
        // Video player placeholder
        Container(
          height: 220,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.lesson.hasImages)
                CachedNetworkImage(
                  imageUrl: widget.lesson.imageUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow, size: 36),
                  color: Colors.green[700],
                  onPressed: () {
                    // TODO: Play video
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video player would open here'),
                      ),
                    );
                  },
                ),
              ),
              // Duration badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.lesson.duration}:00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Description
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetadataRow(),
              const SizedBox(height: 16),
              if (widget.lesson.content != null)
                _buildMarkdownContent(widget.lesson.content!),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfographicContent() {
    return Column(
      children: [
        // Infographic images
        ...widget.lesson.imageUrls.map((url) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.fitWidth,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                ),
              ),
            )),

        // Description
        if (widget.lesson.content != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMarkdownContent(widget.lesson.content!),
          ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildInteractiveContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow(),
          const SizedBox(height: 24),

          // Interactive placeholder
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.touch_app, size: 64, color: Colors.blue[400]),
                const SizedBox(height: 16),
                Text(
                  'Interactive Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This interactive lesson would load here with exercises and activities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ),
          ),

          if (widget.lesson.content != null) ...[
            const SizedBox(height: 24),
            _buildMarkdownContent(widget.lesson.content!),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Row(
      children: [
        _buildMetadataChip(
          icon: _getLessonTypeIcon(),
          label: widget.lesson.type.value.toUpperCase(),
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildMetadataChip(
          icon: Icons.timer_outlined,
          label: '${widget.lesson.duration} min',
          color: Colors.grey[700]!,
        ),
        if (widget.lesson.isCompleted) ...[
          const SizedBox(width: 8),
          _buildMetadataChip(
            icon: Icons.check_circle,
            label: 'Completed',
            color: Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    // Simple markdown-like rendering
    final paragraphs = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        final trimmed = paragraph.trim();

        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed.substring(3),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Text(
              trimmed.substring(2),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (trimmed.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('  ', style: TextStyle(fontSize: 16)),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            trimmed,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.lesson.imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.lesson.imageUrls.length - 1 ? 12 : 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Open fullscreen image viewer
                    },
                    child: CachedNetworkImage(
                      imageUrl: widget.lesson.imageUrls[index],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
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
            // Progress indicator
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lesson.isCompleted ? 'Completed' : 'Reading progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.lesson.isCompleted ? 1.0 : _readProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.lesson.isCompleted
                            ? Colors.green
                            : Colors.blue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Complete button
            ElevatedButton.icon(
              onPressed: widget.lesson.isCompleted || _isCompleting
                  ? null
                  : _markComplete,
              icon: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      widget.lesson.isCompleted
                          ? Icons.check_circle
                          : Icons.check,
                    ),
              label: Text(
                widget.lesson.isCompleted ? 'Completed' : 'Mark Complete',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.lesson.isCompleted
                    ? Colors.green
                    : Colors.green[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green[200],
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLessonTypeIcon() {
    switch (widget.lesson.type) {
      case LessonType.article:
        return Icons.article_outlined;
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.infographic:
        return Icons.image_outlined;
      case LessonType.interactive:
        return Icons.touch_app_outlined;
    }
  }
}
