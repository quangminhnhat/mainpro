import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ScheduleService.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String? scheduleId;
  const AddEditScheduleScreen({super.key, this.scheduleId});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _dayOfWeekController = TextEditingController();

  List<dynamic> _classes = [];
  String? _selectedClassId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _scheduleService.getScheduleFormData(id: widget.scheduleId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _classes = result['classes'] ?? [];
          if (widget.scheduleId != null && result['schedule'] != null) {
            final s = result['schedule'];
            _selectedClassId = s['class_id'].toString();
            _dateController.text = s['formatted_schedule_date'] ?? '';
            _startTimeController.text = s['formatted_start_time'] ?? '';
            _endTimeController.text = s['formatted_end_time'] ?? '';
            _dayOfWeekController.text = s['day_of_week'] ?? '';
          }
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
      }
    }
  }

  void _updateDayOfWeek(DateTime date) {
    final daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    setState(() {
      _dayOfWeekController.text = daysOfWeek[date.weekday % 7];
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _updateDayOfWeek(picked);
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
      if (_selectedClassId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
        return;
      }

      final data = {
        'class_id': _selectedClassId,
        'schedule_date': _dateController.text,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'day_of_week': _dayOfWeekController.text,
      };

      setState(() => _isLoading = true);
      final result = widget.scheduleId == null
          ? await _scheduleService.createSchedule(data)
          : await _scheduleService.updateSchedule(widget.scheduleId!, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scheduleId == null ? 'Add Schedule' : 'Edit Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(labelText: 'Class*', border: OutlineInputBorder()),
                      items: _classes.map((c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text("${c['class_name']} (${c['course_name']})"),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedClassId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Date*', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dayOfWeekController,
                      decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder(), fillColor: Color(0xFFF5F5F5), filled: true),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: const InputDecoration(labelText: 'Start Time*', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                            readOnly: true,
                            onTap: () => _selectTime(_startTimeController),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: const InputDecoration(labelText: 'End Time*', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                            readOnly: true,
                            onTap: () => _selectTime(_endTimeController),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(widget.scheduleId == null ? 'Create Schedule' : 'Save Changes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
