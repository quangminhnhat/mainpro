import 'package:dio/dio.dart';
import 'AuthService.dart';
import 'dart:io';

class MaterialService {
  final Dio _dio = AuthService.client;

  Future<List<dynamic>> getMaterials() async {
    try {
      final response = await _dio.get("/materials");
      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getMaterialEditData(String id) async {
    try {
      final response = await _dio.get("/materials/$id/edit");
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> deleteMaterial(String id) async {
    try {
      final response = await _dio.delete("/materials/$id");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUploadFormData() async {
    try {
      final response = await _dio.get("/upload");
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> uploadMaterial(String courseId, File file) async {
    try {
      FormData formData = FormData.fromMap({
        "course_id": courseId,
        "material": await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      // Corrected route to match server's /api/upload-material
      final response = await _dio.post("/upload-material", data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  Future<bool> updateMaterial(String id, String courseId, File? file) async {
    try {
      Map<String, dynamic> map = {"course_id": courseId};
      if (file != null) {
        map["material"] = await MultipartFile.fromFile(file.path, filename: file.path.split('/').last);
      }
      FormData formData = FormData.fromMap(map);
      final response = await _dio.post("/materials/$id", data: formData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
