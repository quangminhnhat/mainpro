import 'package:flutter/material.dart';
import '../services/CourseService.dart';
import '../config/config_url.dart';

class AvailableCoursesScreen extends StatefulWidget {
  const AvailableCoursesScreen({super.key});

  @override
  State<AvailableCoursesScreen> createState() => _AvailableCoursesScreenState();
}

class _AvailableCoursesScreenState extends State<AvailableCoursesScreen> {
  final CourseService _courseService = CourseService();
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableCourses();
  }

  Future<void> _fetchAvailableCourses() async {
    setState(() => _isLoading = true);
    final result = await _courseService.getAvailableCourses();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _courses = result['courses'];
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

  void _enroll(String classId) async {
    final result = await _courseService.enrollCourse(classId);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment request submitted successfully!')),
        );
        _fetchAvailableCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  String _getImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.isEmpty) return "";
    imgPath = imgPath.replaceAll('\\\\', '/').replaceAll('\\', '/');
    if (imgPath.startsWith('http')) return imgPath;
    String base = Config_URL.baseUrl.split('/api')[0];
    if (imgPath.startsWith('images/') || imgPath.startsWith('uploads/')) return "$base/$imgPath";
    return "$base/images/$imgPath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAvailableCourses,
              child: _courses.isEmpty
                  ? const Center(child: Text('No courses available for enrollment'))
                  : ListView.builder(
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        final String imgUrl = _getImageUrl(course['image_path']);

                        return Card(
                          margin: const EdgeInsets.all(12),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imgUrl.isNotEmpty
                                  ? Image.network(
                                      imgUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 180,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, size: 64),
                                      ),
                                    )
                                  : Container(
                                      height: 180,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 64),
                                    ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['course_name'] ?? '',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Class: ${course['class_name'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course['description'] ?? '',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Fee: ${course['tuition_fee'] ?? 'Free'}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _enroll(course['id'].toString()),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Enroll Now'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
