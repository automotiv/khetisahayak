import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';

class DiagnosticService {
  static Future<List<Diagnostic>> getUserDiagnostics(String userId) async {
    final response = await ApiService.get('diagnostics/user/$userId');
    return (response['diagnostics'] as List)
        .map((diagnosticJson) => Diagnostic.fromJson(diagnosticJson))
        .toList();
  }

  static Future<Diagnostic> submitDiagnostic(Diagnostic diagnostic) async {
    final response = await ApiService.post('diagnostics', diagnostic.toJson());
    return Diagnostic.fromJson(response);
  }

  // You might add more methods here for updating or deleting diagnostics if needed
}