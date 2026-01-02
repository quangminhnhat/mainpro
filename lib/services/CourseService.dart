import 'package:dio/dio.dart';
import 'AuthService.dart';
import 'dart:io';

class CourseService {
  final Dio _dio = AuthService.client;

  Future<Map<String, dynamic>> getCourses() async {
    try {
      final response = await _dio.get("/courses");
      if (response.statusCode == 200) {
        return {"success": true, "courses": response.data['courses']};
      }
      return {"success": false, "message": "Failed to load courses"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getCourseDetail(String id) async {
    try {
      final response = await _dio.get("/courses/$id");
      if (response.statusCode == 200) {
        return {"success": true, "course": response.data['course']};
      }
      return {"success": false, "message": "Failed to load course details"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> saveCourse({
    String? id,
    required String name,
    required String description,
    required String startDate,
    required String endDate,
    required String tuitionFee,
    File? imageFile,
  }) async {
    try {
      Map<String, dynamic> data = {
        'course_name': name,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'tuition_fee': tuitionFee,
      };

      if (imageFile != null) {
        data['course_image'] = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
      }

      FormData formData = FormData.fromMap(data);

      final url = id != null ? "/courses/$id" : "/courses";
      final response = await _dio.post(url, data: formData);

      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to save course"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteCourse(String id) async {
    try {
      final response = await _dio.delete("/courses/$id");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete course"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getAvailableCourses() async {
    try {
      final response = await _dio.get("/available-courses");
      if (response.statusCode == 200) {
        return {"success": true, "courses": response.data['courses']};
      }
      return {"success": false, "message": "Failed to load available courses"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> enrollCourse(String classId) async {
    try {
      final response = await _dio.post("/enroll-course", data: {"class_id": classId});
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to enroll"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getMyCourses() async {
    try {
      final response = await _dio.get("/my-courses");
      if (response.statusCode == 200) {
        return {"success": true, "courses": response.data['courses']};
      }
      return {"success": false, "message": "Failed to load my courses"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}
