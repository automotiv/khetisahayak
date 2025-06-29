import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';

class EducationalContentService {
  static Future<List<EducationalContent>> getEducationalContent() async {
    final response = await ApiService.get('educational-content');
    return (response['content'] as List)
        .map((contentJson) => EducationalContent.fromJson(contentJson))
        .toList();
  }

  static Future<EducationalContent> getEducationalContentById(String id) async {
    final response = await ApiService.get('educational-content/$id');
    return EducationalContent.fromJson(response['content']);
  }

  // You might add more methods here for creating, updating, or deleting content if needed
}