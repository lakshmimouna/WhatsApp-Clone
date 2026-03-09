import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  SplashContent(
                    icon: Icons.chat,
                    title: 'Welcome to WhatsApp Clone',
                    description: 'A simple, reliable, and private way to connect.',
                  ),
                  SplashContent(
                    icon: Icons.group,
                    title: 'Group Chats',
                    description: 'Keep in touch with your groups of friends and family.',
                  ),
                  SplashContent(
                    icon: Icons.lock,
                    title: 'Secure & Real-Time',
                    description: 'Your messages are synced instantly across your devices.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF128C7E)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF128C7E),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  if (_currentPage < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    try {
                      print("DEBUG: Starting Google Sign-In initialization...");
                      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
                      await googleSignIn.initialize(
                        clientId: '931997234707-1qug821ckttp3j7sp7ll5r8pucl6kac9.apps.googleusercontent.com', 
                        serverClientId: '931997234707-1qug821ckttp3j7sp7ll5r8pucl6kac9.apps.googleusercontent.com',
                      );

                      print("DEBUG: Prompting user for account selection...");
                      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
                      
                      if (googleUser == null) {
                        print("DEBUG: User closed the Google popup without selecting an account.");
                        return;
                      }

                      print("DEBUG: User selected: ${googleUser.email}");
                      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                      final String? idToken = googleAuth.idToken;

                      if (idToken != null) {
                        print("DEBUG: Token received. Sending to NestJS at https://whatsapp-clone-backend-navv.onrender.com");
                        
                        final response = await http.post(
                          Uri.parse('https://whatsapp-clone-backend-navv.onrender.com/auth/google'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'idToken': idToken}),
                        ).timeout(const Duration(seconds: 15)); // Timeout if backend is unreachable

                        print("DEBUG: Backend Response Code: ${response.statusCode}");
                        
                        if (response.statusCode == 201 || response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          print("SUCCESS! User saved to database: ${data['user']['name']}");
                          
                          // After successful login, we will navigate to the Home Screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Welcome ${data['user']['name']}!")),
                          );
                        } else {
                          print("DEBUG: Backend Error Message: ${response.body}");
                        }
                      } else {
                        print("DEBUG: Failed to retrieve ID Token from Google.");
                      }
                    } catch (e) {
                      print("DEBUG: CRITICAL ERROR: $e");
                    }
                  }
                },
                child: Text(
                  _currentPage == 2 ? 'Login with Google' : 'Next',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SplashContent({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: const Color(0xFF128C7E)),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}