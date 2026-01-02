import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ClassService.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String classId;
  const ClassStudentsScreen({super.key, required this.classId});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final ClassService _classService = ClassService();
  Map<String, dynamic>? _classInfo;
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final result = await _classService.getClassStudents(widget.classId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _classInfo = result['classInfo'];
          _students = result['students'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load students')),
        );
      }
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return dateStr.toString();
    }
  }

  bool _isPaid(dynamic status) {
    if (status == null) return false;
    if (status is bool) return status;
    if (status is num) return status == 1;
    if (status is String) {
      return status.toLowerCase() == 'paid' || status == '1' || status.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_classInfo?['class_name'] ?? 'Class Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_classInfo != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course: ${_classInfo!['course_name'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text('Teacher: ${_classInfo!['teacher_name'] ?? 'N/A'}'),
                        Text('Total Students: ${_students.length}'),
                      ],
                    ),
                  ),
                Expanded(
                  child: _students.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No students enrolled in this class', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final enrollmentDate = _formatDate(student['enrollment_date']);
                            final paid = _isPaid(student['payment_status']);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text((student['full_name']?[0] ?? 'S').toUpperCase()),
                                ),
                                title: Text(student['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (student['email'] != null) Text(student['email']),
                                    if (student['phone_number'] != null) Text('Phone: ${student['phone_number']}'),
                                    Text('Enrolled: $enrollmentDate'),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(
                                    paid ? 'Paid' : 'Unpaid',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: paid ? Colors.green.shade900 : Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: paid ? Colors.green.shade100 : Colors.orange.shade100,
                                  side: BorderSide(color: paid ? Colors.green : Colors.orange),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
