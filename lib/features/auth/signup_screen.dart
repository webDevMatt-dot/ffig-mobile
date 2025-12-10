import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);

    // 1. Basic Validation
    if (_passwordController.text != _confirmController.text) {
      _showError("Passwords do not match");
      setState(() => _isLoading = false);
      return;
    }

    // 2. Determine URL
    const baseUrl = 'https://ffig-api.onrender.com/api/auth/register/';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password2': _confirmController.text,
        }),
      );

      if (response.statusCode == 201) {
        // Success! Go back to Login so they can sign in.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please log in."), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Return to Login Screen
        }
      } else {
        // Handle errors (like "Username already exists")
        _showError("Registration failed: ${response.body}");
      }
    } catch (e) {
      _showError("Connection error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("JOIN FFIG")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Create your Account", style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Join the global network of female founders."),
            const SizedBox(height: 32),

            _buildTextField("Username", _usernameController, Icons.person),
            const SizedBox(height: 16),
            _buildTextField("Email", _emailController, Icons.email),
            const SizedBox(height: 16),
            _buildTextField("Password", _passwordController, Icons.lock, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField("Confirm Password", _confirmController, Icons.lock_outline, isObscure: true),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
