import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/config_url.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String groups = user['group_name'] ?? 'Không có nhóm';
    final createdAt = user['created_at'] != null ? DateTime.parse(user['created_at']) : null;

    // Construct Profile Picture URL
    String? serverPic = user['profile_pic'];
    String? imageUrl;
    if (serverPic != null && serverPic.isNotEmpty) {
      String base = Config_URL.baseUrl.replaceAll('/api/', '');
      imageUrl = "$base/$serverPic";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user['full_name'] ?? user['username']),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? Text(
                      (user['full_name']?[0] ?? user['username'][0]).toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['full_name'] ?? user['username'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user['role'].toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Thông tin chi tiết",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoItem(Icons.person_outline, "Tên đăng nhập", user['username']),
            _buildInfoItem(Icons.email_outlined, "Email", user['email']),
            _buildInfoItem(Icons.phone_outlined, "Số điện thoại", user['phone_number'] ?? user['phone'] ?? "Chưa cập nhật"),
            _buildInfoItem(Icons.location_on_outlined, "Địa chỉ", user['address'] ?? "Chưa cập nhật"),
            _buildInfoItem(Icons.cake_outlined, "Ngày sinh", user['date_of_birth'] ?? "Chưa cập nhật"),
            _buildInfoItem(Icons.groups_outlined, "Nhóm", groups),
            if (createdAt != null)
              _buildInfoItem(
                Icons.calendar_today_outlined,
                "Ngày tham gia",
                DateFormat('dd/MM/yyyy').format(createdAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
