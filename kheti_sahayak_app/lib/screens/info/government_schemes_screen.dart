import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({Key? key}) : super(key: key);

  @override
  _GovernmentSchemesScreenState createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  List<Scheme> _schemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    final schemes = await SchemeService.getSchemes();
    if (mounted) {
      setState(() {
        _schemes = schemes;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schemes.length,
              itemBuilder: (context, index) {
                final scheme = _schemes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      scheme.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      scheme.category ?? 'General',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(scheme.description),
                            const SizedBox(height: 8),
                            if (scheme.benefits != null) ...[
                              const Text(
                                'Benefits:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(scheme.benefits!),
                              const SizedBox(height: 8),
                            ],
                            if (scheme.eligibility != null) ...[
                              const Text(
                                'Eligibility:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(scheme.eligibility!),
                              const SizedBox(height: 8),
                            ],
                            if (scheme.link != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _launchUrl(scheme.link!),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Visit Website'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
