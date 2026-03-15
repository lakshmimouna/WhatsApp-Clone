import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatProvider extends ChangeNotifier {
  List<dynamic> recentChats = [];
  bool isLoadingChats = true;
  String currentUser = "Guest User";
  
  final storage = const FlutterSecureStorage();
  final String backendUrl = 'http://192.168.1.12:3000';

  Future<void> loadUser() async {
    String? email = await storage.read(key: 'user_email');
    if (email != null && email.isNotEmpty) {
      currentUser = email;
      notifyListeners(); 
    }
  }

  Future<void> fetchRecentChats() async {
    if (currentUser == "Guest User") return;

    isLoadingChats = true;
    notifyListeners(); 

    try {
      String safeUser = Uri.encodeComponent(currentUser);
      
      // 🚀 1. Fetch ALL registered users from your database
      final usersRes = await http.get(Uri.parse('$backendUrl/users'));
      
      // 🚀 2. Fetch active chats to get the latest messages
      final chatRes = await http.get(Uri.parse('$backendUrl/chat/recent?type=chat&email=$safeUser'));

      if (usersRes.statusCode == 200) {
        List<dynamic> allUsers = jsonDecode(usersRes.body);
        List<dynamic> activeChats = chatRes.statusCode == 200 ? jsonDecode(chatRes.body) : [];

        List<dynamic> mergedList = [];

        for (var user in allUsers) {
          if (user['email'] == currentUser) continue; // Don't show yourself in the list!

          // Look to see if you already have a chat history with this user
          var existingChat;
          try {
            existingChat = activeChats.firstWhere(
              (chat) => chat['email'] == user['email'] || chat['roomID'] == user['email'],
            );
          } catch (e) {
            existingChat = null; // No chat exists yet
          }

          if (existingChat != null) {
            // If chat exists, attach their name and add them
            existingChat['contactName'] = user['name'] ?? user['email'];
            mergedList.add(existingChat);
          } else {
            // 🚀 If they are a BRAND NEW user, create a blank tile for them automatically!
            mergedList.add({
              'email': user['email'],
              'roomID': user['email'],
              'contactName': user['name'] ?? user['email'],
              'text': 'Tap to start chatting',
              'timestamp': 0, 
              'unreadCount': 0,
            });
          }
        }

        // Sort the list so active conversations are at the top, and new users are underneath
        mergedList.sort((a, b) {
          int timeA = a['timestamp'] ?? 0;
          int timeB = b['timestamp'] ?? 0;
          return timeB.compareTo(timeA);
        });

        recentChats = mergedList;
      }
    } catch (e) {
      print("🚨 Network Error: $e");
    } finally {
      isLoadingChats = false;
      notifyListeners(); 
    }
  }

  void clearUnreadCount(int index) {
    recentChats[index]['unreadCount'] = 0;
    notifyListeners();
  }
}