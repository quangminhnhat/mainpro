import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedSubject = 'subject1'; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ngày mặc định
    _birthdayController.text = DateFormat('yyyy-MM-dd').format(DateTime(2000, 1, 1));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await Auth.register(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        birthday: _birthdayController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        subject: _selectedSubject,
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        if (result['success']) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthdayController,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, 
                onTap: () => _selectDate(context), 
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng chọn ngày sinh' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(labelText: 'Loại tài khoản', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'subject1', child: Text('Người dùng (User)')),
                  DropdownMenuItem(value: 'subject2', child: Text('Quản lý (Manager)')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSubject = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value == null || value.length < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Đăng ký'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
