import 'package:dio/dio.dart';
import 'AuthService.dart';

class EnrollmentService {
  final Dio _dio = AuthService.client;

  Future<Map<String, dynamic>> getEnrollments() async {
    try {
      final response = await _dio.get("/enrollments");
      if (response.statusCode == 200) {
        return {"success": true, "enrollments": response.data['enrollments']};
      }
      return {"success": false, "message": "Failed to load enrollments"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getEnrollmentFormData({String? id}) async {
    try {
      final url = id != null ? "/enrollments/$id/edit" : "/enrollments/new";
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "students": response.data['students'],
          "classes": response.data['classes'],
          "enrollment": response.data['enrollment'],
        };
      }
      return {"success": false, "message": "Failed to load form data"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> createEnrollment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/enrollments", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to create enrollment"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateEnrollment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put("/enrollments/$id", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update enrollment"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> togglePaymentStatus(String id) async {
    try {
      final response = await _dio.post("/enrollments/$id/toggle-payment");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to toggle payment status"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteEnrollment(String id) async {
    try {
      final response = await _dio.delete("/enrollments/$id");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete enrollment"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}
