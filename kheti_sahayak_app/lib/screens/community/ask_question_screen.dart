import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/question.dart';
import 'package:kheti_sahayak_app/services/community_service.dart';

class AskQuestionScreen extends StatefulWidget {
  final Question? editQuestion;

  const AskQuestionScreen({Key? key, this.editQuestion}) : super(key: key);

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();

  List<String> _tags = [];
  List<Tag> _suggestedTags = [];
  bool _isSubmitting = false;
  bool _isLoadingTags = true;

  bool get isEditing => widget.editQuestion != null;

  @override
  void initState() {
    super.initState();
    _loadTags();
    if (isEditing) {
      _titleController.text = widget.editQuestion!.title;
      _bodyController.text = widget.editQuestion!.body;
      _tags = List.from(widget.editQuestion!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await CommunityService.getTags(limit: 30);
      setState(() {
        _suggestedTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() => _isLoadingTags = false);
    }
  }

  void _addTag(String tag) {
    final normalizedTag = tag.toLowerCase().trim();
    if (normalizedTag.isNotEmpty &&
        !_tags.contains(normalizedTag) &&
        _tags.length < 5) {
      setState(() {
        _tags.add(normalizedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (isEditing) {
        final success = await CommunityService.updateQuestion(
          id: widget.editQuestion!.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: _tags,
        );
        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question updated successfully')),
          );
        } else {
          throw Exception('Failed to update question');
        }
      } else {
        final question = await CommunityService.createQuestion(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: _tags,
        );
        if (question != null && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question posted successfully')),
          );
        } else {
          throw Exception('Failed to post question');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Question' : 'Ask a Question'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidelines(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildBodyField(),
              const SizedBox(height: 20),
              _buildTagsSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Tips for a great question',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Be specific about your farming problem'),
          _buildTip('Include relevant details (crop type, location, season)'),
          _buildTip('Check if a similar question exists first'),
          _buildTip('Use clear language in Hindi or English'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Be specific and summarize your question',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'e.g., How to treat yellow leaves on tomato plants?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 10) {
              return 'Title must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Describe your problem in detail',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          maxLines: 8,
          maxLength: 10000,
          decoration: InputDecoration(
            hintText:
                'Include all the information someone would need to answer your question:\n• What crop are you growing?\n• When did the problem start?\n• What have you tried so far?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please describe your question';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add up to 5 tags to help others find your question',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (_tags.length < 5)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add a tag (e.g., tomato, pest-control)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _addTag(_tagController.text),
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        if (!_isLoadingTags && _suggestedTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Popular tags:',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedTags
                .where((t) => !_tags.contains(t.name))
                .take(10)
                .map((tag) {
              return ActionChip(
                label: Text(tag.name),
                onPressed: () => _addTag(tag.name),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                isEditing ? 'Update Question' : 'Post Question',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
