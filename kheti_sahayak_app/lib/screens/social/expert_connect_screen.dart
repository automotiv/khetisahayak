import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/expert.dart';
import 'package:kheti_sahayak_app/services/expert_service.dart';

class ExpertConnectScreen extends StatefulWidget {
  const ExpertConnectScreen({Key? key}) : super(key: key);

  @override
  _ExpertConnectScreenState createState() => _ExpertConnectScreenState();
}

class _ExpertConnectScreenState extends State<ExpertConnectScreen> {
  List<Expert> _experts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    final experts = await ExpertService.getExperts();
    if (mounted) {
      setState(() {
        _experts = experts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Connect'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _experts.length,
              itemBuilder: (context, index) {
                final expert = _experts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: Text(
                            expert.name[0],
                            style: TextStyle(fontSize: 24, color: Colors.green[800]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expert.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                expert.specialization,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  Text(' ${expert.rating}'),
                                  const SizedBox(width: 8),
                                  Text('${expert.experienceYears} yrs exp'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connection request sent!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                          ),
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
