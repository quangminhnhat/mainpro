import 'package:flutter/material.dart';
import '../services/AuthService.dart';
import 'package:dio/dio.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _fullNameController = TextEditingController(text: widget.user['full_name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _phoneController = TextEditingController(text: widget.user['phone'] ?? widget.user['phone_number']);
    _addressController = TextEditingController(text: widget.user['address']);
    _dobController = TextEditingController(text: widget.user['date_of_birth']);
    _selectedRole = widget.user['role']?.toString().toLowerCase();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = AuthService.client;
      final response = await dio.post(
        "/users/${widget.user['id']}",
        data: {
          "username": _usernameController.text.trim(),
          "full_name": _fullNameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone_number": _phoneController.text.trim(),
          "address": _addressController.text.trim(),
          "date_of_birth": _dobController.text.trim(),
          "role": _selectedRole,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật người dùng thành công')),
          );
          Navigator.pop(context, true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['error'] ?? 'Lỗi cập nhật')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa người dùng')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Không được để trống' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateUser,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('CẬP NHẬT'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
