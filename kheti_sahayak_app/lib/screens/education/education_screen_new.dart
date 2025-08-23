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
      final content = await EducationalContentService.getEducationalContent(
        limit: 5,
        sortBy: 'views',
        sortOrder: 'desc',
      );
      setState(() {
        _popularContent = content;
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load popular content: $e',
          ),
        );
      }
    }
  }

  Future<void> _loadContent({bool loadMore = false}) async {
    if (_isLoadingArticles || _isLoadingVideos || _isLoadingGuides) return;

    if (!loadMore) {
      setState(() {
        _articlesPage = 1;
        _videosPage = 1;
        _guidesPage = 1;
        _articles.clear();
        _videos.clear();
        _guides.clear();
      });
    }

    await Future.wait([
      _loadArticles(loadMore: loadMore),
      _loadVideos(loadMore: loadMore),
      _loadGuides(loadMore: loadMore),
    ]);
  }

  Future<void> _loadArticles({bool loadMore = false}) async {
    if (_isLoadingArticles || (!loadMore && !_hasMoreArticles)) return;
    
    setState(() {
      _isLoadingArticles = true;
    });

    try {
      final articles = await EducationalContentService.getEducationalContent(
        page: _articlesPage,
        limit: _perPage,
        category: 'article',
        difficultyLevel: _selectedDifficulty,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _articles.addAll(articles);
        _hasMoreArticles = articles.length == _perPage;
        if (articles.isNotEmpty) _articlesPage++;
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

  Future<void> _loadVideos({bool loadMore = false}) async {
    if (_isLoadingVideos || (!loadMore && !_hasMoreVideos)) return;
    
    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final videos = await EducationalContentService.getEducationalContent(
        page: _videosPage,
        limit: _perPage,
        category: 'video',
        difficultyLevel: _selectedDifficulty,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _videos.addAll(videos);
        _hasMoreVideos = videos.length == _perPage;
        if (videos.isNotEmpty) _videosPage++;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVideos = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load videos: $e',
          ),
        );
      }
    }
  }

  Future<void> _loadGuides({bool loadMore = false}) async {
    if (_isLoadingGuides || (!loadMore && !_hasMoreGuides)) return;
    
    setState(() {
      _isLoadingGuides = true;
    });

    try {
      final guides = await EducationalContentService.getEducationalContent(
        page: _guidesPage,
        limit: _perPage,
        category: 'guide',
        difficultyLevel: _selectedDifficulty,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _guides.addAll(guides);
        _hasMoreGuides = guides.length == _perPage;
        if (guides.isNotEmpty) _guidesPage++;
        _isLoadingGuides = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGuides = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load guides: $e',
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _loadContent();
  }

  Future<void> _toggleBookmark(EducationalContent content) async {
    try {
      final updatedContent = await EducationalContentService.toggleBookmark(content.id);
      _updateContentInLists(updatedContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bookmark: $e')),
        );
      }
    }
  }

  Future<void> _rateContent(String contentId, int rating) async {
    try {
      final updatedContent = await EducationalContentService.rateContent(contentId, rating);
      _updateContentInLists(updatedContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  void _updateContentInLists(EducationalContent updatedContent) {
    setState(() {
      final updateList = (List<EducationalContent> list) {
        final index = list.indexWhere((c) => c.id == updatedContent.id);
        if (index != -1) {
          list[index] = updatedContent;
        }
      };

      updateList(_articles);
      updateList(_videos);
      updateList(_guides);
      updateList(_popularContent);
    });
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
          ),
        );
        break;
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailScreen(
              video: content,
              onBookmark: _toggleBookmark,
              onRate: _rateContent,
            ),
          ),
        );
        break;
      case 'guide':
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuideDetailScreen(
              guide: content,
              onBookmark: _toggleBookmark,
              onRate: _rateContent,
            ),
          ),
        );
    }
  }

  Widget _buildContentCard(EducationalContent content) {
    final isBookmarked = content.isBookmarked ?? false;
    final userRating = content.userRating;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: InkWell(
        onTap: () => _navigateToDetailScreen(content),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (content.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
                child: Image.network(
                  content.imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 150,
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
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

  Future<void> _shareContent(EducationalContent content) async {
    try {
      final url = 'https://khetisahayak.com/education/${content.id}';
      await Share.share(
        'Check out this ${content.category}: ${content.title}\n\n$url',
        subject: '${content.category} from Kheti Sahayak',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share content')),
        );
      }
    }
  }

  Widget _buildPopularContent() {
    if (_popularContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Popular Now',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: _popularContent.length,
            itemBuilder: (context, index) {
              final content = _popularContent[index];
              return SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: _buildContentCard(content),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentList(List<EducationalContent> items, bool isLoading, bool hasMore,
      {VoidCallback? onLoadMore}) {
    if (items.isEmpty && !isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No content found'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          if (onLoadMore != null) {
            onLoadMore();
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildContentCard(items[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Education'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.article), text: 'Articles'),
              Tab(icon: Icon(Icons.video_library), text: 'Videos'),
              Tab(icon: Icon(Icons.menu_book), text: 'Guides'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search education content...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            _buildPopularContent(),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Articles Tab
                  _buildContentList(
                    _articles,
                    _isLoadingArticles,
                    _hasMoreArticles,
                    onLoadMore: () => _loadArticles(loadMore: true),
                  ),
                  // Videos Tab
                  _buildContentList(
                    _videos,
                    _isLoadingVideos,
                    _hasMoreVideos,
                    onLoadMore: () => _loadVideos(loadMore: true),
                  ),
                  // Guides Tab
                  _buildContentList(
                    _guides,
                    _isLoadingGuides,
                    _hasMoreGuides,
                    onLoadMore: () => _loadGuides(loadMore: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
