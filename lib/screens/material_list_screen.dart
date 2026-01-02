import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/MaterialService.dart';
import '../config/config_url.dart';
import 'upload_material_screen.dart';
import 'edit_material_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final MaterialService _materialService = MaterialService();
  List<dynamic> _materials = [];
  bool _isLoading = true;
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchMaterials();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      final userData = jsonDecode(userStr);
      setState(() {
        _userRole = userData['role']?.toString().toLowerCase() ?? 'student';
      });
    }
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);
    final results = await _materialService.getMaterials();
    if (mounted) {
      setState(() {
        _materials = results;
        _isLoading = false;
      });
    }
  }

  void _deleteMaterial(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _materialService.deleteMaterial(id);
      if (success && mounted) {
        _fetchMaterials();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material deleted')));
      }
    }
  }

  Future<void> _downloadMaterial(String id) async {
    String base = Config_URL.baseUrl.replaceAll('/api', '');
    final Uri url = Uri.parse("$base/download/$id");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start download')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = _userRole == 'admin' || _userRole == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Materials'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadMaterialScreen()),
                );
                if (result == true) _fetchMaterials();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMaterials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMaterials,
              child: _materials.isEmpty
                  ? const Center(child: Text('No materials found'))
                  : ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final mat = _materials[index];
                        final date = mat['uploaded_at'] != null 
                            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(mat['uploaded_at']))
                            : 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.description, color: Colors.blue, size: 36),
                            title: Text(mat['file_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Course: ${mat['course_name']}\nUploaded: $date'),
                            onTap: () => _downloadMaterial(mat['id'].toString()),
                            trailing: canManage
                                ? PopupMenuButton(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => EditMaterialScreen(materialId: mat['id'].toString())),
                                        );
                                        if (result == true) _fetchMaterials();
                                      } else if (value == 'delete') {
                                        _deleteMaterial(mat['id'].toString());
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.download, color: Colors.green),
                                    onPressed: () => _downloadMaterial(mat['id'].toString()),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
