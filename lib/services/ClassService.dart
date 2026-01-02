import 'package:dio/dio.dart';
import 'AuthService.dart';

class ClassService {
  final Dio _dio = AuthService.client;

  Future<Map<String, dynamic>> getClasses() async {
    try {
      final response = await _dio.get("/classes");
      if (response.statusCode == 200) {
        return {"success": true, "classes": response.data['classes']};
      }
      return {"success": false, "message": "Failed to load classes"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getClassFormData({String? id}) async {
    try {
      final url = id != null ? "/classes/$id/edit" : "/classes/new";
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "courses": response.data['courses'],
          "teachers": response.data['teachers'],
          "classItem": response.data['classItem'],
        };
      }
      return {"success": false, "message": "Failed to load form data"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> createClass(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/classes", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to create class"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateClass(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/classes/$id", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update class"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteClass(String id) async {
    try {
      final response = await _dio.delete("/classes/$id");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete class"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getClassStudents(String id) async {
    try {
      final response = await _dio.get("/classes/$id/students");
      if (response.statusCode == 200) {
        return {
          "success": true,
          "classInfo": response.data['classInfo'],
          "students": response.data['students']
        };
      }
      return {"success": false, "message": "Failed to load students"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}
