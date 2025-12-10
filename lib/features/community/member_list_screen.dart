import 'dart:async'; // Add this for Timer (Debounce)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Needed for Velvet Rope
import '../../core/api/constants.dart';
import '../chat/chat_screen.dart'; // Needed for navigation
import '../premium/locked_screen.dart'; // Needed for navigation

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  
  // --- FILTER VARIABLES ---
  String _searchQuery = "";
  String _selectedIndustry = "ALL"; // Default to show all
  String _sortBy = "name"; // Options: name, industry
  bool _premiumOnly = false;
  Timer? _debounce; // To stop API calls on every keystroke

  final List<DropdownMenuItem<String>> _industryOptions = [
    const DropdownMenuItem(value: 'ALL', child: Text('All Industries')),
    const DropdownMenuItem(value: 'TECH', child: Text('Technology')),
    const DropdownMenuItem(value: 'FIN', child: Text('Finance')),
    const DropdownMenuItem(value: 'HLTH', child: Text('Healthcare')),
    const DropdownMenuItem(value: 'RET', child: Text('Retail')),
    const DropdownMenuItem(value: 'EDU', child: Text('Education')),
    const DropdownMenuItem(value: 'MED', child: Text('Media')),
    const DropdownMenuItem(value: 'OTH', child: Text('Other')),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // --- API CALL ---
  Future<void> _fetchMembers() async {
    // Avoid setting loading to true on every keystroke to prevent flickering, 
    // but useful for initial load or major filter changes.
    // For now we keep it simple.
    // setState(() => _isLoading = true); 
    
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    
    try {
      // Build the URL with query parameters
      String url = '${baseUrl}members/?search=$_searchQuery';
      
      if (_selectedIndustry != 'ALL') {
        url += '&industry=$_selectedIndustry';
      }
      
      // Note: Backend typically sorts by Premium first automatically.
      // We can add extra sorting here if the backend supports it.
      
      final response = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List;

        // CLIENT-SIDE FILTERING (For instant "Premium Only" toggle)
        if (_premiumOnly) {
          data = data.where((m) => m['is_premium'] == true).toList();
        }

        // CLIENT-SIDE SORTING
        data.sort((a, b) {
           // Always keep Premium users at the very top
           bool aPrem = a['is_premium'] ?? false;
           bool bPrem = b['is_premium'] ?? false;
           if (aPrem && !bPrem) return -1;
           if (!aPrem && bPrem) return 1;

           // Then sort by chosen field
           if (_sortBy == 'industry') {
             return (a['industry_label'] ?? '').compareTo(b['industry_label'] ?? '');
           }
           return (a['username'] ?? '').compareTo(b['username'] ?? '');
        });

        if (mounted) {
          setState(() {
            _members = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SEARCH DEBOUNCE ---
  // Waits 500ms after user stops typing before calling API
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Global Network")),
      body: Column(
        children: [
          // --- SEARCH & FILTER BAR ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: [
                // 1. Search Box
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search Name or Location...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                
                // 2. Dropdowns Row
                Row(
                  children: [
                    // Industry Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedIndustry,
                            isExpanded: true,
                            items: _industryOptions,
                            onChanged: (val) {
                              setState(() => {
                                _selectedIndustry = val!,
                                _isLoading = true
                              });
                              _fetchMembers();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                              DropdownMenuItem(value: 'industry', child: Text('Sort: Industry')),
                            ],
                            onChanged: (val) {
                                setState(() => _sortBy = val!);
                                _fetchMembers(); // Re-sort list
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 3. Premium Filter Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _premiumOnly, 
                      activeColor: Colors.amber,
                      onChanged: (val) {
                        setState(() => _premiumOnly = val!);
                        _fetchMembers();
                      }
                    ),
                    const Text("Show Premium Members Only"),
                  ],
                )
              ],
            ),
          ),

          // --- THE LIST ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isPremium = member['is_premium'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: member['photo'] != null 
                                ? NetworkImage(member['photo']) 
                                : (member['photo_url'] != null ? NetworkImage(member['photo_url']) : null),
                              child: (member['photo'] == null && member['photo_url'] == null) ? const Icon(Icons.person) : null,
                            ),
                            if (isPremium)
                               const Positioned(
                                top: -4, right: -4, 
                                child: Icon(Icons.stars, color: Colors.amber, size: 20)
                              ),
                            if (member['is_online'] == true)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        title: Text(member['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${member['industry_label'] ?? member['industry'] ?? 'Unknown'} • ${member['location'] ?? ''}"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                        onTap: () async {
                            // THE VELVET ROPE Logic
                            const storage = FlutterSecureStorage();
                            final isPremiumString = await storage.read(key: 'is_premium');
                            final bool iAmPremium = isPremiumString == 'true';
                            final bool memberIsPremium = member['is_premium'] ?? false;

                            // Restrict access if SHE is Premium and I am NOT
                            if (memberIsPremium && !iAmPremium) {
                                showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                    title: const Text("VIP Member 🔒"),
                                    content: const Text("This founder is in the Premium Circle. Upgrade your membership to connect with her."),
                                    actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                    ElevatedButton(
                                        onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LockedScreen())); 
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                        child: const Text("Upgrade Now", style: TextStyle(color: Colors.black)),
                                    )
                                    ],
                                )
                                );
                            } else {
                                // Access Granted
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                        recipientId: member['user_id'], 
                                        recipientName: member['username'],
                                    ),
                                    ),
                                );
                            }
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
