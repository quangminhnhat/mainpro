import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/AuthService.dart';

class AddEditQuestionScreen extends StatefulWidget {
  final String examId;
  final String? questionId;
  const AddEditQuestionScreen({super.key, required this.examId, this.questionId});

  @override
  State<AddEditQuestionScreen> createState() => _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends State<AddEditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(text: '1');
  String _selectedType = '1'; // 1: MCQ, 2: Essay
  String? _selectedDifficulty;
  
  List<Map<String, dynamic>> _mcqOptions = [
    {'text': '', 'isCorrect': false, 'explanation': ''},
    {'text': '', 'isCorrect': false, 'explanation': ''},
  ];

  List<File> _mediaFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.questionId != null) {
      _loadQuestionData();
    }
  }

  Future<void> _loadQuestionData() async {
    setState(() => _isLoading = true);
    final dio = AuthService.client;
    try {
      final response = await dio.get("/questions/${widget.questionId}/edit");
      if (response.statusCode == 200) {
        final q = response.data['question'];
        setState(() {
          _textController.text = q['body_text'] ?? '';
          _pointsController.text = q['points']?.toString() ?? '1';
          _selectedType = q['type_id']?.toString() ?? '1';
          _selectedDifficulty = q['difficulty']?.toString();
          
          if (q['options'] != null) {
            final options = q['options'] as List;
            _mcqOptions = options.map((o) => {
              'text': o['option_text'] ?? '',
              'isCorrect': o['is_correct'] == 1 || o['is_correct'] == true,
              'explanation': o['explanation'] ?? '',
              'id': o['option_id']
            }).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _addOption() {
    if (_mcqOptions.length < 10) {
      setState(() {
        _mcqOptions.add({'text': '', 'isCorrect': false, 'explanation': ''});
      });
    }
  }

  void _removeOption(int index) {
    if (_mcqOptions.length > 2) {
      setState(() {
        _mcqOptions.removeAt(index);
      });
    }
  }

  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _mediaFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == '1') {
        if (!_mcqOptions.any((o) => o['isCorrect'])) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one correct option')));
          return;
        }
      }

      setState(() => _isLoading = true);
      
      final formData = FormData();
      formData.fields.add(MapEntry('question_text', _textController.text));
      formData.fields.add(MapEntry('points', _pointsController.text));
      formData.fields.add(MapEntry('type_id', _selectedType));
      if (_selectedDifficulty != null) formData.fields.add(MapEntry('difficulty', _selectedDifficulty!));

      if (_selectedType == '1') {
        formData.fields.add(MapEntry('options', jsonEncode(_mcqOptions)));
      }

      for (var file in _mediaFiles) {
        formData.files.add(MapEntry(
          'media',
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }

      final dio = AuthService.client;
      try {
        final url = widget.questionId != null 
            ? "/questions/${widget.questionId}" 
            : "/${widget.examId}/questions/add";
        
        final response = widget.questionId != null 
            ? await dio.put(url, data: formData)
            : await dio.post(url, data: formData);

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.questionId == null ? 'Add Question' : 'Edit Question')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Question Type*', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Multiple Choice')),
                        DropdownMenuItem(value: '2', child: Text('Essay')),
                      ],
                      onChanged: widget.questionId != null ? null : (v) => setState(() => _selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _textController,
                      decoration: const InputDecoration(labelText: 'Question Text*', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pointsController,
                            decoration: const InputDecoration(labelText: 'Points*', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDifficulty,
                            decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: '1', child: Text('Easy')),
                              DropdownMenuItem(value: '2', child: Text('Medium')),
                              DropdownMenuItem(value: '3', child: Text('Hard')),
                            ],
                            onChanged: (v) => setState(() => _selectedDifficulty = v),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedType == '1') ...[
                      const SizedBox(height: 24),
                      const Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._mcqOptions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final opt = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(child: Text(String.fromCharCode(65 + i))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: opt['text'],
                                        decoration: InputDecoration(hintText: 'Option ${String.fromCharCode(65 + i)} Text'),
                                        onChanged: (v) => opt['text'] = v,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeOption(i),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: opt['isCorrect'],
                                      onChanged: (v) {
                                        setState(() {
                                          for (var o in _mcqOptions) {
                                            o['isCorrect'] = false;
                                          }
                                          opt['isCorrect'] = v;
                                        });
                                      },
                                    ),
                                    const Text('Correct Answer'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text('Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Media Files'),
                    ),
                    ..._mediaFiles.map((f) => ListTile(
                      leading: const Icon(Icons.file_present),
                      title: Text(f.path.split('/').last),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _mediaFiles.remove(f))),
                    )),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
