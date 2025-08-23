import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailScreen extends StatelessWidget {
  final EducationalContent article;
  final Function(EducationalContent)? onBookmark;
  final Function(EducationalContent, int)? onRate;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
    this.onBookmark,
    this.onRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareContent(article),
          ),
          IconButton(
            icon: Icon(
              article.isBookmarked ?? false ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: onBookmark != null ? () => onBookmark!(article) : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.hasImage)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(article.imageUrl!), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            Text(
              article.title,
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
                    article.difficultyDisplay,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${article.viewCount} views',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'By ${article.authorFullName}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            Text(
              article.content,
              style: theme.textTheme.bodyLarge,
            ),
            
            if (article.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: article.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: colorScheme.surfaceVariant,
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            if (onRate != null) ...[
              const Text('Rate this article:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < (article.userRating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => onRate!(article, index + 1),
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
      'Check out this article: ${content.title}\n\n${content.summary ?? ''}\n\nDownload Kheti Sahayak app for more content!',
      subject: 'Kheti Sahayak Article: ${content.title}',
    );
  }
}
