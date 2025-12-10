import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/login_screen.dart';
import 'package:overlay_support/overlay_support.dart';

void main() {
  runApp(const FFIGApp());
}



class FFIGApp extends StatelessWidget {
  const FFIGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'FFIG Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Assuming a Premium Gold/Black or Deep Purple palette based on the "Gala" vibe
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A1A2E), // Deep Navy/Black
            primary: const Color(0xFFD4AF37),   // Metallic Gold
            secondary: const Color(0xFFE94560), // Accent Pink/Red
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.playfairDisplayTextTheme(), // Elegant serif for headings
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate checking for a Django Token, then navigate
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Icon(Icons.diamond_outlined, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              "FFIG",
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "FEMALE FOUNDERS INITIATIVE GLOBAL",
              style: GoogleFonts.lato(
                fontSize: 12,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "\"We don't compete,\nwe collaborate.\"",
              textAlign: TextAlign.center,
              style: GoogleFonts.dancingScript(
                fontSize: 24,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}