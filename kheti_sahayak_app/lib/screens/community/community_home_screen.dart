import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/question.dart';
import 'package:kheti_sahayak_app/services/community_service.dart';
import 'package:kheti_sahayak_app/screens/community/question_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/community/ask_question_screen.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({Key? key}) : super(key: key);

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  List<Question> _questions = [];
  List<Tag> _popularTags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSort = 'recent';
  String? _selectedTag;
  bool? _filterAnswered;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _fetchTags();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final questions = await CommunityService.getQuestions(
        page: 1,
        sort: _selectedSort,
        tag: _selectedTag,
        answered: _filterAnswered,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _questions = questions;
        _isLoading = false;
        _hasMoreData = questions.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load questions')),
        );
      }
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final questions = await CommunityService.getQuestions(
        page: _currentPage + 1,
        sort: _selectedSort,
        tag: _selectedTag,
        answered: _filterAnswered,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _currentPage++;
        _questions.addAll(questions);
        _hasMoreData = questions.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _fetchTags() async {
    try {
      final tags = await CommunityService.getTags(limit: 20);
      setState(() => _popularTags = tags);
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  void _onSearchSubmitted(String query) {
    setState(() => _searchQuery = query);
    _fetchQuestions();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Recent'),
                    selected: _selectedSort == 'recent',
                    onSelected: (selected) {
                      setSheetState(() => _selectedSort = 'recent');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Most Votes'),
                    selected: _selectedSort == 'votes',
                    onSelected: (selected) {
                      setSheetState(() => _selectedSort = 'votes');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Most Views'),
                    selected: _selectedSort == 'views',
                    onSelected: (selected) {
                      setSheetState(() => _selectedSort = 'views');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Unanswered'),
                    selected: _selectedSort == 'unanswered',
                    onSelected: (selected) {
                      setSheetState(() => _selectedSort = 'unanswered');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterAnswered == null,
                    onSelected: (selected) {
                      setSheetState(() => _filterAnswered = null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Answered'),
                    selected: _filterAnswered == true,
                    onSelected: (selected) {
                      setSheetState(() => _filterAnswered = true);
                    },
                  ),
                  FilterChip(
                    label: const Text('Unanswered'),
                    selected: _filterAnswered == false,
                    onSelected: (selected) {
                      setSheetState(() => _filterAnswered = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _selectedSort = 'recent';
                        _filterAnswered = null;
                        _selectedTag = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchQuestions();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Q&A'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          if (_popularTags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _popularTags.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: const Text('All'),
                        backgroundColor: _selectedTag == null
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : null,
                        onPressed: () {
                          setState(() => _selectedTag = null);
                          _fetchQuestions();
                        },
                      ),
                    );
                  }
                  final tag = _popularTags[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(tag.name),
                      backgroundColor: _selectedTag == tag.name
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : null,
                      onPressed: () {
                        setState(() => _selectedTag = tag.name);
                        _fetchQuestions();
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchQuestions,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _questions.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _questions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildQuestionCard(_questions[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AskQuestionScreen()),
          );
          if (result == true) {
            _fetchQuestions();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to ask a question!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionDetailScreen(questionId: question.id),
            ),
          );
          if (result == true) {
            _fetchQuestions();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: question.profileImage != null
                        ? NetworkImage(question.profileImage!)
                        : null,
                    child: question.profileImage == null
                        ? Text(question.authorName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          timeago.format(question.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (question.isAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Answered',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                question.body,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (question.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: question.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(Icons.thumb_up_outlined, question.score.toString()),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    Icons.chat_bubble_outline,
                    '${question.answersCount} answers',
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.visibility_outlined, '${question.views}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
