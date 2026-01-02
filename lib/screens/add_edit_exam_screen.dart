import 'package:flutter/material.dart';
import '../services/ExamService.dart';
import 'add_edit_question_screen.dart';

class AddEditExamScreen extends StatefulWidget {
  final String? examId;
  const AddEditExamScreen({super.key, this.examId});

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  final ExamService _examService = ExamService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _totalPointsController = TextEditingController();
  final TextEditingController _passingPointsController = TextEditingController();

  List<dynamic> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      _loadExamData();
    }
  }

  Future<void> _loadExamData() async {
    setState(() => _isLoading = true);
    final result = await _examService.getExamDetail(widget.examId!);
    if (mounted) {
      if (result['success']) {
        final exam = result['exam'];
        setState(() {
          _titleController.text = exam['exam_title'] ?? '';
          _descriptionController.text = exam['description'] ?? '';
          _durationController.text = exam['duration_min']?.toString() ?? '';
          _totalPointsController.text = exam['total_points']?.toString() ?? '';
          _passingPointsController.text = exam['passing_points']?.toString() ?? '';
          _questions = result['questions'] ?? [];
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
      final data = {
        'exam_title': _titleController.text,
        'description': _descriptionController.text,
        'duration_minutes': int.parse(_durationController.text),
        'total_marks': int.parse(_totalPointsController.text),
        'passing_marks': _passingPointsController.text.isNotEmpty ? int.parse(_passingPointsController.text) : null,
      };

      setState(() => _isLoading = true);
      final result = widget.examId == null
          ? await _examService.createExam(data)
          : await _examService.updateExam(widget.examId!, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          if (widget.examId == null) {
            // If new exam, return to list or show questions section?
            // Usually, after create, user stays to add questions. 
            // For now, return to list as per web logic.
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam updated successfully')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  void _deleteQuestion(String qId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final dio = _examService.client;
      try {
        final response = await dio.delete("/questions/$qId");
        if (response.statusCode == 200) {
          _loadExamData();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examId == null ? 'Create New Exam' : 'Edit Exam'),
        actions: [
          if (widget.examId != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditQuestionScreen(examId: widget.examId!)),
                );
                if (result == true) _loadExamData();
              },
              tooltip: 'Add Question',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Exam Title*', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationController,
                                decoration: const InputDecoration(labelText: 'Duration (min)*', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _totalPointsController,
                                decoration: const InputDecoration(labelText: 'Total Marks*', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passingPointsController,
                          decoration: const InputDecoration(labelText: 'Passing Marks', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(widget.examId == null ? 'Create Exam' : 'Save Changes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  if (widget.examId != null) ...[
                    const Divider(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${_questions.length} questions', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_questions.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No questions added yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final q = _questions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(q['body_text'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${q['type_name']} • ${q['points']} pts'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => AddEditQuestionScreen(examId: widget.examId!, questionId: q['question_id'].toString())),
                                      );
                                      if (result == true) _loadExamData();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteQuestion(q['question_id'].toString()),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
