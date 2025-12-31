import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification clicked: ${response.payload}");
      },
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      // IMPORTANT: Explicitly create channels with high importance
      const AndroidNotificationChannel summaryChannel = AndroidNotificationChannel(
        'daily_summary_channel',
        'Daily Summary',
        description: 'Shows a summary of today\'s events',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'reminder_channel',
        'Reminders',
        description: 'Event reminders and alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(summaryChannel);
      await androidImplementation?.createNotificationChannel(reminderChannel);
      
      // Request permission
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print("Showing notification: $title - $body");
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary_channel',
          'Daily Summary',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> showDailySummaryNotification(List<dynamic> events) async {
    final now = DateTime.now();
    
    // Check if events are for today
    final todayEvents = events.where((event) {
      final eventDate = DateTime.parse(event['start_time']);
      return eventDate.year == now.year &&
             eventDate.month == now.month &&
             eventDate.day == now.day;
    }).toList();

    print("Daily Summary Check: Found ${todayEvents.length} events for today.");

    if (todayEvents.isEmpty) return;

    final String eventCount = todayEvents.length.toString();
    final String eventList = todayEvents.map((e) => e['title'] ?? 'Sự kiện').join(', ');

    await showNotification(
      id: 0, 
      title: 'Lịch trình hôm nay',
      body: 'Bạn có $eventCount sự kiện: $eventList',
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    print("Scheduling notification '$title' for $scheduledDate");

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleEventReminders({
    required int reminderId,
    required String title,
    required String startTime,
    required DateTime remindAt,
  }) async {
    final thirtyBefore = remindAt.subtract(const Duration(minutes: 30));
    await scheduleNotification(
      id: reminderId * 10 + 1,
      title: 'Sắp tới: $title',
      body: 'Còn 30 phút nữa ($startTime)',
      scheduledDate: thirtyBefore,
    );

    await scheduleNotification(
      id: reminderId * 10 + 2,
      title: 'Nhắc nhở: $title',
      body: 'Bắt đầu lúc $startTime',
      scheduledDate: remindAt,
    );

    final tenAfter = remindAt.add(const Duration(minutes: 10));
    await scheduleNotification(
      id: reminderId * 10 + 3,
      title: 'Trễ: $title',
      body: 'Đã qua lúc $startTime',
      scheduledDate: tenAfter,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
