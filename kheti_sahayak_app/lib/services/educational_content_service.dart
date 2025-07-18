import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';

class EducationalContentService {
  // Get all educational content with filtering and pagination
  static Future<Map<String, dynamic>> getEducationalContent({
    int page = 1,
    int limit = 10,
    String? category,
    String? subcategory,
    String? difficultyLevel,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (category != null) queryParams['category'] = category;
    if (subcategory != null) queryParams['subcategory'] = subcategory;
    if (difficultyLevel != null) queryParams['difficulty_level'] = difficultyLevel;
    if (search != null) queryParams['search'] = search;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;

    final response = await ApiService.get('educational-content', queryParams: queryParams);
    
    return {
      'content': (response['content'] as List)
          .map((contentJson) => EducationalContent.fromJson(contentJson))
          .toList(),
      'pagination': response['pagination'],
    };
  }

  // Get educational content by ID
  static Future<EducationalContent> getEducationalContentById(String id) async {
    final response = await ApiService.get('educational-content/$id');
    return EducationalContent.fromJson(response['content']);
  }

  // Add new educational content (Admin/Content Creator)
  static Future<EducationalContent> addEducationalContent({
    required String title,
    required String content,
    required String category,
    String? summary,
    String? subcategory,
    String? difficultyLevel,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'category': category,
      if (summary != null) 'summary': summary,
      if (subcategory != null) 'subcategory': subcategory,
      if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      if (tags != null) 'tags': tags,
    };

    final response = await ApiService.post('educational-content', data);
    return EducationalContent.fromJson(response['content']);
  }

  // Update educational content
  static Future<EducationalContent> updateEducationalContent({
    required String id,
    String? title,
    String? content,
    String? summary,
    String? category,
    String? subcategory,
    String? difficultyLevel,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
    bool? isPublished,
  }) async {
    final data = <String, dynamic>{};
    
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (summary != null) data['summary'] = summary;
    if (category != null) data['category'] = category;
    if (subcategory != null) data['subcategory'] = subcategory;
    if (difficultyLevel != null) data['difficulty_level'] = difficultyLevel;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (videoUrl != null) data['video_url'] = videoUrl;
    if (tags != null) data['tags'] = tags;
    if (isPublished != null) data['is_published'] = isPublished;

    final response = await ApiService.put('educational-content/$id', data);
    return EducationalContent.fromJson(response['content']);
  }

  // Delete educational content
  static Future<void> deleteEducationalContent(String id) async {
    await ApiService.delete('educational-content/$id');
  }

  // Get content categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await ApiService.get('educational-content/categories');
    return List<Map<String, dynamic>>.from(response['categories']);
  }

  // Get content by category
  static Future<Map<String, dynamic>> getContentByCategory({
    required String category,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final response = await ApiService.get('educational-content/category/$category', queryParams: queryParams);
    
    return {
      'category': response['category'],
      'content': (response['content'] as List)
          .map((contentJson) => EducationalContent.fromJson(contentJson))
          .toList(),
      'pagination': response['pagination'],
    };
  }

  // Get popular content
  static Future<List<EducationalContent>> getPopularContent({int limit = 5}) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    final response = await ApiService.get('educational-content/popular', queryParams: queryParams);
    
    return (response['content'] as List)
        .map((contentJson) => EducationalContent.fromJson(contentJson))
        .toList();
  }

  // Get content analytics (Admin/Content Creator)
  static Future<Map<String, dynamic>> getContentAnalytics() async {
    final response = await ApiService.get('educational-content/analytics');
    return response['analytics'];
  }
}