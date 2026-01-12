import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/services/diagnostic_translation_service.dart';
import 'package:kheti_sahayak_app/models/localized_diagnostic.dart';

/// Widget to display diagnostic results with localization support
class LocalizedDiagnosticResultCard extends StatelessWidget {
  final Diagnostic diagnostic;
  final Map<String, dynamic>? aiAnalysis;
  final VoidCallback? onViewTreatment;

  const LocalizedDiagnosticResultCard({
    Key? key,
    required this.diagnostic,
    this.aiAnalysis,
    this.onViewTreatment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final langCode = languageService.currentLanguage.code;
        final translationService = DiagnosticTranslationService.instance;

        // Try to get localized disease info
        LocalizedDisease? localizedDisease;
        if (diagnostic.diagnosisResult != null) {
          localizedDisease =
              translationService.getDisease(diagnostic.diagnosisResult!);
        }

        final confidence = aiAnalysis != null && aiAnalysis!['confidence'] != null
            ? (aiAnalysis!['confidence'] * 100).toStringAsFixed(1)
            : null;

        // Get disease name - prefer localized, fall back to API response
        String diseaseName = _getDiseaseName(localizedDisease, langCode);

        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  DiagnosticStrings.get('analysis_results', langCode),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                // Disease Name
                Row(
                  children: [
                    Icon(
                      Icons.coronavirus,
                      color: Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DiagnosticStrings.get('disease_detected', langCode)}: $diseaseName',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),

                // Confidence
                if (confidence != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${DiagnosticStrings.get('confidence', langCode)}: $confidence%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],

                // Localized Description
                if (localizedDisease != null &&
                    localizedDisease.getDescription(langCode).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizedDisease.getDescription(langCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],

                // Localized Symptoms
                if (localizedDisease != null &&
                    localizedDisease.getSymptoms(langCode).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${DiagnosticStrings.get('symptoms', langCode)}:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedDisease.getSymptoms(langCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                // Localized Prevention
                if (localizedDisease != null &&
                    localizedDisease.getPrevention(langCode).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${DiagnosticStrings.get('prevention', langCode)}:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedDisease.getPrevention(langCode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[900],
                        ),
                  ),
                ],

                // Original recommendations if no localized data
                if (localizedDisease == null &&
                    diagnostic.recommendations != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${DiagnosticStrings.get('treatment_recommendations', langCode)}:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(diagnostic.recommendations!),
                ],

                // View Treatment Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewTreatment,
                    icon: const Icon(Icons.medical_services, color: Colors.white),
                    label: Text(
                      DiagnosticStrings.get('view_treatment_details', langCode),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDiseaseName(LocalizedDisease? localizedDisease, String langCode) {
    // Priority:
    // 1. Localized disease name
    // 2. AI analysis disease name
    // 3. Diagnostic result
    // 4. N/A
    if (localizedDisease != null) {
      return localizedDisease.getName(langCode);
    }
    if (aiAnalysis != null) {
      final diseaseData = aiAnalysis!['disease'];
      if (diseaseData is Map<String, dynamic> && diseaseData['name'] != null) {
        return diseaseData['name'];
      }
      if (diseaseData is String) {
        return diseaseData;
      }
    }
    return diagnostic.diagnosisResult ?? 'N/A';
  }
}

/// Compact card for recent analyses list
class LocalizedDiagnosticListItem extends StatelessWidget {
  final Diagnostic diagnostic;
  final VoidCallback? onTap;

  const LocalizedDiagnosticListItem({
    Key? key,
    required this.diagnostic,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final langCode = languageService.currentLanguage.code;
        final translationService = DiagnosticTranslationService.instance;

        // Try to get localized disease name
        String diseaseName = diagnostic.diagnosisResult ?? 'Unknown';
        if (diagnostic.diagnosisResult != null) {
          final localizedDisease =
              translationService.getDisease(diagnostic.diagnosisResult!);
          if (localizedDisease != null) {
            diseaseName = localizedDisease.getName(langCode);
          }
        }

        return Card(
          elevation: 2.0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diagnostic.cropType,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (diagnostic.diagnosisResult != null)
                    Text(
                      diseaseName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${diagnostic.status}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    DiagnosticStrings.get('view_treatment_details', langCode),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
