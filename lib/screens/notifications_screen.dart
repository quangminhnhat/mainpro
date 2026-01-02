import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/NotificationService.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchNotifications();
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

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final result = await _notificationService.getNotifications();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _notifications = result['notifications'];
          _users = result['users'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _sendNotification() {
    String? selectedUserId;
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send Notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'To User', border: OutlineInputBorder()),
              items: _users.map((u) => DropdownMenuItem<String>(
                value: u['id'].toString(),
                child: Text("${u['full_name']} (${u['role']})"),
              )).toList(),
              onChanged: (v) => selectedUserId = v,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId == null || messageController.text.isEmpty) return;
                final res = await _notificationService.sendNotification(selectedUserId!, messageController.text);
                if (res['success']) {
                  Navigator.pop(context);
                  _fetchNotifications();
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Send'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _markAsRead(String id) async {
    final res = await _notificationService.markAsRead(id);
    if (res['success']) {
      _fetchNotifications();
    }
  }

  void _deleteNotification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _notificationService.deleteNotification(id);
      if (res['success']) _fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _userRole == 'admin' || _userRole == 'teacher';

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      floatingActionButton: canSend ? FloatingActionButton(
        onPressed: _sendNotification,
        child: const Icon(Icons.send),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? const Center(child: Text('No notifications found'))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final bool isRead = n['read'] == 1 || n['read'] == true;
                        final date = DateFormat('dd/MM HH:mm').format(DateTime.parse(n['created_at']));

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: isRead ? Colors.white : Colors.blue.shade50,
                          child: ListTile(
                            leading: Icon(
                              isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: isRead ? Colors.grey : Colors.blue,
                            ),
                            title: Text(n['message'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text('From: ${n['sender_name'] ?? 'System'}\n$date'),
                            onTap: isRead ? null : () => _markAsRead(n['id'].toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteNotification(n['id'].toString()),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
