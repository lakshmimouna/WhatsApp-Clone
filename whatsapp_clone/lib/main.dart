import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 Added FCM
import 'dart:ui';

import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';

// 🚀 1. This runs in the background to catch notifications when the app is closed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 BACKGROUND NOTIFICATION RECEIVED: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🚀 2. Tell Firebase to use our background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: WhatsAppClone()));
}

class WhatsAppClone extends StatefulWidget {
  const WhatsAppClone({super.key});

  @override
  State<WhatsAppClone> createState() => _WhatsAppCloneState();
}

class _WhatsAppCloneState extends State<WhatsAppClone> {

  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  // 🚀 3. The function that asks for permission and gets your phone's "Mailing Address"
  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Ask the user for permission to show pop-up alerts
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission for notifications');
      
      // Get the unique token for this specific phone
      String? token = await messaging.getToken();
      print('📱 FCM DEVICE TOKEN: $token'); // WE NEED THIS TOKEN!
      
    } else {
      print('🚫 User declined notification permissions');
    }

    // Listen for messages while the app is OPEN and on the screen
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 FOREGROUND NOTIFICATION RECEIVED: ${message.notification?.title}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Clone',
      debugShowCheckedModeBanner: false,
      
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF128C7E)),
        useMaterial3: true,
      ),
      // Always start the app at the Onboarding Screen
      home: const OnboardingScreen(), 
    );
  }
}