import 'package:flutter/material.dart';
import 'login_screen.dart'; // We import login to go there after clicking "Get Started"

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // This is the swipeable area holding your 3 welcome screens
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Screen 1
              _buildPage(
                icon: Icons.chat,
                title: "Welcome to WhatsApp Clone",
                description: "A simple, secure, and reliable way to connect with your friends and family.",
              ),
              // Screen 2
              _buildPage(
                icon: Icons.security,
                title: "Fast & Secure",
                description: "Your personal messages and calls are private and safe.",
              ),
              // Screen 3
              _buildPage(
                icon: Icons.group,
                title: "Stay Connected",
                description: "Group chats let you keep in touch with the people who matter most.",
              ),
            ],
          ),
          
          // The Bottom Buttons ("Next", "Skip", "Get Started")
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: _currentPage == 2 
                // If on the last screen, show "Get Started"
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      // Navigate to Login Screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                // If on screen 1 or 2, show "Skip" and "Next"
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _controller.jumpToPage(2),
                        child: const Text("SKIP", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF128C7E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text("NEXT"),
                      ),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  // Helper widget to easily build the text and icons for each page
  Widget _buildPage({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: const Color(0xFF128C7E)),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}