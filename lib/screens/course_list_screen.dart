import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/CourseService.dart';
import '../config/config_url.dart';
import 'add_edit_course_screen.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final CourseService _courseService = CourseService();
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final result = await _courseService.getCourses();
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

  void _deleteCourse(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _courseService.deleteCourse(id);
      if (mounted) {
        if (result['success']) {
          _fetchCourses();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditCourseScreen()),
              );
              if (result == true) _fetchCourses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCourses,
              child: _courses.isEmpty
                  ? const Center(child: Text('No courses found'))
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
                            title: Text(course['course_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Classes: ${course['class_count'] ?? 0} | Materials: ${course['material_count'] ?? 0}'),
                                Text(
                                  'Teachers: ${course['teacherInfo'] ?? 'N/A'}', 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseDetailScreen(courseId: course['id'].toString()),
                                ),
                              );
                            },
                            trailing: PopupMenuButton(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditCourseScreen(courseId: course['id'].toString()),
                                    ),
                                  );
                                  if (result == true) _fetchCourses();
                                } else if (value == 'delete') {
                                  _deleteCourse(course['id'].toString());
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
