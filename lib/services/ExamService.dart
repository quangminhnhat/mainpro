import 'package:dio/dio.dart';
import 'AuthService.dart';
import 'dart:convert';
import 'dart:io';

class ExamService {
  final Dio _dio = AuthService.client;

  Dio get client => _dio;

  Future<Map<String, dynamic>> getExams() async {
    try {
      final response = await _dio.get("/exams");
      if (response.statusCode == 200) {
        return {"success": true, "exams": response.data['exams']};
      }
      return {"success": false, "message": "Failed to load exams"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/exam/new", data: data);
      if (response.statusCode == 201) {
        return {"success": true, "examId": response.data['examId']};
      }
      return {"success": false, "message": "Failed to create exam"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['message'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateExam(String examId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put("/exams/$examId", data: data);
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update exam"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['message'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> deleteExam(String examId) async {
    try {
      final response = await _dio.delete("/exams/$examId");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to delete exam"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['message'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getExamDetail(String examId) async {
    try {
      final response = await _dio.get("/exams/$examId/edit");
      if (response.statusCode == 200) {
        return {
          "success": true,
          "exam": response.data['exam'],
          "questions": response.data['questions']
        };
      }
      return {"success": false, "message": "Failed to load exam details"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> getTakeExamData(String assignmentId) async {
    try {
      final response = await _dio.get("/exams/$assignmentId/take");
      if (response.statusCode == 200) {
        return {
          "success": true,
          "exam": response.data['exam'],
          "questions": response.data['questions'],
          "attemptId": response.data['attemptId'],
          "responses": response.data['responses'],
          "duration": response.data['duration']
        };
      }
      return {"success": false, "message": "Failed to start exam"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> submitExam(String attemptId, Map<String, dynamic> responses, List<File> files) async {
    try {
      FormData formData = FormData.fromMap({
        "responses": jsonEncode(responses),
        "isAutoSubmit": "false",
      });

      for (var file in files) {
        formData.files.add(MapEntry(
          "files", // The server expects 'files' or specific field names
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }

      final response = await _dio.post("/exams/submit/$attemptId", data: formData);
      if (response.statusCode == 200) {
        return {"success": true, "message": response.data['message'], "score": response.data['score']};
      }
      return {"success": false, "message": "Failed to submit exam"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['message'] ?? e.message};
    }
  }
}
