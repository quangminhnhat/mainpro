import 'package:flutter/material.dart';
import '../services/ClassService.dart';
import 'add_edit_class_screen.dart';
import 'class_students_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final ClassService _classService = ClassService();
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    final result = await _classService.getClasses();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _classes = result['classes'];
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

  void _deleteClass(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class?'),
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
      final result = await _classService.deleteClass(id);
      if (mounted) {
        if (result['success']) {
          _fetchClasses();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class deleted successfully')),
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
        title: const Text('Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditClassScreen()),
              );
              if (result == true) _fetchClasses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchClasses,
              child: _classes.isEmpty
                  ? const Center(child: Text('No classes found'))
                  : ListView.builder(
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        final cls = _classes[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(cls['class_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Course: ${cls['course_name']}'),
                                Text('Teacher: ${cls['teacher_name']}'),
                                Text('Schedule: ${cls['scheduleDisplay']}'),
                                Text('Time: ${cls['formatted_start_time']} - ${cls['formatted_end_time']}'),
                                Text('Students: ${cls['student_count']}'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditClassScreen(classId: cls['id'].toString()),
                                    ),
                                  );
                                  if (result == true) _fetchClasses();
                                } else if (value == 'delete') {
                                  _deleteClass(cls['id'].toString());
                                } else if (value == 'students') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClassStudentsScreen(classId: cls['id'].toString()),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'students', child: Text('View Students')),
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
