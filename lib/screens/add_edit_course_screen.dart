import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/CourseService.dart';

class AddEditCourseScreen extends StatefulWidget {
  final String? courseId;
  const AddEditCourseScreen({super.key, this.courseId});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _tuitionController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null) {
      _loadCourseData();
    }
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);
    final result = await _courseService.getCourseDetail(widget.courseId!);
    if (mounted) {
      if (result['success']) {
        final course = result['course'];
        setState(() {
          _nameController.text = course['course_name'] ?? '';
          _descriptionController.text = course['description'] ?? '';
          _startDateController.text = course['formatted_start_date'] ?? '';
          _endDateController.text = course['formatted_end_date'] ?? '';
          _tuitionController.text = course['tuition_fee']?.toString() ?? '';
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

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
      } catch (e) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _courseService.saveCourse(
        id: widget.courseId,
        name: _nameController.text,
        description: _descriptionController.text,
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        tuitionFee: _tuitionController.text,
        imageFile: _imageFile,
      );

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
      appBar: AppBar(title: Text(widget.courseId == null ? 'Add Course' : 'Edit Course')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_imageFile != null)
                      Image.file(_imageFile!, height: 150)
                    else
                      const Icon(Icons.image, size: 100, color: Colors.grey),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Course Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateController,
                            decoration: const InputDecoration(labelText: 'Start Date'),
                            readOnly: true,
                            onTap: () => _selectDate(_startDateController),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            decoration: const InputDecoration(labelText: 'End Date'),
                            readOnly: true,
                            onTap: () => _selectDate(_endDateController),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tuitionController,
                      decoration: const InputDecoration(labelText: 'Tuition Fee (VND)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Save Course'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
