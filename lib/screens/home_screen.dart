import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';
import 'add_reminder_screen.dart';
import 'group_list_screen.dart';
import 'user_management_screen.dart';
import 'profile_screen.dart';
import 'all_schedule_with_in_group_screen.dart';
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
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  List<dynamic> _allEvents = [];
  bool _isLoadingEvents = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

  Future<void> _deleteReminder(int reminderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhắc nhở'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo nhắc nhở này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = AuthService.client;
        await dio.delete("/reminders/$reminderId");
        _fetchMyEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa nhắc nhở')));
        }
      } catch (e) {
        print("Delete error: $e");
      }
    }
  }

  void _showReminderOptions(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Sửa nhắc nhở'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReminderScreen(
                    events: _allEvents,
                    reminderToEdit: event,
                  ),
                ),
              );
              if (result == true) _fetchMyEvents();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Xóa nhắc nhở', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteReminder(event['reminder_id']);
            },
          ),
        ],
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _allEvents.where((event) {
      DateTime eventDate = DateTime.parse(event['start_time']);
      return isSameDay(eventDate, day);
    }).toList();
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
    bool isAdmin = _userData?['role'] == 'admin';
    bool isManager = _userData?['role'] == 'manager' || isAdmin;
    final selectedEvents = _getEventsForDay(_selectedDay!);

    String? serverPic = _userData?['profile_pic'];
    String? imageUrl;
    if (serverPic != null && serverPic.isNotEmpty) {
      String base = Config_URL.baseUrl.replaceAll('/api/', '');
      imageUrl = "$base/$serverPic";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sự kiện'),
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
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text("Quản lý", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Thêm sự kiện'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEventScreen()),
                );
                if (result == true) _fetchMyEvents();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_add),
              title: const Text('Thêm thông báo'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReminderScreen(events: _allEvents),
                  ),
                );
                if (result == true) _fetchMyEvents();
              },
            ),
            if (isManager) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text("Hệ thống", style: TextStyle(color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.event_note), 
                title: const Text('Lịch trình nhóm'),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllScheduleWithInGroupScreen()),
                  );
                  _fetchMyEvents();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_work),
                title: const Text('Quản lý nhóm'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GroupListScreen()),
                  );
                  if (result == true) _fetchMyEvents();
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Quản lý người dùng'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                    );
                    _fetchMyEvents();
                  },
                ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, 
            ),
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isLoadingEvents 
              ? const Center(child: CircularProgressIndicator())
              : selectedEvents.isEmpty
                ? const Center(child: Text("Không có sự kiện nào cho ngày này"))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final hasReminder = event['reminder_id'] != null;
                      
                      final start = DateTime.parse(event['start_time']);
                      final end = DateTime.parse(event['end_time']);
                      final dateRange = "${DateFormat('dd/MM HH:mm').format(start)} - ${DateFormat('dd/MM HH:mm').format(end)}";

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(event: event),
                              ),
                            );
                            if (result == true) _fetchMyEvents();
                          },
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
                                  if (hasReminder) ...[
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
                          trailing: hasReminder 
                            ? IconButton(
                                icon: const Icon(Icons.notifications_active, color: Colors.blue),
                                onPressed: () => _showReminderOptions(event),
                              )
                            : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
          if (result == true) _fetchMyEvents();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
