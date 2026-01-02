import 'package:flutter/material.dart';
import '../services/ClassService.dart';

class AddEditClassScreen extends StatefulWidget {
  final String? classId;
  const AddEditClassScreen({super.key, this.classId});

  @override
  State<AddEditClassScreen> createState() => _AddEditClassScreenState();
}

class _AddEditClassScreenState extends State<AddEditClassScreen> {
  final ClassService _classService = ClassService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  List<dynamic> _courses = [];
  List<dynamic> _teachers = [];
  String? _selectedCourseId;
  String? _selectedTeacherId;
  List<String> _selectedDays = [];
  bool _isLoading = true;

  final List<Map<String, String>> _daysOfWeek = [
    {'id': '1', 'name': 'Mon'},
    {'id': '2', 'name': 'Tue'},
    {'id': '3', 'name': 'Wed'},
    {'id': '4', 'name': 'Thu'},
    {'id': '5', 'name': 'Fri'},
    {'id': '6', 'name': 'Sat'},
    {'id': '7', 'name': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _classService.getClassFormData(id: widget.classId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _courses = result['courses'];
          _teachers = result['teachers'];
          if (widget.classId != null && result['classItem'] != null) {
            final item = result['classItem'];
            _nameController.text = item['class_name'] ?? '';
            _startTimeController.text = item['formatted_start_time'] ?? '';
            _endTimeController.text = item['formatted_end_time'] ?? '';
            _selectedCourseId = item['course_id'].toString();
            _selectedTeacherId = item['teacher_id'].toString();
            if (item['weekly_schedule'] != null) {
              _selectedDays = item['weekly_schedule'].toString().split(',');
            }
          }
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourseId == null || _selectedTeacherId == null || _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields and select at least one day')),
        );
        return;
      }

      final data = {
        'class_name': _nameController.text,
        'course_id': _selectedCourseId,
        'teacher_id': _selectedTeacherId,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'weekly_days': _selectedDays,
      };

      setState(() => _isLoading = true);
      final result = widget.classId == null
          ? await _classService.createClass(data)
          : await _classService.updateClass(widget.classId!, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(widget.classId == null ? 'Add Class' : 'Edit Class')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Class Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(labelText: 'Course'),
                      items: _courses.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['course_name'] ?? c['name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTeacherId,
                      decoration: const InputDecoration(labelText: 'Teacher'),
                      items: _teachers.map((t) => DropdownMenuItem<String>(
                        value: t['id'].toString(),
                        child: Text(t['full_name'] ?? t['name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedTeacherId = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: const InputDecoration(labelText: 'Start Time'),
                            readOnly: true,
                            onTap: () => _selectTime(_startTimeController),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: const InputDecoration(labelText: 'End Time'),
                            readOnly: true,
                            onTap: () => _selectTime(_endTimeController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Weekly Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: _daysOfWeek.map((day) {
                        final isSelected = _selectedDays.contains(day['id']);
                        return FilterChip(
                          label: Text(day['name']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day['id']!);
                              } else {
                                _selectedDays.remove(day['id']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Save Class'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
