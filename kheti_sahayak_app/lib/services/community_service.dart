import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/community.dart';
import 'package:kheti_sahayak_app/models/community_post.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get communities (Offline First)
  static Future<List<Community>> getCommunities() async {
    try {
      // 1. Try to fetch from API
      final token = await _getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${Constants.baseUrl}/api/communities'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            // Cache them
            await _dbHelper.cacheCommunities(items.cast<Map<String, dynamic>>());
            return items.map((item) => Community.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching communities from API: $e');
    }

    // 2. Fallback to cache
    final cached = await _dbHelper.getCachedCommunities();
    return cached.map((map) => Community.fromJson(map)).toList();
  }

  /// Get posts for a community (Offline First)
  static Future<List<CommunityPost>> getPosts(int communityId) async {
    try {
      // 1. Try to fetch from API
      final token = await _getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('${Constants.baseUrl}/api/communities/$communityId/posts'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final List<dynamic> items = data['data'];
            // Cache posts
            for (var item in items) {
              final post = CommunityPost.fromJson(item);
              await _dbHelper.insertCommunityPost(post.toMap());
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching posts from API: $e');
    }

    // 2. Return cached + local dirty posts
    final cachedMaps = await _dbHelper.getCachedCommunityPosts(communityId);
    return cachedMaps.map((map) => CommunityPost.fromMap(map)).toList();
  }

  /// Create a post (Offline First)
  static Future<bool> createPost(CommunityPost post) async {
    try {
      // 1. Save locally
      await _dbHelper.insertCommunityPost(post.toMap()..['dirty'] = 1..['synced'] = 0);

      // 2. Trigger sync
      _syncPost(post);
      
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  /// Sync dirty posts
  static Future<void> syncPosts() async {
    try {
      final dirtyPosts = await _dbHelper.getDirtyCommunityPosts();
      for (var map in dirtyPosts) {
        final post = CommunityPost.fromMap(map);
        await _syncPost(post);
      }
    } catch (e) {
      print('Error syncing posts: $e');
    }
  }

  static Future<void> _syncPost(CommunityPost post) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/api/communities/${post.communityId}/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': post.content,
          // Handle image upload if needed
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final backendId = data['data']['id'];
          await _dbHelper.markPostSynced(post.localId!, backendId);
        }
      }
    } catch (e) {
      print('Error syncing single post: $e');
    }
  }
}
