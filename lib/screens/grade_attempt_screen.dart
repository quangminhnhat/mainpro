import 'package:flutter/material.dart';
import '../services/ExamService.dart';

class GradeAttemptScreen extends StatefulWidget {
  final String attemptId;
  const GradeAttemptScreen({super.key, required this.attemptId});

  @override
  State<GradeAttemptScreen> createState() => _GradeAttemptScreenState();
}

class _GradeAttemptScreenState extends State<GradeAttemptScreen> {
  final ExamService _examService = ExamService();
  Map<String, dynamic>? _attempt;
  Map<String, dynamic>? _student;
  List<dynamic> _responses = [];
  bool _isLoading = true;

  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchGradingData();
  }

  Future<void> _fetchGradingData() async {
    setState(() => _isLoading = true);
    final dio = _examService.client;
    try {
      final response = await dio.get("/exams/attempts/${widget.attemptId}/grade");
      if (response.statusCode == 200) {
        setState(() {
          _attempt = response.data['attempt'];
          _student = response.data['student'];
          _responses = response.data['responses'];
          
          for (var r in _responses) {
            final id = r['response_id'].toString();
            _scoreControllers[id] = TextEditingController(text: r['score_awarded']?.toString() ?? '');
            _commentControllers[id] = TextEditingController(text: r['grader_comment'] ?? '');
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _saveGrades() async {
    final Map<String, String> scores = {};
    final Map<String, String> comments = {};

    _scoreControllers.forEach((id, controller) => scores[id] = controller.text);
    _commentControllers.forEach((id, controller) => comments[id] = controller.text);

    setState(() => _isLoading = true);
    final dio = _examService.client;
    try {
      final response = await dio.post("/exams/attempts/${widget.attemptId}/grade", data: {
        "scores": scores,
        "comments": comments
      });
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grade: ${_student?['full_name'] ?? ''}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exam: ${_attempt?['exam_title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreItem('Auto', _attempt?['auto_score']),
                      _buildScoreItem('Manual', _attempt?['manual_score']),
                      _buildScoreItem('Total', _attempt?['total_score']),
                    ],
                  ),
                  const Divider(height: 32),
                  ..._responses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final id = r['response_id'].toString();
                    final bool isMCQ = r['type_code'] == 'MCQ';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question ${index + 1}: ${r['body_text']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              color: Colors.grey.shade100,
                              child: isMCQ 
                                ? Text('Selected: ${r['display_label'] ?? 'N/A'}', 
                                       style: TextStyle(color: r['score_awarded'] > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold))
                                : Text(r['essay_text'] ?? 'No text submitted'),
                            ),
                            if (!isMCQ) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _scoreControllers[id],
                                decoration: const InputDecoration(labelText: 'Score', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _commentControllers[id],
                                decoration: const InputDecoration(labelText: 'Comment', border: OutlineInputBorder()),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveGrades,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Save Grades'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildScoreItem(String label, dynamic value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value?.toString() ?? '0', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }
}
