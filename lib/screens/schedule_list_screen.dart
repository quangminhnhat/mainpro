import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ScheduleService.dart';
import 'add_edit_schedule_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchSchedules();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        _userRole = userData['role']?.toString().toLowerCase() ?? 'student';
      });
    }
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    final result = await _scheduleService.getSchedules();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _schedules = result['schedules'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _deleteSchedule(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _scheduleService.deleteSchedule(id);
      if (mounted && result['success']) {
        _fetchSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = _userRole == 'admin' || _userRole == 'staff';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditScheduleScreen()),
                );
                if (result == true) _fetchSchedules();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSchedules,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSchedules,
              child: _schedules.isEmpty
                  ? const Center(child: Text('No schedules found'))
                  : ListView.builder(
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final s = _schedules[index];
                        final date = s['schedule_date'] != null 
                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(s['schedule_date']))
                            : 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                width: double.infinity,
                                child: Text(
                                  s['class_name'] ?? 'Unknown Class',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    _buildInfoRow(Icons.person, 'Teacher', s['teacher_name'] ?? 'N/A'),
                                    _buildInfoRow(Icons.calendar_today, 'Date', '$date (${s['day_of_week']})'),
                                    _buildInfoRow(Icons.access_time, 'Time', '${s['formatted_start_time']} - ${s['formatted_end_time']}'),
                                    _buildInfoRow(Icons.location_on, 'Location', s['location'] ?? 'N/A'),
                                  ],
                                ),
                              ),
                              if (canManage)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => AddEditScheduleScreen(scheduleId: s['id'].toString())),
                                          );
                                          if (result == true) _fetchSchedules();
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteSchedule(s['id'].toString()),
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
