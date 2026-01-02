import 'package:dio/dio.dart';
import 'AuthService.dart';

class PaymentService {
  final Dio _dio = AuthService.client;

  /// Get all payments (filtered from enrollments with payment info)
  Future<Map<String, dynamic>> getPayments() async {
    try {
      final response = await _dio.get("/enrollments");
      if (response.statusCode == 200) {
        // Filter only paid enrollments and format as payments
        final enrollments = response.data['enrollments'] as List;
        final payments = enrollments
            .where((e) => e['payment_status'] == 1 || e['payment_status'] == true)
            .map((e) => {
              'id': e['id'],
              'student_name': e['student_name'],
              'amount': e['tuition_fee'],
              'payment_date': e['payment_date'],
              'class_name': e['class_name'],
            })
            .toList();

        return {"success": true, "payments": payments};
      }
      return {"success": false, "message": "Failed to load payments"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  /// Toggle payment status for an enrollment
  Future<Map<String, dynamic>> togglePaymentStatus(String enrollmentId) async {
    try {
      final response = await _dio.post("/enrollments/$enrollmentId/toggle-payment");
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "message": "Failed to update payment status"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }

  /// Get all enrollments with payment info (including unpaid)
  Future<Map<String, dynamic>> getAllEnrollmentsWithPayments() async {
    try {
      final response = await _dio.get("/enrollments");
      if (response.statusCode == 200) {
        return {"success": true, "enrollments": response.data['enrollments']};
      }
      return {"success": false, "message": "Failed to load payment records"};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['error'] ?? e.message};
    }
  }
}

