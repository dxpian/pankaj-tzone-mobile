import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_features.dart';
import '../main.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Read all fields
    final token = await _storage.read(key: 'auth_token');
    final username = await _storage.read(key: 'username');
    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'email'); // 🟢 ADDED: Read Email

    if (mounted) {
      if (token != null && username != null && userId != null) {
        final user = UserProfile(
          userId: userId,
          username: username,
          email: email ?? "user@alfresa.com", // 🟢 ADDED: Fallback
          token: token,
          permissions: [
            AppModule.basicAlerts,
            AppModule.checkPoints,
            AppModule.locationMap,
            AppModule.graphData, 
          ],
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScaffold(user: user)));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Image.asset("assets/images/alfresa_logo.png", height: 150),
        ),
      ),
    );
  }
}