import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ExamService.dart';
import 'grade_attempt_screen.dart';

class ExamScoresScreen extends StatefulWidget {
  final String assignmentId;
  const ExamScoresScreen({super.key, required this.assignmentId});

  @override
  State<ExamScoresScreen> createState() => _ExamScoresScreenState();
}

class _ExamScoresScreenState extends State<ExamScoresScreen> {
  final ExamService _examService = ExamService();
  Map<String, dynamic>? _assignment;
  List<dynamic> _scores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    setState(() => _isLoading = true);
    final dio = _examService.client;
    try {
      final response = await dio.get("/exams/assignments/${widget.assignmentId}/scores");
      if (response.statusCode == 200) {
        setState(() {
          _assignment = response.data['assignment'];
          _scores = response.data['scores'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Scores')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_assignment != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_assignment!['exam_title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Class: ${_assignment!['class_name']}'),
                        Text('Code: ${_assignment!['exam_code']}'),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _scores.length,
                    itemBuilder: (context, index) {
                      final s = _scores[index];
                      final score = s['score'];
                      final status = s['status_text'] ?? 'Unknown';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(s['student_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Latest Attempt: ${s['attempt_no'] ?? 'N/A'}'),
                              Text('Status: $status'),
                              if (s['submitted_at'] != null)
                                Text('Submitted: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(s['submitted_at']))}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(score != null ? score.toString() : '-', 
                                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              if (s['submitted_at'] != null && s['status'] != 'graded')
                                TextButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GradeAttemptScreen(attemptId: s['attempt_id'].toString()),
                                      ),
                                    );
                                    if (result == true) _fetchScores();
                                  },
                                  child: const Text('Grade', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
