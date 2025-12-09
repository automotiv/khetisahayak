import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/lesson.dart';
import 'package:kheti_sahayak_app/services/education_service.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final int courseId;

  const LessonPlayerScreen({
    Key? key,
    required this.lesson,
    required this.courseId,
  }) : super(key: key);

  @override
  _LessonPlayerScreenState createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.isCompleted;
  }

  Future<void> _markComplete() async {
    await EducationService.markLessonComplete(widget.lesson.id, widget.courseId);
    setState(() {
      _isCompleted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson completed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.lesson.type == 'video'
                ? _buildVideoPlayer()
                : _buildArticleViewer(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCompleted ? null : _markComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isCompleted ? 'Completed' : 'Mark as Complete'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Video Player Placeholder\n${widget.lesson.contentUrl ?? "No URL"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleViewer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.lesson.contentUrl ?? 'No content available.',
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }
}
