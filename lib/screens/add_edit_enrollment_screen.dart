import 'package:flutter/material.dart';
import '../services/EnrollmentService.dart';

class AddEditEnrollmentScreen extends StatefulWidget {
  final String? enrollmentId;
  const AddEditEnrollmentScreen({super.key, this.enrollmentId});

  @override
  State<AddEditEnrollmentScreen> createState() => _AddEditEnrollmentScreenState();
}

class _AddEditEnrollmentScreenState extends State<AddEditEnrollmentScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _students = [];
  List<dynamic> _classes = [];
  String? _selectedStudentId;
  String? _selectedClassId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _enrollmentService.getEnrollmentFormData(id: widget.enrollmentId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _students = result['students'];
          _classes = result['classes'];
          if (widget.enrollmentId != null && result['enrollment'] != null) {
            final e = result['enrollment'];
            _selectedStudentId = e['student_id'].toString();
            _selectedClassId = e['class_id'].toString();
          }
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
      }
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudentId == null || _selectedClassId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both student and class')));
        return;
      }

      final data = {
        'student_id': _selectedStudentId,
        'class_id': _selectedClassId,
      };

      setState(() => _isLoading = true);
      final result = widget.enrollmentId == null
          ? await _enrollmentService.createEnrollment(data)
          : await _enrollmentService.updateEnrollment(widget.enrollmentId!, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.enrollmentId == null ? 'New Enrollment' : 'Edit Enrollment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Student'),
                      hint: const Text('Select Student'),
                      items: _students.map((s) => DropdownMenuItem<String>(
                        value: s['id'].toString(),
                        child: Text("${s['full_name']} (${s['email']})"),
                      )).toList(),
                      onChanged: widget.enrollmentId != null ? null : (v) => setState(() => _selectedStudentId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(labelText: 'Class'),
                      hint: const Text('Select Class'),
                      items: _classes.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text("${c['class_name']} - ${c['course_name']}"),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedClassId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Save Enrollment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
