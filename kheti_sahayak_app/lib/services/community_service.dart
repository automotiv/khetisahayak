import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/community.dart';
import 'package:kheti_sahayak_app/models/community_post.dart';
import 'package:kheti_sahayak_app/models/question.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _baseUrl = '${Constants.baseUrl}/api/community';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Question>> getQuestions({
    int page = 1,
    int limit = 20,
    String? tag,
    bool? answered,
    String sort = 'recent',
    String? search,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (tag != null) queryParams['tag'] = tag;
      if (answered != null) queryParams['answered'] = answered.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/questions')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Question.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  static Future<Question?> getQuestion(String id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/questions/$id'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Question.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching question: $e');
      return null;
    }
  }

  static Future<Question?> createQuestion({
    required String title,
    required String body,
    List<String>? tags,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/questions'),
        headers: _getHeaders(token),
        body: json.encode({
          'title': title,
          'body': body,
          'tags': tags ?? [],
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Question.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error creating question: $e');
      return null;
    }
  }

  static Future<bool> updateQuestion({
    required String id,
    String? title,
    String? body,
    List<String>? tags,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$_baseUrl/questions/$id'),
        headers: _getHeaders(token),
        body: json.encode({
          if (title != null) 'title': title,
          if (body != null) 'body': body,
          if (tags != null) 'tags': tags,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating question: $e');
      return false;
    }
  }

  static Future<bool> deleteQuestion(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_baseUrl/questions/$id'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting question: $e');
      return false;
    }
  }

  static Future<Answer?> createAnswer({
    required String questionId,
    required String body,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/questions/$questionId/answers'),
        headers: _getHeaders(token),
        body: json.encode({'body': body}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Answer.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error creating answer: $e');
      return null;
    }
  }

  static Future<bool> updateAnswer({
    required String answerId,
    required String body,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$_baseUrl/answers/$answerId'),
        headers: _getHeaders(token),
        body: json.encode({'body': body}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating answer: $e');
      return false;
    }
  }

  static Future<bool> deleteAnswer(String answerId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_baseUrl/answers/$answerId'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting answer: $e');
      return false;
    }
  }

  static Future<bool> acceptAnswer(String answerId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/answers/$answerId/accept'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting answer: $e');
      return false;
    }
  }

  static Future<int?> vote({
    required String id,
    required String type,
    required int voteType,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/vote/$id'),
        headers: _getHeaders(token),
        body: json.encode({
          'type': type,
          'voteType': voteType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['vote'];
      }
      return null;
    } catch (e) {
      print('Error voting: $e');
      return null;
    }
  }

  static Future<List<Tag>> getTags({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tags?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Tag.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching tags: $e');
      return [];
    }
  }

  static Future<List<Question>> getMyQuestions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/questions/my?page=$page&limit=$limit'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Question.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching my questions: $e');
      return [];
    }
  }

  static Future<List<Community>> getCommunities() async {
    try {
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
            await _dbHelper.cacheCommunities(items.cast<Map<String, dynamic>>());
            return items.map((item) => Community.fromJson(item)).toList();
          }
        }
      }
    } catch (e) {
      print('Error fetching communities from API: $e');
    }

    final cached = await _dbHelper.getCachedCommunities();
    return cached.map((map) => Community.fromJson(map)).toList();
  }

  static Future<List<CommunityPost>> getPosts(int communityId) async {
    try {
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

    final cachedMaps = await _dbHelper.getCachedCommunityPosts(communityId);
    return cachedMaps.map((map) => CommunityPost.fromMap(map)).toList();
  }

  static Future<bool> createPost(CommunityPost post) async {
    try {
      await _dbHelper.insertCommunityPost(post.toMap()..['dirty'] = 1..['synced'] = 0);
      _syncPost(post);
      return true;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

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
