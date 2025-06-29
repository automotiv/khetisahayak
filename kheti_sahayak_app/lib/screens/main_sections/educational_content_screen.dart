import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';
import 'package:kheti_sahayak_app/services/educational_content_service.dart';

class EducationalContentScreen extends StatefulWidget {
  const EducationalContentScreen({super.key});

  @override
  State<EducationalContentScreen> createState() => _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen> {
  late Future<List<EducationalContent>> _educationalContentFuture;

  @override
  void initState() {
    super.initState();
    _educationalContentFuture = EducationalContentService.getEducationalContent();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EducationalContent>>(
      future: _educationalContentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No educational content available.'));
        } else {
          final contentList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              final content = contentList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        content.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category: ${content.category ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          Text(
                            'Date: ${content.createdAt.toLocal().toString().split(' ')[0]}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      // You might add a "Read More" button here
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}