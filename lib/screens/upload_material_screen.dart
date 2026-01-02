import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/MaterialService.dart';

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final MaterialService _materialService = MaterialService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _courses = [];
  String? _selectedCourseId;
  File? _selectedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final data = await _materialService.getUploadFormData();
    if (mounted) {
      setState(() {
        _courses = data['courses'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _upload() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() => _isLoading = true);
      final success = await _materialService.uploadMaterial(_selectedCourseId!, _selectedFile!);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
        }
      }
    } else if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Material')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
                      items: _courses.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['course_name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null ? 'Select File' : _selectedFile!.path.split('/').last),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _upload,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Upload Material'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
