import 'package:flutter/material.dart';
import '../services/AuthService.dart';
import '../config/config_url.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final dio = AuthService.client;
      final response = await dio.get("/profile");
      
      if (response.statusCode == 200) {
        setState(() {
          _profileData = response.data['details'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.isEmpty) {
      return "";
    }
    // Clean up path separators for URLs
    imgPath = imgPath.replaceAll('\\\\', '/').replaceAll('\\', '/');
    if (imgPath.startsWith('http')) return imgPath;
    
    // Remove leading 'api/' if present in the path stored in DB
    if (imgPath.startsWith('api/')) {
      imgPath = imgPath.substring(4);
    } else if (imgPath.startsWith('/api/')) {
      imgPath = imgPath.substring(5);
    }
    
    // Get base URL without /api suffix
    String base = Config_URL.baseUrl;
    if (base.contains('/api')) {
      base = base.split('/api')[0];
    }
    
    if (imgPath.startsWith('/')) {
      return "$base$imgPath";
    }
    return "$base/$imgPath";
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = _getImageUrl(_profileData?['profile_pic']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_profileData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: _profileData!),
                  ),
                );
                if (result == true) {
                  _fetchProfile();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text("Không thể tải thông tin profile"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 80, color: Colors.blue)
                                  : null,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _profileData!['full_name'] ?? 'Người dùng',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _profileData!['role'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "THÔNG TIN TÀI KHOẢN",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoTile(Icons.alternate_email, "Username", _profileData!['username']),
                            _buildInfoTile(Icons.email_outlined, "Email", _profileData!['email']),
                            
                            const SizedBox(height: 20),
                            const Text(
                              "THÔNG TIN CÁ NHÂN",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoTile(Icons.phone_outlined, "Số điện thoại", _profileData!['phone_number'] ?? "Chưa cập nhật"),
                            _buildInfoTile(Icons.location_on_outlined, "Địa chỉ", _profileData!['address'] ?? "Chưa cập nhật"),
                            _buildInfoTile(Icons.cake_outlined, "Ngày sinh", _profileData!['date_of_birth'] ?? "Chưa cập nhật"),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value ?? "N/A",
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
