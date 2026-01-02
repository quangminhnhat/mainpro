import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ExamService.dart';
import 'take_exam_screen.dart';
import 'add_edit_exam_screen.dart';
import 'exam_assignments_screen.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final ExamService _examService = ExamService();
  List<dynamic> _exams = [];
  bool _isLoading = true;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchExams();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        _userRole = userData['role']?.toString().toLowerCase() ?? 'student';
      });
    }
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    final result = await _examService.getExams();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _exams = result['exams'];
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  void _deleteExam(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text('Are you sure you want to delete this exam?'),
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
      final result = await _examService.deleteExam(id);
      if (mounted) {
        if (result['success']) {
          _fetchExams();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam deleted')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'admin';
    final bool isTeacher = _userRole == 'teacher';
    final bool isStudent = _userRole == 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam List'),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditExamScreen()),
                );
                if (result == true) _fetchExams();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExams,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchExams,
              child: _exams.isEmpty
                  ? const Center(child: Text('No exams found'))
                  : ListView.builder(
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        final String status = exam['exam_status'] ?? 'Available';
                        final String code = exam['exam_code'] ?? 'N/A';
                        final int attemptCount = exam['attempt_count'] ?? 0;
                        final int? maxAttempts = exam['max_attempts'];
                        
                        String attemptsText = 'Unlimited';
                        if (maxAttempts != null) {
                          int remaining = (maxAttempts - attemptCount).clamp(0, maxAttempts);
                          attemptsText = '$remaining / $maxAttempts';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exam['exam_title'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ),
                                    if (isStudent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.qr_code, 'Code', code),
                                _buildInfoRow(Icons.person, 'Teacher', exam['teacher_name'] ?? 'N/A'),
                                _buildInfoRow(Icons.timer, 'Duration', '${exam['duration_min']} min'),
                                
                                if (isStudent) ...[
                                  const Divider(),
                                  _buildInfoRow(Icons.login, 'Open', _formatDateTime(exam['open_at'])),
                                  _buildInfoRow(Icons.logout, 'Close', _formatDateTime(exam['close_at'])),
                                  _buildInfoRow(Icons.star, 'Score', 
                                    (exam['total_score'] != null) ? '${exam['total_score']} / ${exam['total_points']}' : 'N/A'),
                                  _buildInfoRow(Icons.history, 'Attempts', attemptsText),
                                ],

                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isStudent && status == 'Available')
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TakeExamScreen(assignmentId: exam['assignment_id'].toString()),
                                            ),
                                          );
                                          if (result == true) _fetchExams();
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    
                                    if (isTeacher) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddEditExamScreen(examId: exam['exam_id'].toString()),
                                            ),
                                          );
                                          if (result == true) _fetchExams();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.group, color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ExamAssignmentsScreen(examId: exam['exam_id'].toString()),
                                            ),
                                          );
                                        },
                                      ),
                                    ],

                                    if (isAdmin || isTeacher)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteExam(exam['exam_id'].toString()),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Completed': return Colors.grey;
      case 'In Progress': return Colors.orange;
      case 'Expired': return Colors.red;
      case 'Upcoming': return Colors.blue;
      default: return Colors.black;
    }
  }
}
