import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'AuthService.dart';

class NotificationService {
  final Dio _dio = AuthService.client;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // API Methods
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _dio.get("/notifications");
      if (response.statusCode == 200) {
        return {
          "success": true,
          "notifications": response.data['notifications'],
          "users": response.data['users'],
        };
      }
      return {"success": false, "message": "Failed to load notifications"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> sendNotification(String userId, String message) async {
    try {
      final response = await _dio.post("/notifications", data: {
        "userId": userId,
        "message": message,
      });
      if (response.statusCode == 200) {
        return {"success": true, "message": response.data['message']};
      }
      return {"success": false, "message": "Failed to send notification"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> markAsRead(String id) async {
    try {
      final response = await _dio.post("/notifications/$id/read");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update notification"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      final response = await _dio.delete("/notifications/$id");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete notification"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  // Local Push Notification Methods
  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> showDailySummaryNotification(List<dynamic> events) async {
    if (events.isEmpty) return;

    final String title = "Lịch học hôm nay";
    final String body = "Bạn có ${events.length} sự kiện trong ngày hôm nay.";

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Summary',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> scheduleEventReminders({
    required int reminderId,
    required String title,
    required String startTime,
    required DateTime remindAt,
  }) async {
    if (remindAt.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      reminderId,
      'Sắp đến giờ học: $title',
      'Tiết học bắt đầu lúc $startTime',
      tz.TZDateTime.from(remindAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminder_channel',
          'Event Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
