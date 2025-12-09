import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/course.dart';
import 'package:kheti_sahayak_app/models/module.dart';
import 'package:kheti_sahayak_app/models/lesson.dart';
import 'package:kheti_sahayak_app/services/education_service.dart';
import 'package:kheti_sahayak_app/screens/education/lesson_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  const CourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    setState(() => _isLoading = true);
    final course = await EducationService.getCourseDetails(widget.courseId);
    if (mounted) {
      setState(() {
        _course = course;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load course details.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_course!.title),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_course!.thumbnailUrl != null)
              Image.network(
                _course!.thumbnailUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _course!.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_course!.description),
                  const SizedBox(height: 16),
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Syllabus',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildModulesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Calculate progress locally if needed, or use course.completedLessons
    // For now, let's assume course.completedLessons is updated or we calculate it from modules
    int total = 0;
    int completed = 0;
    
    for (var module in _course!.modules) {
      total += module.lessons.length;
      completed += module.lessons.where((l) => l.isCompleted).length;
    }

    double progress = total > 0 ? completed / total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress: ${(progress * 100).toInt()}%'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: Colors.green,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildModulesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _course!.modules.length,
      itemBuilder: (context, index) {
        final module = _course!.modules[index];
        return _buildModuleTile(module);
      },
    );
  }

  Widget _buildModuleTile(Module module) {
    return ExpansionTile(
      title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: module.lessons.map((lesson) => _buildLessonTile(lesson)).toList(),
    );
  }

  Widget _buildLessonTile(Lesson lesson) {
    return ListTile(
      leading: Icon(
        lesson.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
        color: lesson.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(lesson.title),
      subtitle: Text('${lesson.duration} min • ${lesson.type}'),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonPlayerScreen(
              lesson: lesson,
              courseId: _course!.id,
            ),
          ),
        );
        _loadCourseDetails(); // Refresh progress
      },
    );
  }
}
