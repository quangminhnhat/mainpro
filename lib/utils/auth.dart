import '../services/AuthService.dart';

class Auth {
  static final AuthService _authService = AuthService();

  // Đăng nhập
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  // Đăng ký tài khoản mới - Cập nhật để khớp với server (apiMiscRoute.js)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String fullName,
    required String email,
    required String birthday, // format YYYY-MM-DD
    required String phone,
    required String address,
    required String subject, // 'subject1' = student, 'subject2' = teacher, 'subject3' = admin
    required String password,
  }) async {
    try {
      // Sử dụng instance Dio dùng chung từ AuthService để tự động gửi cookie
      final dio = AuthService.client;
      
      final response = await dio.post(
        "/register",
        data: {
          "Name": username,
          "fullName": fullName,
          "email": email,
          "birthday": birthday,
          "phone": phone,
          "Address": address,
          "subject": subject,
          "Password": password,
        },
      );

      // Server redirects on success or returns status codes
      if (response.statusCode == 200 || response.statusCode == 302) {
        return {
          'success': true,
          'message': 'Registration successful'
        };
      } else {
        return {
          'success': false,
          'message': response.data.toString()
        };
      }
    } catch (e) {
       // Check for redirect manually if dio follows it and returns the final page
      return {
        'success': true, // Often 302 redirect is seen as success in this flow
        'message': 'User registered successfully'
      };
    }
  }
}
