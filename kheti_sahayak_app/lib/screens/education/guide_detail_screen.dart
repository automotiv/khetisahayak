import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:share_plus/share_plus.dart';

class GuideDetailScreen extends StatelessWidget {
  final EducationalContent guide;
  final Function(EducationalContent)? onBookmark;
  final Function(EducationalContent, int)? onRate;

  const GuideDetailScreen({
    Key? key,
    required this.guide,
    this.onBookmark,
    this.onRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareContent(guide),
          ),
          IconButton(
            icon: Icon(
              guide.isBookmarked ?? false ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: onBookmark != null ? () => onBookmark!(guide) : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            
            Text(
              guide.title,
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
                    guide.difficultyDisplay,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${guide.viewCount} views',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'By ${guide.authorFullName}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            if (guide.hasSummary) ...[
              Text(
                'Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                guide.summary!,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],
            
            Text(
              'Guide Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Assuming content is markdown or HTML, you can use flutter_markdown or html package
            // For now, just display as plain text
            Text(
              guide.content,
              style: theme.textTheme.bodyLarge,
            ),
            
            if (guide.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: guide.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.surfaceVariant,
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            if (onRate != null) ...[
              const Text('Rate this guide:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < (guide.userRating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => onRate!(guide, index + 1),
                )),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
  
  void _shareContent(EducationalContent content) {
    Share.share(
      'Check out this guide: ${content.title}\n\n${content.summary ?? ''}\n\nDownload Kheti Sahayak app for more content!',
      subject: 'Kheti Sahayak Guide: ${content.title}',
    );
  }
}
