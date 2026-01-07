import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../models/app_features.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  
  // controllers to capture user input
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _performLogin() async {
    final String passwordInput = _passwordController.text.trim();

    // Validating password presence as per the new requirement
    if (passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your Password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. UPDATED ENDPOINT: Correct path provided by your colleague
      final url = Uri.parse("https://www.ibtrace.com/tzoneserver/api/v1/auth/login");
      
      // 2. UPDATED BODY: Includes all required keys (email, password, username)
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": "pankaj@ithrue.com",
          "password": passwordInput,
          "username": "Ite-admin",
          "withCredentials": true
        }),
      );

      // Logging for immediate verification in your console
      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 3. CORRECT DATA EXTRACTION based on your Raw Log
        // Token is at the top level in 'accesstoken' (lowercase)
        final String serverToken = data['accesstoken'] ?? "";
        
        // User details are inside the first element of the 'object' list
        String serverUserId = "Ite-admin";
        String serverName = "Admin";
        
        if (data['object'] != null && data['object'] is List && data['object'].isNotEmpty) {
          serverUserId = data['object'][0]['id']?.toString() ?? serverUserId;
          serverName = data['object'][0]['name'] ?? serverName;
        }

        if (serverToken.isEmpty) {
          throw Exception("Login succeeded but no Access Token was found.");
        }

        final realUser = UserProfile(
          userId: serverUserId,
          username: serverName,
          token: serverToken,
          permissions: [
            AppModule.basicAlerts,
            AppModule.checkPoints,
            AppModule.locationMap,
            AppModule.graphData,
          ],
        );

        // 4. SAVE REAL SESSION TO STORAGE
        await _storage.write(key: 'auth_token', value: realUser.token);
        await _storage.write(key: 'username', value: realUser.username);
        await _storage.write(key: 'user_id', value: realUser.userId);
        await _storage.write(
          key: 'permissions', 
          value: UserProfile.encodePermissions(realUser.permissions)
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainScaffold(user: realUser)),
          );
        }
      } else {
        throw Exception("Authentication failed (Status: ${response.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder icon for the logo
              const Icon(Icons.ac_unit, size: 60, color: Colors.blue), 
              const SizedBox(height: 40),
              const Text(
                "Cold Chain Monitor",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              
              const Text(
                "Authenticating as ITE-Admin",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Enter Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Secure Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}