import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ExamService.dart';

class TakeExamScreen extends StatefulWidget {
  final String assignmentId;
  const TakeExamScreen({super.key, required this.assignmentId});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> {
  final ExamService _examService = ExamService();
  Map<String, dynamic>? _exam;
  List<dynamic> _questions = [];
  String? _attemptId;
  Map<String, dynamic> _responses = {};
  Map<String, List<File>> _uploadedFiles = {};
  
  bool _isLoading = true;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExamData() async {
    final result = await _examService.getTakeExamData(widget.assignmentId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _exam = result['exam'];
          _questions = result['questions'];
          _attemptId = result['attemptId'].toString();
          _secondsRemaining = (result['duration'] as int) * 60;
          
          if (result['responses'] != null) {
            final existingResponses = result['responses'] as Map<String, dynamic>;
            existingResponses.forEach((qId, resp) {
              if (resp['essay_text'] != null && resp['essay_text'].toString().isNotEmpty) {
                _responses[qId] = resp['essay_text'];
              } else if (resp['chosen_options'] != null && (resp['chosen_options'] as List).isNotEmpty) {
                _responses[qId] = resp['chosen_options'][0]['option_id'];
              }
            });
          }
          
          _isLoading = false;
        });
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitExam(isAutoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _pickFiles(String questionId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _uploadedFiles[questionId] = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> _submitExam({bool isAutoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!isAutoSubmit) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Exam'),
          content: const Text('Are you sure you want to submit this exam? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });
    _timer?.cancel();

    Map<String, dynamic> submissionData = {};
    List<File> allFiles = [];

    for (var q in _questions) {
      String qId = q['question_id'].toString();
      if (q['type_code'] == 'MCQ') {
        submissionData[qId] = {'selectedOptionId': _responses[qId]};
      } else if (q['type_code'] == 'ESSAY') {
        submissionData[qId] = {'text': _responses[qId] ?? ''};
        if (_uploadedFiles[qId] != null) {
          allFiles.addAll(_uploadedFiles[qId]!);
        }
      }
    }

    final result = await _examService.submitExam(_attemptId!, submissionData, allFiles);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Exam Submitted'),
            content: Text(result['message']),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        _startTimer();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text('Leaving now will automatically submit your current progress. Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Leave & Submit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      await _submitExam(isAutoSubmit: true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isSubmitting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_exam?['exam_title'] ?? 'Exam', style: const TextStyle(fontSize: 16)),
              Text('Code: ${_exam?['exam_code'] ?? ''}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        body: _isSubmitting 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting your exam...'),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Card(
                    color: Color(0xFFFFFBEB),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Do not refresh or close the page. Your progress is automatically saved.',
                              style: TextStyle(color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    final String qId = question['question_id'].toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                                  child: Text('${question['points']} points', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(question['body_text'], style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 16),
                                if (question['type_code'] == 'MCQ' || question['type_name'] == 'Câu hỏi trắc nghiệm')
                                  ...((question['options'] as List).asMap().entries.map((optEntry) {
                                    final optIdx = optEntry.key;
                                    final opt = optEntry.value;
                                    final label = opt['display_label'] ?? String.fromCharCode(65 + optIdx);
                                    final text = opt['option_text_snapshot'] ?? opt['option_text'] ?? '';
                                    
                                    return RadioListTile<int>(
                                      title: Text("$label. $text"),
                                      value: opt['option_id'],
                                      groupValue: _responses[qId],
                                      onChanged: (val) => setState(() => _responses[qId] = val),
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: Colors.blue,
                                    );
                                  }))
                                else if (question['type_code'] == 'ESSAY')
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        maxLines: 6,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          hintText: 'Enter your answer here...',
                                        ),
                                        onChanged: (val) => _responses[qId] = val,
                                        controller: TextEditingController.fromValue(
                                          TextEditingValue(
                                            text: _responses[qId] ?? '',
                                            selection: TextSelection.collapsed(offset: (_responses[qId] ?? '').length),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _submitExam(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit Exam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      ),
    );
  }
}
