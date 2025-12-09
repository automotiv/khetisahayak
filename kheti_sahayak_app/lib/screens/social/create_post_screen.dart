import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/community_post.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int communityId;

  const CreatePostScreen({Key? key, required this.communityId}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitPost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts or ask a question...',
                border: InputBorder.none,
              ),
              maxLines: 10,
              autofocus: true,
            ),
            // TODO: Add image picker
          ],
        ),
      ),
    );
  }

  void _submitPost() {
    if (_contentController.text.trim().isEmpty) return;

    final post = CommunityPost(
      communityId: widget.communityId,
      userName: 'Me', // Should come from user profile
      content: _contentController.text.trim(),
      timestamp: DateTime.now(),
      likes: 0,
      commentsCount: 0,
      synced: false,
      dirty: true,
    );

    Navigator.pop(context, post);
  }
}
