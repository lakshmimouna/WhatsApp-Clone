import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recentChats = [];
  List<dynamic> _recentGroups = []; 
  bool _isLoading = true;
  
  // 🚀 Setting your full name so the database knows who is looking at the screen
  final String currentUser = "Lakshmi Mouna";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      const String baseUrl = 'http://192.168.1.12:3000/chat/recent';
      
      // 🚀 Passing your name to the NestJS backend
      final chatRes = await http.get(Uri.parse('$baseUrl/chat?user=$currentUser'));
      final groupRes = await http.get(Uri.parse('$baseUrl/group?user=$currentUser'));

      if (mounted) {
        if (chatRes.statusCode == 200 && groupRes.statusCode == 200) {
          setState(() {
            _recentChats = jsonDecode(chatRes.body);
            _recentGroups = jsonDecode(groupRes.body);
            _isLoading = false;
          });
        } else {
          print("🚨 Server Error: Chats ${chatRes.statusCode}, Groups ${groupRes.statusCode}");
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("🚨 Network Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF128C7E),
          foregroundColor: Colors.white,
          title: const Text('WhatsApp Clone', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try { await GoogleSignIn().disconnect(); } catch (e) {}
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'CHATS'), Tab(text: 'GROUPS'), Tab(text: 'CALLS')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatList(_recentChats, isGroup: false),
            _buildChatList(_recentGroups, isGroup: true),
            const Center(child: Text("Calls Under Construction", style: TextStyle(color: Colors.grey))),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChatList(List<dynamic> data, {required bool isGroup}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
    if (data.isEmpty) return Center(child: Text(isGroup ? "No groups yet" : "No chats yet", style: const TextStyle(color: Colors.grey)));

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          String timeString = "";
          if (item["timestamp"] != null) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(item["timestamp"] as int);
            timeString = DateFormat('h:mm a').format(date);
          }

          // 🚀 Grab the unread count from your backend!
          final int unreadCount = item['unreadCount'] ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isGroup ? const Color(0xFF128C7E) : Colors.grey.shade400,
              child: Icon(isGroup ? Icons.group : Icons.person, color: Colors.white),
            ),
            title: Text(
              isGroup ? item['roomID'].toString().replaceAll('Group:', '') : item['roomID'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${item['sender']}: ${item['text']}", maxLines: 1, overflow: TextOverflow.ellipsis),
            
            // 🚀 The Green Circle UI Magic Happens Here
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
            onTap: () async {
              // 🚀 THE ERASER TRIGGER: Tell NestJS to clear the circle BEFORE opening the chat!
              if (unreadCount > 0) {
                try {
                  final String markReadUrl = 'http://192.168.1.12:3000/chat/mark-read/${item['roomID']}?user=Lakshmi%20Mouna';
                  await http.get(Uri.parse(markReadUrl));
                } catch (e) {
                  print("Could not mark as read: $e");
                }
              }

              // Open the Chat Screen
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(contactName: item['roomID'])),
              );
              
              // Refresh the Home Screen when you press the back button
              _fetchData();
            },
          );
        },
      ),
    );
  }
}