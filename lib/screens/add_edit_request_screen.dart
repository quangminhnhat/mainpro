import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/RequestService.dart';

class AddEditRequestScreen extends StatefulWidget {
  final String? requestId;
  const AddEditRequestScreen({super.key, this.requestId});

  @override
  State<AddEditRequestScreen> createState() => _AddEditRequestScreenState();
}

class _AddEditRequestScreenState extends State<AddEditRequestScreen> {
  final RequestService _requestService = RequestService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _detailsController = TextEditingController();
  List<dynamic> _requestTypes = [];
  List<dynamic> _classes = [];
  String? _selectedType;
  String? _selectedClassId;
  int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      _userId = jsonDecode(userStr)['id'];
    }

    final result = await _requestService.getRequestFormData(requestId: widget.requestId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _requestTypes = result['requestTypes'];
          _classes = result['classes'];
          if (widget.requestId != null && result['request'] != null) {
            final r = result['request'];
            _detailsController.text = r['description'] ?? '';
            _selectedType = r['type_name'];
            _selectedClassId = r['class_id']?.toString();
          }
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a request type')));
        return;
      }

      final data = {
        'userId': _userId,
        'requestType': _selectedType,
        'details': _detailsController.text,
        'classId': _selectedClassId,
      };

      setState(() => _isLoading = true);
      final result = widget.requestId == null
          ? await _requestService.submitRequest(data)
          : await _requestService.updateRequest(widget.requestId!, data);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.requestId == null ? 'New Request' : 'Edit Request')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Request Type*', border: OutlineInputBorder()),
                      items: _requestTypes.map((t) => DropdownMenuItem<String>(
                        value: t['type_name'].toString(),
                        child: Text(t['type_name']),
                      )).toList(),
                      onChanged: widget.requestId != null ? null : (v) => setState(() => _selectedType = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(labelText: 'Related Class (Optional)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ..._classes.map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['class_name']),
                        )),
                      ],
                      onChanged: (v) => setState(() => _selectedClassId = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _detailsController,
                      decoration: const InputDecoration(labelText: 'Details*', border: OutlineInputBorder()),
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.requestId == null ? 'Submit Request' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
