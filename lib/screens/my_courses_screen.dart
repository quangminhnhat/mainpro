import 'package:flutter/material.dart';
import '../services/CourseService.dart';
import '../config/config_url.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final CourseService _courseService = CourseService();
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyCourses();
  }

  Future<void> _fetchMyCourses() async {
    setState(() => _isLoading = true);
    final result = await _courseService.getMyCourses();
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

  String _getImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.isEmpty) return "";
    imgPath = imgPath.replaceAll('\\\\', '/').replaceAll('\\', '/');
    if (imgPath.startsWith('http')) return imgPath;
    
    String base = Config_URL.baseUrl.split('/api')[0];
    if (imgPath.startsWith('images/') || imgPath.startsWith('uploads/')) {
      return "$base/$imgPath";
    }
    return "$base/images/$imgPath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMyCourses,
              child: _courses.isEmpty
                  ? const Center(child: Text('You are not enrolled in any courses'))
                  : ListView.builder(
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        final String imageUrl = _getImageUrl(course['image_path']);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade100,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                                    )
                                  : const Icon(Icons.book, color: Colors.blue),
                            ),
                            title: Text(course['course_name'] ?? 'Unknown Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Class: ${course['class_name'] ?? 'N/A'}'),
                                Text('Schedule: ${course['schedule'] ?? 'N/A'}'),
                                Text('Time: ${course['class_start_time'] ?? ''} - ${course['class_end_time'] ?? ''}'),
                                if (course['payment_status'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      (course['payment_status'] == 1 || course['payment_status'] == true) ? 'Paid' : 'Unpaid',
                                      style: TextStyle(
                                        color: (course['payment_status'] == 1 || course['payment_status'] == true) ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
