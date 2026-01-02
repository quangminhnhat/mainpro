import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/EnrollmentService.dart';
import 'add_edit_enrollment_screen.dart';

class EnrollmentListScreen extends StatefulWidget {
  const EnrollmentListScreen({super.key});

  @override
  State<EnrollmentListScreen> createState() => _EnrollmentListScreenState();
}

class _EnrollmentListScreenState extends State<EnrollmentListScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<dynamic> _enrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEnrollments();
  }

  Future<void> _fetchEnrollments() async {
    setState(() => _isLoading = true);
    final result = await _enrollmentService.getEnrollments();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _enrollments = result['enrollments'];
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

  void _togglePayment(String id) async {
    final result = await _enrollmentService.togglePaymentStatus(id);
    if (mounted) {
      if (result['success']) {
        _fetchEnrollments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _deleteEnrollment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Enrollment'),
        content: const Text('Are you sure you want to delete this enrollment?'),
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
      final result = await _enrollmentService.deleteEnrollment(id);
      if (mounted) {
        if (result['success']) {
          _fetchEnrollments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enrollment deleted')),
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
        title: const Text('Enrollments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditEnrollmentScreen()),
              );
              if (result == true) _fetchEnrollments();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEnrollments,
              child: _enrollments.isEmpty
                  ? const Center(child: Text('No enrollments found'))
                  : ListView.builder(
                      itemCount: _enrollments.length,
                      itemBuilder: (context, index) {
                        final enrollment = _enrollments[index];
                        final bool isPaid = enrollment['payment_status'] == 1 || enrollment['payment_status'] == true;
                        final String enrollmentDate = enrollment['enrollment_date'] != null 
                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(enrollment['enrollment_date']))
                            : 'N/A';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(enrollment['student_name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Class: ${enrollment['class_name']}'),
                                Text('Fee: ${enrollment['tuition_fee']} VND'),
                                Text('Date: $enrollmentDate'),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                ActionChip(
                                  label: Text(isPaid ? 'Paid' : 'Unpaid', style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  backgroundColor: isPaid ? Colors.green : Colors.orange,
                                  onPressed: () => _togglePayment(enrollment['id'].toString()),
                                ),
                                PopupMenuButton(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditEnrollmentScreen(enrollmentId: enrollment['id'].toString()),
                                        ),
                                      );
                                      if (result == true) _fetchEnrollments();
                                    } else if (value == 'delete') {
                                      _deleteEnrollment(enrollment['id'].toString());
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
}
