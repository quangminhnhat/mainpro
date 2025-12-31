import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/AuthService.dart';
import '../services/NotificationService.dart';
import '../config/config_url.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  
  List<dynamic> _allEvents = [];
  bool _isLoadingEvents = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchMyEvents();
    _fetchUserProfile(); 
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchMyEvents();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      setState(() {
        _userData = jsonDecode(userStr);
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final dio = AuthService.client;
      final response = await dio.get("/profile");
      if (response.statusCode == 200) {
        final details = response.data['details'];
        if (mounted) {
          setState(() {
            _userData = details;
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(details));
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchMyEvents() async {
    try {
      final dio = AuthService.client;
      final response = await dio.get("/my-events");
      
      if (response.statusCode == 200) {
        final events = response.data['events'] ?? [];
        if (mounted) {
          setState(() {
            _allEvents = events;
            _isLoadingEvents = false;
          });
        }
        
        NotificationService.showDailySummaryNotification(events);
        _scheduleReminders(events);
      }
    } catch (e) {
      print("Error fetching events: $e");
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  void _scheduleReminders(List<dynamic> events) async {
    await NotificationService.cancelAll();
    
    for (var event in events) {
      if (event['reminder_id'] != null && event['remind_at'] != null) {
        DateTime remindTime = DateTime.parse(event['remind_at']);
        String startTimeFormatted = DateFormat('HH:mm').format(DateTime.parse(event['start_time']));

        await NotificationService.scheduleEventReminders(
          reminderId: event['reminder_id'],
          title: event['title'] ?? 'Sự kiện',
          startTime: startTimeFormatted,
          remindAt: remindTime,
        );
      }
    }
  }

  void _logout() async {
    await _authService.logout();
    await NotificationService.cancelAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? serverPic = _userData?['profile_pic'];
    String? imageUrl;
    if (serverPic != null && serverPic.isNotEmpty) {
      String base = Config_URL.baseUrl.replaceAll('/api/', '');
      imageUrl = "$base/$serverPic";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả sự kiện'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyEvents,
          ),
          if (_userData != null)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                _fetchUserProfile(); 
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          (_userData?['full_name']?[0] ?? 'U').toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                _fetchUserProfile(); 
              },
              child: UserAccountsDrawerHeader(
                accountName: Text(_userData?['full_name'] ?? 'Người dùng'),
                accountEmail: Text(_userData?['email'] ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          (_userData?['full_name']?[0] ?? 'U').toUpperCase(),
                          style: const TextStyle(fontSize: 40.0),
                        )
                      : null,
                ),
                decoration: const BoxDecoration(color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chủ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ sơ cá nhân'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                _fetchUserProfile(); 
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoadingEvents 
        ? const Center(child: CircularProgressIndicator())
        : _allEvents.isEmpty
          ? const Center(child: Text("Không có sự kiện nào"))
          : ListView.builder(
              itemCount: _allEvents.length,
              itemBuilder: (context, index) {
                final event = _allEvents[index];
                final hasReminder = event['reminder_id'] != null;
                
                final start = event['start_time'] != null ? DateTime.parse(event['start_time']) : DateTime.now();
                final end = event['end_time'] != null ? DateTime.parse(event['end_time']) : DateTime.now();
                final dateRange = "${DateFormat('dd/MM HH:mm').format(start)} - ${DateFormat('dd/MM HH:mm').format(end)}";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hexToColor(event['color'] ?? '#039be5'),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(event['title'] ?? 'Không có tiêu đề', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['description'] ?? ''),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateRange,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasReminder && event['remind_at'] != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.alarm, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm').format(DateTime.parse(event['remind_at'])),
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
