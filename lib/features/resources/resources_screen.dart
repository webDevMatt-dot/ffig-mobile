import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart'; // Import this

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<dynamic> _resources = [];
  bool _isLoading = true;
  String _selectedFilter = "ALL"; // ALL, MAGAZINE, VIDEO, TOOLKIT

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

  Future<void> _fetchResources() async {
    setState(() => _isLoading = true);
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    
    // Build URL with filter
    String baseUrl = 'https://ffig-api.onrender.com/api/resources/';
    
    if (_selectedFilter != "ALL") {
      baseUrl += "?type=$_selectedFilter";
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() => _resources = jsonDecode(response.body));
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RESOURCE VAULT")),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip("All", "ALL"),
                const SizedBox(width: 8),
                _buildFilterChip("Magazines", "MAGAZINE"),
                const SizedBox(width: 8),
                _buildFilterChip("Masterclasses", "MASTERCLASS"),
                const SizedBox(width: 8),
                _buildFilterChip("Newsletters", "NEWSLETTER"),
                const SizedBox(width: 8),
                _buildFilterChip("Toolkits", "TOOLKIT"),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _resources.isEmpty 
                  ? const Center(child: Text("No resources found."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _resources.length,
                      itemBuilder: (context, index) {
                        final res = _resources[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _launchURL(res['url']),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                Image.network(
                                  res['thumbnail_url'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        res['resource_type'], 
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        res['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        res['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final primary = Theme.of(context).colorScheme.primary;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
          _fetchResources();
        }
      },
      selectedColor: primary,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.black87),
    );
  }
}
