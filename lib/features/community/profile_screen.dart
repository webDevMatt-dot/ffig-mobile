import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _businessController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  // 1. GET Current Data
  Future<void> _fetchMyProfile() async {
    final token = await const FlutterSecureStorage().read(key: 'access_token');
    
    // Select URL based on device
    // Select URL based on device
    const String baseUrl = 'https://ffig-api.onrender.com/api/members/me/';

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _businessController.text = data['business_name'] ?? '';
          _industryController.text = data['industry'] ?? '';
          _locationController.text = data['location'] ?? '';
          _bioController.text = data['bio'] ?? '';
        });
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Connection Error: $e");
    } finally {
      // THIS IS THE FIX: Always stop loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. SAVE Changes (PATCH)
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    const String baseUrl = 'https://ffig-api.onrender.com/api/members/me/';

    try {
      final response = await http.patch(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'business_name': _businessController.text,
          'industry': _industryController.text,
          'location': _locationController.text,
          'bio': _bioController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text("MY PROFILE")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Pic Placeholder
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text("Tap to change photo (Coming Soon)", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField("Business Name", _businessController, Icons.business),
            const SizedBox(height: 16),
            _buildTextField("Industry", _industryController, Icons.work_outline),
            const SizedBox(height: 16),
            _buildTextField("Location", _locationController, Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField("Bio / Mission", _bioController, Icons.short_text, maxLines: 3),
            
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
