import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/services/educational_content_service.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({Key? key}) : super(key: key);

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Data
  List<EducationalContent> _articles = [];
  List<EducationalContent> _videos = [];
  List<EducationalContent> _guides = [];
  List<Map<String, dynamic>> _categories = [];
  List<EducationalContent> _popularContent = [];
  
  // Loading states
  bool _isLoadingArticles = false;
  bool _isLoadingVideos = false;
  bool _isLoadingGuides = false;
  bool _isLoadingCategories = false;
  bool _isLoadingPopular = false;
  
  // Filter options
  String? _selectedCategory;
  String? _selectedDifficulty;
  String? _searchQuery;
  final List<String> _difficultyOptions = ['All', 'beginner', 'intermediate', 'advanced'];
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreArticles = true;
  bool _hasMoreVideos = true;
  bool _hasMoreGuides = true;

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
      _loadArticles(),
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
    setState(() {
      _isLoadingPopular = true;
    });

    try {
      final popular = await EducationalContentService.getPopularContent(limit: 5);
      setState(() {
        _popularContent = popular;
        _isLoadingPopular = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPopular = false;
      });
    }
  }

  Future<void> _loadArticles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreArticles = true;
      });
    }

    if (!_hasMoreArticles || _isLoadingArticles) return;

    setState(() {
      _isLoadingArticles = true;
    });

    try {
      final result = await EducationalContentService.getEducationalContent(
        page: _currentPage,
        limit: 10,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchQuery,
      );
      
      final newArticles = result['content'] as List<EducationalContent>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      
      setState(() {
        if (refresh) {
          _articles = newArticles;
        } else {
          _articles.addAll(newArticles);
        }
        _hasMoreArticles = pagination['hasNext'] ?? false;
        _isLoadingArticles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingArticles = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load articles: $e',
          ),
        );
      }
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreVideos = true;
      });
    }

    if (!_hasMoreVideos || _isLoadingVideos) return;

    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final result = await EducationalContentService.getEducationalContent(
        page: _currentPage,
        limit: 10,
        category: 'Videos',
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchQuery,
      );
      
      final newVideos = result['content'] as List<EducationalContent>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      
      setState(() {
        if (refresh) {
          _videos = newVideos;
        } else {
          _videos.addAll(newVideos);
        }
        _hasMoreVideos = pagination['hasNext'] ?? false;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
      });
    }
  }

  Future<void> _loadGuides({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreGuides = true;
      });
    }

    if (!_hasMoreGuides || _isLoadingGuides) return;

    setState(() {
      _isLoadingGuides = true;
    });

    try {
      final result = await EducationalContentService.getEducationalContent(
        page: _currentPage,
        limit: 10,
        category: 'Guides',
        difficultyLevel: _selectedDifficulty == 'All' ? null : _selectedDifficulty,
        search: _searchQuery,
      );
      
      final newGuides = result['content'] as List<EducationalContent>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      
      setState(() {
        if (refresh) {
          _guides = newGuides;
        } else {
          _guides.addAll(newGuides);
        }
        _hasMoreGuides = pagination['hasNext'] ?? false;
        _isLoadingGuides = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGuides = false;
      });
    }
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
    _loadArticles(refresh: true);
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadArticles(refresh: true);
  }

  void _onDifficultyChanged(String? difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    _loadArticles(refresh: true);
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

  Widget _buildArticleCard(ThemeData theme, ColorScheme colorScheme, EducationalContent article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to article detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (article.hasImage)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(article.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (article.hasSummary)
                Text(
                  article.summary!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
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
                  const Spacer(),
                  Text(
                    '${article.viewCount} views',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(ThemeData theme, ColorScheme colorScheme, EducationalContent video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to video player
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
                        Icons.play_circle_outline,
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Video',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${video.authorFullName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
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
                          video.difficultyDisplay,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${video.viewCount} views',
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

  Widget _buildGuideCard(ThemeData theme, ColorScheme colorScheme, EducationalContent guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to guide detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
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
