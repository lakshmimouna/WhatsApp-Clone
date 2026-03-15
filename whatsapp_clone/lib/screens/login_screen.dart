import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🚀 Toggle between Login and Signup modes
  bool _isLoginMode = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final storage = const FlutterSecureStorage();
  
  // 🚀 Updated to your Local IP!
  final String backendUrl = 'http://192.168.1.12:3000';

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    final endpoint = _isLoginMode ? '/users/login' : '/users/signup';

    try {
      final response = await http.post(
        Uri.parse('$backendUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          if (!_isLoginMode) "name": name, 
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_isLoginMode) {
          await storage.write(key: 'jwt_token', value: responseData['access_token']);
          await storage.write(key: 'user_email', value: responseData['user']['email']);
          await storage.write(key: 'user_name', value: responseData['user']['name'] ?? 'Unknown');

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Signup successful! Please log in."), backgroundColor: Colors.green),
            );
            setState(() => _isLoginMode = true);
          }
        }
      } else {
        _showError(responseData['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      _showError("Network error: Check your connection.");
      print("🚨 Auth Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat, size: 80, color: Color(0xFF128C7E)),
              const SizedBox(height: 20),
              Text(
                _isLoginMode ? "Welcome Back" : "Create Account",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF128C7E)),
              ),
              const SizedBox(height: 40),
              
              if (!_isLoginMode) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
              ],
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF128C7E)),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLoginMode ? "Login" : "Sign Up", style: const TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  setState(() => _isLoginMode = !_isLoginMode);
                },
                child: Text(
                  _isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Log in",
                  style: const TextStyle(color: Color(0xFF128C7E)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}