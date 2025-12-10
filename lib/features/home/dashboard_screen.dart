import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../community/member_list_screen.dart';
import '../community/profile_screen.dart';
import '../resources/resources_screen.dart';
import '../events/events_screen.dart';
import '../events/event_detail_screen.dart';
import '../events/event_detail_screen.dart';
import '../premium/locked_screen.dart';
import '../premium/premium_screen.dart';
import '../auth/login_screen.dart';
import '../chat/inbox_screen.dart';
import 'package:overlay_support/overlay_support.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> _events = [];
  bool _isLoading = true;
  bool _isPremium = false;
  Timer? _notificationTimer;
  int _lastUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedEvents();
    _checkPremiumStatus();
    // Start the Global Listener (Checks every 10 seconds)
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkUnreadMessages();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUnreadMessages() async {
    final token = await const FlutterSecureStorage().read(key: 'access_token');
    // Adjust URL based on device
    const String baseUrl = 'https://ffig-api.onrender.com/api/chat/unread-count/';

    // 1. Quit early if not premium
    if (!_isPremium) return; 

    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int currentCount = data['unread_count'];

        // If we have MORE unread messages than before, Ding!
        if (currentCount > _lastUnreadCount) {
           showSimpleNotification(
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen()));
                },
                child: const Text("New Message Received! Tap to check."),
              ),
              subtitle: const Text("Someone wants to connect."),
              background: Colors.amber, 
              foreground: Colors.black,
              duration: const Duration(seconds: 4),
              slideDismissDirection: DismissDirection.up,
           );
        }
        _lastUnreadCount = currentCount;
      }
    } catch (e) {
      if (kDebugMode) print("Notification Check Error: $e");
    }
  }

  Future<void> _checkPremiumStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    const String baseUrl = 'https://ffig-api.onrender.com/api/members/me/';

    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isPremium = data['is_premium'] ?? false;
          });
          
          // Save to storage so other screens can see it
          await storage.write(key: 'is_premium', value: _isPremium.toString());
        }
      }
    } catch (e) {
      print("Error checking premium status: $e");
    }
  }

  Future<void> _fetchFeaturedEvents() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    const String baseUrl = 'https://ffig-api.onrender.com/api/events/featured/';

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- THE KEY TO THE CASTLE
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _events = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        // Token might be expired
        print("Error fetching events: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Connection error: $e");
      setState(() => _isLoading = false);
    }
  }

  // Logout Function
  Future<void> _logout() async {
    // 1. Delete the token
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    // 2. Return to Login
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("FFIG MEMBER PORTAL", style: GoogleFonts.lato(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: () {
              if (_isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LockedScreen()));
              }
            },
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: _selectedIndex == 0 
          ? _buildHomeTab() 
          : _selectedIndex == 1 // 1 is Events
              ? const EventsScreen()
              : _selectedIndex == 2 
                  ? const MemberListScreen() 
                  : _selectedIndex == 3
                      ? (_isPremium ? const PremiumScreen() : const LockedScreen())
                      : _selectedIndex == 4
                          ? const ProfileScreen()
                          : _buildPlaceholder("Coming Soon"),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        indicatorColor: goldColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Network'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'VIP'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Welcome, Founder.", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.amber))
        else if (_events.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No upcoming events.")))
        else
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.amber))
        else if (_events.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No upcoming events.")))
        else
          // Display the first featured event
          GestureDetector(
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => EventDetailScreen(event: _events[0]))
              );
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  // Use the image URL from Django
                  image: NetworkImage(_events[0]['image_url']), 
                  fit: BoxFit.cover,
                  opacity: 0.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                      child: const Text("FEATURED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _events[0]['title'], // Real Title
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${_events[0]['location']} • ${_events[0]['date']}", // Real Details
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),
        Text("Quick Access", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // 2. Action Grid
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(Icons.diamond_outlined, "Benefits", () {}),
            _buildActionCard(Icons.forum_outlined, "Mentors", () {}),
            _buildActionCard(Icons.library_books_outlined, "Resources", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourcesScreen()));
            }),
            _buildActionCard(Icons.qr_code, "My ID", () {}),
          ],
        )
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) => Center(child: Text(text));
}
