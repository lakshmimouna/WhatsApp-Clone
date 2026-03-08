import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 Added for Notifications
import 'package:http/http.dart' as http; // 🚀 Added to talk to AWS
import 'dart:convert'; // 🚀 Added to package data into JSON

import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 🚀 The function that updates your AWS "Phonebook" with the FCM Token
  Future<void> _saveTokenToAWS(String fcmToken, String userName) async {
    // 👉 REMEMBER TO REPLACE THIS WITH YOUR REAL AWS NESTJS URL!
    final String awsEndpoint = 'http://192.168.1.12:3000/users/save-token';
    try {
      final response = await http.post(
        Uri.parse(awsEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userName": userName, 
          "fcmToken": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCESS: Saved $userName's token to AWS!");
      } else {
        print("🚨 AWS ERROR: Could not save token. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 NETWORK ERROR: Failed to send token to AWS: $e");
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
      
      // 🚀 --- NEW NOTIFICATION TOKEN LOGIC --- 🚀
      // 1. Get the user's actual Google name (e.g., "Lakshmi Mouna")
      final String userName = googleUser.displayName ?? "Unknown User";
      
      // 2. Ask Firebase for this device's unique Notification Token
      String? token = await FirebaseMessaging.instance.getToken();
      print('📱 FCM DEVICE TOKEN: $token');

      // 3. Send the name and token up to AWS!
      if (token != null) {
        await _saveTokenToAWS(token, userName); 
      }
      // 🚀 -------------------------------------- 🚀

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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