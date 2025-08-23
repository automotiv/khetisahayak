import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:kheti_sahayak_app/screens/education/article_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/education/guide_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/education/video_detail_screen.dart';
import 'package:kheti_sahayak_app/services/educational_content_service.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({Key? key}) : super(key: key);

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Data
  final List<EducationalContent> _articles = [];
  final List<EducationalContent> _videos = [];
  final List<EducationalContent> _guides = [];
  List<Map<String, dynamic>> _categories = [];
  List<EducationalContent> _popularContent = [];
  
  // Loading states
  bool _isLoadingArticles = false;
  bool _isLoadingVideos = false;
  bool _isLoadingGuides = false;
  bool _isLoadingCategories = false;
  
  // Pagination
  bool _hasMoreArticles = true;
  bool _hasMoreVideos = true;
  bool _hasMoreGuides = true;
  int _articlesPage = 1;
  int _videosPage = 1;
  int _guidesPage = 1;
  final int _perPage = 10;
  
  // Filter options
  String? _selectedCategory;
  String? _selectedDifficulty;
  final List<String> _difficultyOptions = ['All', 'beginner', 'intermediate', 'advanced'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadPopularContent(),
      _loadContent(),
    ]);
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    
    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadPopularContent(),
      _loadContent(),
    ]);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await EducationalContentService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load categories: $e',
          ),
        );
      }
    }
  }

  Future<void> _loadPopularContent() async {
    try {
      final popular = await EducationalContentService.getPopularContent(limit: 5);
      if (mounted) {
        setState(() {
          _popularContent = popular;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load popular content: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadContent() async {
    switch (_tabController.index) {
      case 0:
        await _loadArticles();
        break;
      case 1:
        await _loadVideos();
        break;
      case 2:
        await _loadGuides();
        break;
    }
  }

  Future<void> _loadArticles({bool refresh = false}) async {
    if ((_isLoadingArticles && !refresh) || (!_hasMoreArticles && !refresh)) return;
    
    try {
      setState(() => _isLoadingArticles = true);
      
      final page = refresh ? 1 : _articlesPage;
      
      final response = await EducationalContentService.getEducationalContent(
        page: page,
        limit: _perPage,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      if (mounted) {
        setState(() {
          if (refresh || page == 1) {
            _articles.clear();
            _articles.addAll(response['content']);
          } else {
            _articles.addAll(response['content']);
          }
          
          _hasMoreArticles = response['pagination']['hasNextPage'] ?? false;
          _articlesPage = page + 1;
          _isLoadingArticles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingArticles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load articles: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if ((_isLoadingVideos && !refresh) || (!_hasMoreVideos && !refresh)) return;
    
    try {
      setState(() => _isLoadingVideos = true);
      
      final page = refresh ? 1 : _videosPage;
      
      final response = await EducationalContentService.getEducationalContent(
        page: page,
        limit: _perPage,
        category: 'Video',
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      if (mounted) {
        setState(() {
          if (refresh || page == 1) {
            _videos.clear();
            _videos.addAll(response['content']);
          } else {
            _videos.addAll(response['content']);
          }
          
          _hasMoreVideos = response['pagination']['hasNextPage'] ?? false;
          _videosPage = page + 1;
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVideos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load videos: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadGuides({bool refresh = false}) async {
    if ((_isLoadingGuides && !refresh) || (!_hasMoreGuides && !refresh)) return;
    
    try {
      setState(() => _isLoadingGuides = true);
      
      final page = refresh ? 1 : _guidesPage;
      
      final response = await EducationalContentService.getEducationalContent(
        page: page,
        limit: _perPage,
        category: 'Guide',
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      if (mounted) {
        setState(() {
          if (refresh || page == 1) {
            _guides.clear();
            _guides.addAll(response['content']);
          } else {
            _guides.addAll(response['content']);
          }
          
          _hasMoreGuides = response['pagination']['hasNextPage'] ?? false;
          _guidesPage = page + 1;
          _isLoadingGuides = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGuides = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load guides: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged() {
    switch (_tabController.index) {
      case 0:
        _loadArticles(refresh: true);
        break;
      case 1:
        _loadVideos(refresh: true);
        break;
      case 2:
        _loadGuides(refresh: true);
        break;
    }
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    switch (_tabController.index) {
      case 0:
        _loadArticles(refresh: true);
        break;
      case 1:
        _loadVideos(refresh: true);
        break;
      case 2:
        _loadGuides(refresh: true);
        break;
    }
  }

  void _onDifficultyChanged(String? difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    switch (_tabController.index) {
      case 0:
        _loadArticles(refresh: true);
        break;
      case 1:
        _loadVideos(refresh: true);
        break;
      case 2:
        _loadGuides(refresh: true);
        break;
    }
  }

  void _onTabChanged() {
    switch (_tabController.index) {
      case 0:
        if (_articles.isEmpty) _loadArticles();
        break;
      case 1:
        if (_videos.isEmpty) _loadVideos();
        break;
      case 2:
        if (_guides.isEmpty) _loadGuides();
        break;
    }
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
          onTap: (index) => _onTabChanged(),
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
            ),
          ),
          
          // Categories
          if (!_isLoadingCategories && _categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1, // +1 for "All"
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == (index == 0 ? 'All' : _categories[index - 1]['name']);
                  final categoryName = index == 0 ? 'All' : _categories[index - 1]['name'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(categoryName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _onCategoryChanged(categoryName);
                        }
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
          
          // Difficulty filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Difficulty: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ..._difficultyOptions.map((difficulty) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(difficulty),
                    selected: _selectedDifficulty == difficulty,
                    onSelected: (selected) {
                      if (selected) {
                        _onDifficultyChanged(difficulty);
                      }
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedDifficulty == difficulty ? colorScheme.primary : theme.hintColor,
                      fontWeight: _selectedDifficulty == difficulty ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedDifficulty == difficulty 
                            ? colorScheme.primary 
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
          
          // Content
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
    return RefreshIndicator(
      onRefresh: () => _loadArticles(refresh: true),
      child: _isLoadingArticles && _articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? const Center(child: Text('No articles found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _articles.length + (_hasMoreArticles ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _articles.length) {
                      if (_hasMoreArticles) {
                        _loadArticles();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    
                    final article = _articles[index];
                    return _buildArticleCard(theme, colorScheme, article);
                  },
                ),
    );
  }

  Widget _buildVideosTab(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => _loadVideos(refresh: true),
      child: _isLoadingVideos && _videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? const Center(child: Text('No videos found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length + (_hasMoreVideos ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _videos.length) {
                      if (_hasMoreVideos) {
                        _loadVideos();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    
                    final video = _videos[index];
                    return _buildVideoCard(theme, colorScheme, video);
                  },
                ),
    );
  }

  Widget _buildGuidesTab(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: () => _loadGuides(refresh: true),
      child: _isLoadingGuides && _guides.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _guides.isEmpty
              ? const Center(child: Text('No guides found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _guides.length + (_hasMoreGuides ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _guides.length) {
                      if (_hasMoreGuides) {
                        _loadGuides();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    
                    final guide = _guides[index];
                    return _buildGuideCard(theme, colorScheme, guide);
                  },
                ),
    );
  }

  Future<void> _toggleBookmark(EducationalContent content) async {
    try {
      // Determine which list contains this content
      List<EducationalContent> targetList;
      if (_articles.any((a) => a.id == content.id)) {
        targetList = _articles;
      } else if (_videos.any((v) => v.id == content.id)) {
        targetList = _videos;
      } else if (_guides.any((g) => g.id == content.id)) {
        targetList = _guides;
      } else {
        return;
      }

      // Toggle bookmark status locally
      setState(() {
        final index = targetList.indexWhere((c) => c.id == content.id);
        if (index != -1) {
          targetList[index] = targetList[index].copyWith(
            isBookmarked: !(targetList[index].isBookmarked ?? false),
          );
        }
      });

      // Call API to update bookmark status
      final response = await EducationalContentService.toggleBookmark(content.id);
      
      // If API call fails, revert the local change
      if (response == null) {
        setState(() {
          final index = targetList.indexWhere((c) => c.id == content.id);
          if (index != -1) {
            targetList[index] = targetList[index].copyWith(
              isBookmarked: !targetList[index].isBookmarked!,
            );
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update bookmark')),
          );
        }
      }
    } catch (e) {
      // Revert local change on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rateContent(EducationalContent content, int rating) async {
    try {
      // Determine which list contains this content
      List<EducationalContent> targetList;
      if (_articles.any((a) => a.id == content.id)) {
        targetList = _articles;
      } else if (_videos.any((v) => v.id == content.id)) {
        targetList = _videos;
      } else if (_guides.any((g) => g.id == content.id)) {
        targetList = _guides;
      } else {
        return;
      }

      // Update rating locally
      setState(() {
        final index = targetList.indexWhere((c) => c.id == content.id);
        if (index != -1) {
          targetList[index] = targetList[index].copyWith(
            userRating: rating.toInt(),
          );
        }
      });

      // Call API to update rating
      await EducationalContentService.rateContent(content.id, rating.toInt());
      
      // Refresh content to get updated average rating
      _loadContent();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
      }
    } catch (e) {
      // Revert local change on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildArticleCard(ThemeData theme, ColorScheme colorScheme, EducationalContent article) {
    return _buildContentCard(article);
  Widget _buildVideoCard(ThemeData theme, ColorScheme colorScheme, EducationalContent video) {
    return _buildContentCard(video);
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(
                video: video,
                onBookmark: _toggleBookmark,
                onRate: _rateContent,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (video.hasVideo)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      color: colorScheme.surfaceVariant,
                    ),
                    child: const Center(
                      child: Icon(
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  if (content.summary != null && content.summary!.isNotEmpty)
                    Text(
                      content.summary!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.0,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        content.difficultyLevel.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Theme.of(context).primaryColor : null,
                            ),
                            onPressed: () => _toggleBookmark(content),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _shareContent(content),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (userRating != null && userRating > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16.0),
                          const SizedBox(width: 4.0),
                          Text(
                            userRating.toString(),
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToDetailScreen(EducationalContent content) {
    switch (content.category.toLowerCase()) {
      case 'article':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(
              article: content,
              onBookmark: _toggleBookmark,
              onRate: _rateContent,
            ),
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
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
                        const Spacer(),
                        Text(
                          '${guide.viewCount} views',
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
      ),
    );
  }
}
