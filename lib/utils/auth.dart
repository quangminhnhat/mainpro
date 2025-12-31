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
    required String subject, // 'subject1' = user, 'subject2' = manager, 'subject3' = admin
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

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Đăng ký thành công'
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Đăng ký thất bại'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    }
  }
}
