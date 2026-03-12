import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 🚀 Updated function to talk to your new Render/Neon Backend
  Future<void> _saveTokenToDatabase(String fcmToken, String email) async {
    final String backendEndpoint = 'https://whatsapp-clone-backend-navv.onrender.com/users/save-token';
    try {
      final response = await http.post(
        Uri.parse(backendEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email, // 👈 We now send the unique email, not the name!
          "fcmToken": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCESS: Saved token to Neon Database for $email!");
      } else {
        print("🚨 SERVER ERROR: Could not save token. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 NETWORK ERROR: Failed to send token: $e");
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Forces Google to clear its memory so the popup always shows
      await googleSignIn.signOut(); 
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Log the user into Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // 🚀 --- NOTIFICATION TOKEN LOGIC --- 🚀
      // 1. Get the user's unique Google email
      final String userEmail = googleUser.email; 
      
      // 2. Ask Firebase for this device's unique Notification Token
      String? token = await FirebaseMessaging.instance.getToken();
      print('📱 FCM DEVICE TOKEN: $token');

      // 3. Send the email and token up to your NestJS Backend!
      if (token != null) {
        await _saveTokenToDatabase(token, userEmail); 
      }
      // 🚀 -------------------------------------- 🚀

      if (context.mounted) {
        _showUsernameDialog(context, userEmail);
      }
    } catch (e) {
      print("🚨 LOGIN ERROR: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Error: $e")),
        );
      }
    }
  }

  void _showUsernameDialog(BuildContext context, String userEmail) {
    final TextEditingController _usernameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter your name"),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: "Your Name"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final String chosenName = _usernameController.text.trim();
                
                if (chosenName.isNotEmpty) {
                  print("🚀 ATTEMPTING TO SAVE NAME: $chosenName for $userEmail");
                  
                  try {
                    // 🚨 IMPORTANT: Make sure this URL is your ACTUAL Render URL!
                    final response = await http.post(
                      Uri.parse('https://whatsapp-clone-backend-navv.onrender.com/users/update-name'), 
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        "email": userEmail, 
                        "username": chosenName
                      }),
                    );

                    print("🔥 BACKEND RESPONSE CODE: ${response.statusCode}");
                    print("🔥 BACKEND RESPONSE BODY: ${response.body}");

                  } catch (e) {
                    print("🚨 CRITICAL ERROR SAVING NAME: $e");
                  }

                  if (context.mounted) {
                    Navigator.pop(context); 
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  }
                }
              },
              child: const Text("Save & Continue"),
            )
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat, size: 100, color: Color(0xFF128C7E)),
            const SizedBox(height: 30),
            const Text("WhatsApp Clone", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              onPressed: () => _signInWithGoogle(context),
            ),
          ],
        ),
      ),
    );
  }
}