import 'package:dio/dio.dart';
import 'AuthService.dart';

class ScheduleService {
  final Dio _dio = AuthService.client;

  Future<Map<String, dynamic>> getSchedules() async {
    try {
      final response = await _dio.get("/schedules");
      if (response.statusCode == 200) {
        return {"success": true, "schedules": response.data['schedules']};
      }
      return {"success": false, "message": "Failed to load schedules"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getMySchedule({String? weekStart}) async {
    try {
      final response = await _dio.get("/schedule", queryParameters: weekStart != null ? {"weekStart": weekStart} : null);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "days": response.data['days'],
          "scheduleData": response.data['scheduleData'],
          "weekStart": response.data['weekStart'],
          "prevWeekStart": response.data['prevWeekStart'],
          "nextWeekStart": response.data['nextWeekStart'],
        };
      }
      return {"success": false, "message": "Failed to load schedule"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getScheduleFormData({String? id}) async {
    try {
      final url = id != null ? "/schedules/$id/edit" : "/schedules/new";
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "classes": response.data['classes'],
          "schedule": response.data['schedule'],
          "currentDate": response.data['currentDate'],
        };
      }
      return {"success": false, "message": "Failed to load form data"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/schedules", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to create schedule"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateSchedule(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/schedules/$id", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update schedule"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteSchedule(String id) async {
    try {
      final response = await _dio.delete("/schedules/$id");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete schedule"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}
