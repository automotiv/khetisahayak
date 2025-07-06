import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({Key? key}) : super(key: key);

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'All',
    'Crops',
    'Soil',
    'Pest Control',
    'Irrigation',
    'Organic Farming',
    'Techniques',
  ];
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  
  // Mock data for demonstration
  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Organic Farming Techniques for Beginners',
      'category': 'Organic Farming',
      'readTime': '5 min read',
      'level': 'Beginner',
      'image': 'assets/images/education/organic_farming.jpg',
    },
    {
      'title': 'Understanding Soil Types and Their Impact on Crops',
      'category': 'Soil',
      'readTime': '8 min read',
      'level': 'Intermediate',
      'image': 'assets/images/education/soil_types.jpg',
    },
    {
      'title': 'Drip Irrigation: A Complete Guide',
      'category': 'Irrigation',
      'readTime': '6 min read',
      'level': 'Beginner',
      'image': 'assets/images/education/drip_irrigation.jpg',
    },
    {
      'title': 'Natural Pest Control Methods',
      'category': 'Pest Control',
      'readTime': '7 min read',
      'level': 'Intermediate',
      'image': 'assets/images/education/pest_control.jpg',
    },
  ];
  
  final List<Map<String, dynamic>> _videos = [
    {
      'title': 'How to Start a Small Organic Farm',
      'channel': 'Farmers Guide',
      'duration': '12:45',
      'views': '24K',
      'thumbnail': 'assets/images/education/video1.jpg',
    },
    {
      'title': 'Soil Preparation for Vegetable Garden',
      'channel': 'AgriTech',
      'duration': '8:32',
      'views': '15K',
      'thumbnail': 'assets/images/education/video2.jpg',
    },
    {
      'title': 'Composting at Home: A Complete Guide',
      'channel': 'Eco Farming',
      'duration': '15:20',
      'views': '32K',
      'thumbnail': 'assets/images/education/video3.jpg',
    },
  ];
  
  final List<Map<String, dynamic>> _guides = [
    {
      'title': 'Step-by-Step Guide to Crop Rotation',
      'pages': 12,
      'downloads': '5.2K',
      'icon': Icons.agriculture_outlined,
    },
    {
      'title': 'Pesticide Application Handbook',
      'pages': 18,
      'downloads': '3.8K',
      'icon': Icons.bug_report_outlined,
    },
    {
      'title': 'Sustainable Farming Practices',
      'pages': 24,
      'downloads': '7.1K',
      'icon': Icons.eco_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Center'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Videos'),
            Tab(text: 'Guides'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for topics, crops, techniques...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Handle search
              },
            ),
          ),
          
          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryIndex = selected ? index : 0;
                      });
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : theme.hintColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected 
                            ? colorScheme.primary 
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tab bar view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArticlesTab(theme, colorScheme),
                _buildVideosTab(theme, colorScheme),
                _buildGuidesTab(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildArticlesTab(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return _buildArticleCard(theme, colorScheme, article, index);
      },
    );
  }
  
  Widget _buildArticleCard(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> article, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to article detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                image: const DecorationImage(
                  image: AssetImage('assets/images/education/article_placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Article content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and read time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article['category'],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article['readTime'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          article['level'],
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    article['title'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        theme,
                        icon: Icons.bookmark_border_outlined,
                        label: 'Save',
                        onTap: () {
                          // Save article
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        theme,
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {
                          // Share article
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Read more
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Read More'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideosTab(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(theme, colorScheme, video, index);
      },
    );
  }
  
  Widget _buildVideoCard(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> video, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Play video
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/education/video_placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video['duration'],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Video info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video['title'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Channel and views
                  Row(
                    children: [
                      Text(
                        video['channel'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${video['views']} views',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGuidesTab(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _guides.length,
      itemBuilder: (context, index) {
        final guide = _guides[index];
        return _buildGuideCard(theme, colorScheme, guide, index);
      },
    );
  }
  
  Widget _buildGuideCard(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> guide, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Open guide
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Guide icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  guide['icon'],
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Guide info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      guide['title'],
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Meta info
                    Row(
                      children: [
                        // Pages
                        Row(
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${guide['pages']} pages',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Downloads
                        Row(
                          children: [
                            const Icon(
                              Icons.download_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${guide['downloads']} downloads',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Download button
              IconButton(
                onPressed: () {
                  // Download guide
                },
                icon: const Icon(Icons.download_outlined),
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.hintColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
