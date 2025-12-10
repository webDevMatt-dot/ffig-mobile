import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'dart:io';

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

  File? _imageFile;
  String? _userPhotoUrl; // Store the URL from backend
  String _selectedIndustry = 'OTH'; 

  final List<DropdownMenuItem<String>> _industryItems = const [
    DropdownMenuItem(value: 'TECH', child: Text('Technology')),
    DropdownMenuItem(value: 'FIN', child: Text('Finance')),
    DropdownMenuItem(value: 'HLTH', child: Text('Healthcare')),
    DropdownMenuItem(value: 'RET', child: Text('Retail')),
    DropdownMenuItem(value: 'EDU', child: Text('Education')),
    DropdownMenuItem(value: 'MED', child: Text('Media & Arts')),
    DropdownMenuItem(value: 'LEG', child: Text('Legal')),
    DropdownMenuItem(value: 'FASH', child: Text('Fashion')),
    DropdownMenuItem(value: 'MAN', child: Text('Manufacturing')),
    DropdownMenuItem(value: 'OTH', child: Text('Other')),
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

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
      }
    } catch (e) {
      print("Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. SAVE Changes (Supports Image Upload)
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    const String baseUrl = 'https://ffig-api.onrender.com/api/members/me/';

    try {
      final request = http.MultipartRequest('PATCH', Uri.parse(baseUrl));
      request.headers['Authorization'] = 'Bearer $token';

      // Text Fields
      request.fields['business_name'] = _businessController.text;
      request.fields['industry'] = _selectedIndustry;
      request.fields['location'] = _locationController.text;
      request.fields['bio'] = _bioController.text;

      // File
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
           );
           // Refresh to show new photo URL if it changed
           _fetchMyProfile();
        }
      } else {
        print(response.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save."), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
            // Profile Pic
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) 
                    : (_userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null) as ImageProvider?,
                child: (_imageFile == null && _userPhotoUrl == null) 
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text("Tap to change photo", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField("Business Name", _businessController, Icons.business),
            const SizedBox(height: 16),
            
            // INDUSTRY DROPDOWN
            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: InputDecoration(
                labelText: "Industry",
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _industryItems,
              onChanged: (val) => setState(() => _selectedIndustry = val!),
            ),
            const SizedBox(height: 16),
            
            // LOCATION PICKER
            GestureDetector(
                onTap: () {
                    showCountryPicker(
                    context: context,
                    onSelect: (Country country) {
                        setState(() {
                        _locationController.text = country.displayNameNoCountryCode; 
                        });
                    },
                    );
                },
                child: AbsorbPointer( // Prevent manual typing
                    child: _buildTextField("Location", _locationController, Icons.location_on_outlined),
                ),
            ),
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
