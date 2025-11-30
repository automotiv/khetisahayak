import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:kheti_sahayak_app/services/educational_content_service.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_view.dart';

class EducationalContentScreen extends StatefulWidget {
  const EducationalContentScreen({super.key});

  @override
  State<EducationalContentScreen> createState() => _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Content lists
  final List<EducationalContent> _articles = [];
  final List<EducationalContent> _videos = [];
  final List<EducationalContent> _guides = [];
  List<EducationalContent> _popularContent = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  final int _perPage = 10;
  
  // Filters
  String? _selectedDifficulty;
  final List<String> _difficultyLevels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
  
  // Share plugin

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      await Future.wait([
        _loadContent(),
        _loadPopularContent(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadContent({bool loadMore = false}) async {
    if (_isLoadingMore || !_hasMore) return;
    
    try {
      setState(() => _isLoadingMore = true);
      
      final response = await EducationalContentService.getEducationalContent(
        page: _currentPage,
        limit: _perPage,
        category: _getCurrentCategory(),
        difficultyLevel: _selectedDifficulty,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      
      final List<EducationalContent> content = response['content'];
      
      setState(() {
        if (loadMore) {
          _updateContentList(content);
        } else {
          _resetContentLists();
          _updateContentList(content);
        }
        
        _hasMore = content.length == _perPage;
        if (_hasMore) _currentPage++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load content: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _loadPopularContent() async {
    try {
      final response = await EducationalContentService.getEducationalContent(
        limit: 5,
        sortBy: 'view_count',
        sortOrder: 'desc',
      );
      
      if (mounted) {
        setState(() {
          _popularContent = response['content'];
        });
      }
    } catch (e) {
      // Silently fail for popular content
      debugPrint('Failed to load popular content: $e');
    }
  }

  void _onSearchChanged() {
    _currentPage = 1;
    _hasMore = true;
    _loadContent();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadContent(loadMore: true);
    }
  }

  String? _getCurrentCategory() {
    switch (_tabController.index) {
      case 0: return 'article';
      case 1: return 'video';
      case 2: return 'guide';
      default: return null;
    }
  }

  void _updateContentList(List<EducationalContent> content) {
    switch (_tabController.index) {
      case 0: 
        _articles.addAll(content.where((c) => c.category == 'article'));
        break;
      case 1: 
        _videos.addAll(content.where((c) => c.category == 'video'));
        break;
      case 2: 
        _guides.addAll(content.where((c) => c.category == 'guide'));
        break;
    }
  }

  void _resetContentLists() {
    switch (_tabController.index) {
      case 0: _articles.clear(); break;
      case 1: _videos.clear(); break;
      case 2: _guides.clear(); break;
    }
  }

  List<EducationalContent> _getCurrentList() {
    switch (_tabController.index) {
      case 0: return _articles;
      case 1: return _videos;
      case 2: return _guides;
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Content'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _currentPage = 1;
            _hasMore = true;
            _loadContent();
          },
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Articles'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.menu_book), text: 'Guides'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search ${_getCurrentCategory()}s...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          
          // Popular Content Carousel
          if (_popularContent.isNotEmpty) _buildPopularContent(),
          
          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _error != null
                    ? ErrorView(
                        error: _error!,
                        onRetry: _loadInitialData,
                      )
                    : _buildContentList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularContent() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: _popularContent.length,
        itemBuilder: (context, index) {
          final content = _popularContent[index];
          return SizedBox(
            width: 280,
            child: _buildContentCard(content),
          );
        },
      ),
    );
  }
  
  Widget _buildContentList() {
    final currentList = _getCurrentList();
    
    if (currentList.isEmpty) {
      return const Center(
        child: Text('No content found. Try adjusting your filters.'),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: currentList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= currentList.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        return _buildContentCard(currentList[index]);
      },
    );
  }
  
  Widget _buildContentCard(EducationalContent content) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _navigateToDetail(content),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (content.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  content.imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (content.summary?.isNotEmpty ?? false)
                    Text(
                      content.summary!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          content.difficultyLevel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: _getDifficultyColor(content.difficultyLevel),
                      ),
                      Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${content.viewCount}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          content.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        content.createdAt.toLocal().toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall,
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
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green[100]!;
      case 'intermediate':
        return Colors.orange[100]!;
      case 'advanced':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
  
  void _navigateToDetail(EducationalContent content) {
    // Navigation logic to detail screen
    // This should be implemented based on your navigation setup
    debugPrint('Navigate to ${content.title}');
  }
  
  Future<void> _showFilterDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Content'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Difficulty Level'),
                ..._difficultyLevels.map((level) => RadioListTile<String>(
                  title: Text(level),
                  value: level,
                  groupValue: _selectedDifficulty ?? 'All',
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value == 'All' ? null : value!.toLowerCase();
                    });
                    Navigator.of(context).pop();
                    _currentPage = 1;
                    _hasMore = true;
                    _loadContent();
                  },
                )).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDifficulty = null;
                });
                Navigator.of(context).pop();
                _currentPage = 1;
                _hasMore = true;
                _loadContent();
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}