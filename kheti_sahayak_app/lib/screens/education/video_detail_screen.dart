import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:share_plus/share_plus.dart';

class VideoDetailScreen extends StatefulWidget {
  final EducationalContent video;
  final Function(EducationalContent)? onBookmark;
  final Function(EducationalContent, int)? onRate;

  const VideoDetailScreen({
    Key? key,
    required this.video,
    this.onBookmark,
    this.onRate,
  }) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.video.videoUrl!);
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        placeholder: Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareContent(widget.video),
          ),
          IconButton(
            icon: Icon(
              widget.video.isBookmarked ?? false ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: widget.onBookmark != null 
                ? () => widget.onBookmark!(widget.video) 
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Chewie(controller: _chewieController!),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.video.difficultyDisplay,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.video.viewCount} views',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              'By ${widget.video.authorFullName}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        
                        if (widget.video.hasSummary) ...[
                          const Divider(height: 32),
                          Text(
                            widget.video.summary!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                        
                        if (widget.video.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.video.tags.map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: colorScheme.surfaceVariant,
                            )).toList(),
                          ),
                        ],
                        
                        if (widget.onRate != null) ...[
                          const Divider(height: 32),
                          const Text('Rate this video:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (index) => IconButton(
                              icon: Icon(
                                index < (widget.video.userRating ?? 0) ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () => widget.onRate!(widget.video, index + 1),
                            )),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  void _shareContent(EducationalContent content) {
    Share.share(
      'Check out this video: ${content.title}\n\n${content.summary ?? ''}\n\nDownload Kheti Sahayak app for more content!',
      subject: 'Kheti Sahayak Video: ${content.title}',
    );
  }
}
