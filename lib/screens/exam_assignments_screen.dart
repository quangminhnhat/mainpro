import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ExamService.dart';
import '../services/ClassService.dart';
import 'exam_scores_screen.dart';

class ExamAssignmentsScreen extends StatefulWidget {
  final String examId;
  const ExamAssignmentsScreen({super.key, required this.examId});

  @override
  State<ExamAssignmentsScreen> createState() => _ExamAssignmentsScreenState();
}

class _ExamAssignmentsScreenState extends State<ExamAssignmentsScreen> {
  final ExamService _examService = ExamService();
  final ClassService _classService = ClassService();
  
  Map<String, dynamic>? _exam;
  List<dynamic> _assignments = [];
  List<dynamic> _availableClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final dio = _examService.client;
    try {
      final response = await dio.get("/exams/${widget.examId}/assign");
      if (response.statusCode == 200) {
        setState(() {
          _exam = response.data['exam'];
          _assignments = response.data['assignments'];
          _availableClasses = response.data['availableClasses'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAssignModal() {
    String? selectedClassId;
    DateTime openDate = DateTime.now();
    DateTime closeDate = DateTime.now().add(const Duration(days: 7));
    final TextEditingController maxAttemptsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assign Exam to Class', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
                items: _availableClasses.map((c) => DropdownMenuItem<String>(
                  value: c['id'].toString(),
                  child: Text(c['class_name']),
                )).toList(),
                onChanged: (v) => selectedClassId = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Open At'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(openDate)),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: openDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(openDate));
                          if (t != null) setModalState(() => openDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Close At'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(closeDate)),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: closeDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(closeDate));
                          if (t != null) setModalState(() => closeDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxAttemptsController,
                decoration: const InputDecoration(labelText: 'Max Attempts (empty for unlimited)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (selectedClassId == null) return;
                  final dio = _examService.client;
                  await dio.post("/exams/${widget.examId}/assign", data: {
                    "class_id": selectedClassId,
                    "open_at": openDate.toIso8601String(),
                    "close_at": closeDate.toIso8601String(),
                    "max_attempts": maxAttemptsController.text.isNotEmpty ? int.parse(maxAttemptsController.text) : null
                  });
                  Navigator.pop(context);
                  _fetchData();
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Assign'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAssignment(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: const Text('Are you sure? Students will no longer have access to this exam.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final dio = _examService.client;
      try {
        final response = await dio.delete("/exams/assignments/$assignmentId");
        if (response.statusCode == 200) {
          _fetchData();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_exam?['exam_title'] ?? 'Assignments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAssignModal,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final a = _assignments[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(a['class_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Open: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(a['open_at']))}\nClose: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(a['close_at']))}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAssignment(a['assignment_id'].toString()),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamScoresScreen(assignmentId: a['assignment_id'].toString()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
