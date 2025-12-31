import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/AuthService.dart';
import '../config/config_url.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _emailController = TextEditingController(text: widget.user['email']);
    _fullNameController = TextEditingController(text: widget.user['full_name']);
    _phoneController = TextEditingController(text: widget.user['phone_number'] ?? widget.user['phone']);
    _addressController = TextEditingController(text: widget.user['address']);
    _dobController = TextEditingController(text: widget.user['date_of_birth']);
    _checkIfMe();
  }

  Future<void> _checkIfMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentStr = prefs.getString('user_data');
    if (currentStr != null) {
      final current = jsonDecode(currentStr);
      setState(() {
        _isMe = current['id'].toString() == widget.user['id'].toString();
      });
      print("EditProfileScreen: Is owner? $_isMe");
    }
  }

  Future<void> _pickImage() async {
    print("Attempting to pick image...");
    if (!_isMe) {
      print("Picker blocked: Not the owner.");
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        print("Image selected: ${image.path}");
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở bộ sưu tập: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = AuthService.client;
      
      Map<String, dynamic> map = {
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "full_name": _fullNameController.text.trim(),
        "phone_number": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "date_of_birth": _dobController.text.trim(),
      };

      FormData formData = FormData.fromMap(map);

      if (_isMe && _imageFile != null) {
        formData.files.add(MapEntry(
          "profile_pic",
          await MultipartFile.fromFile(_imageFile!.path, filename: "profile.jpg"),
        ));
      }

      final response = await dio.post("/users/${widget.user['id']}", data: formData);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
          );
          Navigator.pop(context, true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['error'] ?? 'Lỗi cập nhật: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? serverPic = widget.user['profile_pic'];
    String? imageUrl;
    if (serverPic != null && serverPic.isNotEmpty) {
      String base = Config_URL.baseUrl.replaceAll('/api/', '');
      imageUrl = "$base/$serverPic";
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isMe ? _pickImage : null,
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) as ImageProvider
                          : (imageUrl != null ? NetworkImage(imageUrl) : null),
                        child: _imageFile == null && imageUrl == null
                          ? const Icon(Icons.person, size: 80, color: Colors.blue)
                          : null,
                      ),
                      if (_isMe)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 20,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)', border: OutlineInputBorder()),
                readOnly: true,
                onTap: () async {
                  DateTime? current = DateTime.tryParse(_dobController.text);
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: current ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              const SizedBox(height: 30),
              _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('LƯU THAY ĐỔI'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
