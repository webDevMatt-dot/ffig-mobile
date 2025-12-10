import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/ffig_strings.dart';
import '../chat/chat_screen.dart';
import '../premium/locked_screen.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    
    // Choose the right URL based on device
    const String baseUrl = 'https://ffig-api.onrender.com/api/members/';

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _members = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FOUNDER DIRECTORY")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            itemCount: _members.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final member = _members[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(member['photo_url']),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(
                    member['username'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        member['business_name'].isNotEmpty 
                            ? member['business_name'] 
                            : "Stealth Mode",
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)
                      ),
                      Text("${member['industry']} • ${member['location']}"),
                    ],
                  ),
                  trailing: Icon(Icons.chat_bubble_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                  
                  // HERE IS THE CORRECTED SINGLE ONTAP
                  onTap: () async {
                    const storage = FlutterSecureStorage();
                    final isPremiumString = await storage.read(key: 'is_premium');
                    final bool isPremium = isPremiumString == 'true';

                    if (isPremium) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientId: member['user_id'], 
                            recipientName: member['username'],
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LockedScreen()));
                    }
                  },
                ),
              );
            },
          ),
    );
  }
}
