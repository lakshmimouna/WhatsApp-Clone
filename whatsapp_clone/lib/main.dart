import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart'; // 🚀 Added Provider Import
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/chat_provider.dart'; // 🚀 Added Your New Brain

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // 🚀 We wrap the entire app in the Provider so any screen can access the data!
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF128C7E),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF128C7E),
          secondary: const Color(0xFF25D366),
        ),
      ),
      home: FutureBuilder<String?>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF128C7E))),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}