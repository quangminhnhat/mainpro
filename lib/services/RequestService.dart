import 'package:dio/dio.dart';
import 'AuthService.dart';

class RequestService {
  final Dio _dio = AuthService.client;

  Future<Map<String, dynamic>> getRequests() async {
    try {
      final response = await _dio.get("/requests");
      if (response.statusCode == 200) {
        return {"success": true, "requests": response.data['requests']};
      }
      return {"success": false, "message": "Failed to load requests"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getRequestFormData({String? requestId}) async {
    try {
      final url = requestId != null ? "/requests/$requestId/edit" : "/requests/new";
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "requestTypes": response.data['requestTypes'],
          "classes": response.data['classes'],
          "request": response.data['request'],
        };
      }
      return {"success": false, "message": "Failed to load form data"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/requestAdd", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to submit request"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateRequest(String requestId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put("/requestEdit/$requestId", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update request"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String requestId) async {
    try {
      final response = await _dio.delete("/requestDelete/$requestId");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete request"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> toggleStatus(String requestId) async {
    try {
      final response = await _dio.put("/requestToggleStatus/$requestId");
      if (response.statusCode == 200) {
        return {"success": true, "newStatus": response.data['newStatus']};
      }
      return {"success": false, "message": "Failed to update status"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}
