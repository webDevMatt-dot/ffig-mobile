import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; 
import 'package:country_picker/country_picker.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Added back
import '../../core/api/constants.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- VARIABLES ---
  bool _isLoading = true;
  bool _isSaving = false;
  
  final TextEditingController _businessController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  String _selectedIndustry = 'OTH'; 
  String? _userPhotoUrl; 
  XFile? _pickedImage; 

  // Industry Options
  final List<DropdownMenuItem<String>> _industryItems = [
    const DropdownMenuItem(value: 'TECH', child: Text('Technology')),
    const DropdownMenuItem(value: 'FIN', child: Text('Finance')),
    const DropdownMenuItem(value: 'HLTH', child: Text('Healthcare')),
    const DropdownMenuItem(value: 'RET', child: Text('Retail')),
    const DropdownMenuItem(value: 'EDU', child: Text('Education')),
    const DropdownMenuItem(value: 'MED', child: Text('Media & Arts')),
    const DropdownMenuItem(value: 'LEG', child: Text('Legal')),
    const DropdownMenuItem(value: 'FASH', child: Text('Fashion')),
    const DropdownMenuItem(value: 'MAN', child: Text('Manufacturing')),
    const DropdownMenuItem(value: 'OTH', child: Text('Other')),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyProfile();
  }

  // --- API FUNCTIONS ---

  Future<void> _fetchMyProfile() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) return; // Should handle logout/redirect

    try {
      final response = await http.get(
          Uri.parse('${baseUrl}members/me/'),
          headers: {'Authorization': 'Bearer $token'}
      ); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _businessController.text = data['business_name'] ?? '';
            _locationController.text = data['location'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _selectedIndustry = data['industry'] ?? 'OTH';
            // Handle Photo URL logic
            _userPhotoUrl = data['photo']; 
            if (_userPhotoUrl == null && data['photo_url'] != null) {
                _userPhotoUrl = data['photo_url'];
            }
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    try {
      var request = http.MultipartRequest('PATCH', Uri.parse('${baseUrl}members/me/'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['business_name'] = _businessController.text;
      request.fields['industry'] = _selectedIndustry;
      request.fields['location'] = _locationController.text;
      request.fields['bio'] = _bioController.text;

      if (_pickedImage != null) {
        if (kIsWeb) {
            var f = await _pickedImage!.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
                'photo', 
                f, 
                filename: 'upload.jpg'
            ));
        } else {
            request.files.add(await http.MultipartFile.fromPath(
                'photo', 
                _pickedImage!.path
            ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Saved!"), backgroundColor: Colors.green)
          );
          _fetchMyProfile(); 
        }
      } else {
        throw Exception("Server rejected update: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _pickedImage != null
                    ? (kIsWeb 
                        ? NetworkImage(_pickedImage!.path) 
                        : FileImage(File(_pickedImage!.path)) as ImageProvider)
                    : (_userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null),
                child: (_pickedImage == null && _userPhotoUrl == null)
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text("Tap to change photo", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 24),

            TextField(
              controller: _businessController,
              decoration: const InputDecoration(labelText: "Business Name", prefixIcon: Icon(Icons.business)),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: const InputDecoration(labelText: "Industry", prefixIcon: Icon(Icons.work)),
              items: _industryItems,
              onChanged: (val) => setState(() => _selectedIndustry = val!),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              readOnly: true, 
              decoration: const InputDecoration(
                labelText: "Location", 
                prefixIcon: Icon(Icons.location_on),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
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
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "Bio / Mission", prefixIcon: Icon(Icons.info)),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, 
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
