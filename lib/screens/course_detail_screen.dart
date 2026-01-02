import 'package:flutter/material.dart';
import '../services/CourseService.dart';
import '../config/config_url.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  Map<String, dynamic>? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final result = await _courseService.getCourseDetail(widget.courseId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _course = result['course'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: Text('Course not found')),
      );
    }

    String? imageUrl;
    if (_course!['image_path'] != null) {
      String base = Config_URL.baseUrl.replaceAll('/api/', '');
      imageUrl = "$base/${_course!['image_path']}";
    }

    final classes = _course!['classes'] as List? ?? [];
    final materials = _course!['materials'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_course!['course_name'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_course!['course_name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_course!['description'] ?? 'No description'),
                  const SizedBox(height: 16),
                  Text('Duration: ${_course!['formatted_start_date']} to ${_course!['formatted_end_date']}'),
                  Text('Tuition: ${_course!['tuition_fee']?.toString() ?? 'N/A'} VND'),
                  const Divider(height: 32),
                  const Text('Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (classes.isEmpty)
                    const Text('No classes assigned')
                  else
                    ...classes.map((cls) => Card(
                          child: ListTile(
                            title: Text(cls['class_name']),
                            subtitle: Text('Teacher: ${cls['teacher_name']}\nSchedule: ${cls['schedule']}\nTime: ${cls['start_time']} - ${cls['end_time']}'),
                            trailing: Text('${cls['student_count']} Students'),
                          ),
                        )),
                  const Divider(height: 32),
                  const Text('Materials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (materials.isEmpty)
                    const Text('No materials uploaded')
                  else
                    ...materials.map((mat) => ListTile(
                          leading: const Icon(Icons.file_present),
                          title: Text(mat['file_name']),
                          subtitle: Text('Uploaded at: ${mat['uploaded_at']}'),
                          onTap: () {
                            // TODO: Add material download/view functionality
                          },
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
