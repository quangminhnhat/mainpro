import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/RequestService.dart';
import 'add_edit_request_screen.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final RequestService _requestService = RequestService();
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _userRole = 'student';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchRequests();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        _userRole = userData['role']?.toString().toLowerCase() ?? 'student';
        _userId = userData['id'];
      });
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final result = await _requestService.getRequests();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _requests = result['requests'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _deleteRequest(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this pending request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _requestService.deleteRequest(id);
      if (mounted && result['success']) {
        _fetchRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _toggleStatus(String id) async {
    final result = await _requestService.toggleStatus(id);
    if (mounted && result['success']) {
      _fetchRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudentOrTeacher = _userRole == 'student' || _userRole == 'teacher';
    final bool isAdminOrTeacher = _userRole == 'admin' || _userRole == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          if (isStudentOrTeacher)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditRequestScreen()),
                );
                if (result == true) _fetchRequests();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: _requests.isEmpty
                  ? const Center(child: Text('No requests found'))
                  : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final r = _requests[index];
                        final String status = r['status'] ?? 'pending';
                        final bool isPending = status == 'pending';
                        final bool isOwner = r['user_id'] == _userId;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(r['type_name'] ?? 'Request', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ),
                                    _buildStatusChip(status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(r['description'] ?? '', style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(r['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.class_, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(r['class_name'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(r['created_at'])),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    Row(
                                      children: [
                                        if (isPending && isOwner) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => AddEditRequestScreen(requestId: r['request_id'].toString())),
                                              );
                                              if (result == true) _fetchRequests();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => _deleteRequest(r['request_id'].toString()),
                                          ),
                                        ],
                                        if (isAdminOrTeacher && !isOwner)
                                          ElevatedButton(
                                            onPressed: () => _toggleStatus(r['request_id'].toString()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: status == 'approved' ? Colors.orange : Colors.green,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            child: Text(status == 'approved' ? 'Reject' : 'Approve', style: const TextStyle(fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
