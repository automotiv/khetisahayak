import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/community.dart';
import 'package:kheti_sahayak_app/models/community_post.dart';
import 'package:kheti_sahayak_app/services/community_service.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/screens/social/create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Community> _communities = [];
  List<CommunityPost> _posts = [];
  Community? _selectedCommunity;
  bool _isLoading = true;
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    final communities = await CommunityService.getCommunities();
    if (mounted) {
      setState(() {
        _communities = communities;
        if (communities.isNotEmpty) {
          _selectedCommunity = communities.first;
          _loadPosts(_selectedCommunity!.id);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts(int communityId) async {
    setState(() => _isLoadingPosts = true);
    final posts = await CommunityService.getPosts(communityId);
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (_selectedCommunity == null) return;

    final result = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(communityId: _selectedCommunity!.id),
      ),
    );

    if (result != null) {
      final success = await CommunityService.createPost(result);
      if (mounted) {
        if (success) {
          _loadPosts(_selectedCommunity!.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create post')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await CommunityService.syncPosts();
              if (_selectedCommunity != null) {
                _loadPosts(_selectedCommunity!.id);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCommunitySelector(),
                Expanded(
                  child: _isLoadingPosts
                      ? const Center(child: CircularProgressIndicator())
                      : _posts.isEmpty
                          ? const Center(child: Text('No posts yet. Be the first to share!'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                return _buildPostCard(post, localizations);
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCommunitySelector() {
    if (_communities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: DropdownButtonFormField<Community>(
        value: _selectedCommunity,
        decoration: const InputDecoration(
          labelText: 'Select Community',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: _communities.map((community) {
          return DropdownMenuItem<Community>(
            value: community,
            child: Text(
              community.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedCommunity = val);
            _loadPosts(val.id);
          }
        },
        isExpanded: true,
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0] : '?',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat.yMMMd(localizations.locale.toString()).format(post.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!post.synced)
                  const Icon(Icons.cloud_off, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.likes}'),
                const SizedBox(width: 24),
                Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.commentsCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
