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
      appBar: AppBar(title: const Text('Register New User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthdayController,
                decoration: const InputDecoration(
                  labelText: 'Birthday',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, 
                onTap: () => _selectDate(context), 
                validator: (value) => value == null || value.isEmpty ? 'Please select birthday' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Please enter phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(labelText: 'User Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'subject1', child: Text('Student')),
                  DropdownMenuItem(value: 'subject2', child: Text('Teacher')),
                  DropdownMenuItem(value: 'subject3', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSubject = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Register User'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
