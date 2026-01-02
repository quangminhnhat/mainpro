import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/MaterialService.dart';

class EditMaterialScreen extends StatefulWidget {
  final String materialId;
  const EditMaterialScreen({super.key, required this.materialId});

  @override
  State<EditMaterialScreen> createState() => _EditMaterialScreenState();
}

class _EditMaterialScreenState extends State<EditMaterialScreen> {
  final MaterialService _materialService = MaterialService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _courses = [];
  String? _selectedCourseId;
  String? _currentFileName;
  File? _newFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _materialService.getMaterialEditData(widget.materialId);
    if (mounted) {
      setState(() {
        _courses = data['courses'] ?? [];
        if (data['material'] != null) {
          _selectedCourseId = data['material']['course_id'].toString();
          _currentFileName = data['material']['file_name'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _newFile = File(result.files.single.path!);
      });
    }
  }

  void _update() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await _materialService.updateMaterial(widget.materialId, _selectedCourseId!, _newFile);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Material')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
                      items: _courses.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['course_name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Current File:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_currentFileName ?? 'Unknown'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_newFile == null ? 'Replace File (Optional)' : _newFile!.path.split('/').last),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _update,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
