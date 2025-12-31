import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import 'dart:io';

class AuthService {
  static final Dio _dio = Dio(BaseOptions(baseUrl: Config_URL.baseUrl));
  static bool _isInitialized = false;

  AuthService() {
    _init();
  }

  // Use a singleton pattern to ensure initialization happens once
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage("$appDocPath/.cookies/"),
    );

    _dio.interceptors.add(CookieManager(cookieJar));
    _isInitialized = true;
  }

  Future<void> _init() async {
    await ensureInitialized();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await ensureInitialized();

      final response = await _dio.post(
        "/login",
        data: {
          "email": email,
          "password": password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));

        return {
          "success": true,
          "message": data['message'] ?? "Login successful",
          "user": userData,
        };
      } else {
        return {
          "success": false,
          "message": response.data['error'] ?? "Failed to login"
        };
      }
    } on DioException catch (e) {
      String message = "Network error";
      if (e.response != null && e.response?.data is Map) {
        message = e.response?.data['error'] ?? message;
      }
      return {"success": false, "message": message};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await ensureInitialized();
      final response = await _dio.delete("/logout");

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_data');
        return {"success": true, "message": "Logged out successfully"};
      }
      return {"success": false, "message": "Logout failed"};
    } on DioException catch (e) {
      return {"success": false, "message": e.message};
    }
  }

  static Dio get client {
    // Ensure we have the base URL even if not fully initialized with cookies yet
    if (_dio.options.baseUrl.isEmpty) {
      _dio.options.baseUrl = Config_URL.baseUrl;
    }
    return _dio;
  }
}
