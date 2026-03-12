import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/socket_service.dart'; // Add this import
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
  
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String _query = "";
  
  // 🚀 Setting your EMAIL so the database knows exactly who is looking at the screen
  String get currentUser {
    return FirebaseAuth.instance.currentUser?.email ?? "Guest User";
  }

  // 🚀 The Notification Engine
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    
    // 🚀 1. Setup the Android Notification Channel
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    // 🚀 THE FIX: The parameter is literally just called "settings" now!
    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
    );

    // 🚀 2. NEW: Ask Android for permission to show the notification!
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(); 
      
      // 🚀 Start the global socket using your email!
      SocketService().connect(currentUser); // Replace myEmail with however you get the logged-in user's email
      
      // 🚀 Listen for incoming messages globally to update the unread count!
      SocketService().socket!.on('receiveMessage', (data) async {
        if (mounted) {
          print("🏠 HOME SCREEN HEARD A MESSAGE! Refreshing list...");
          _fetchData(); 

          // 🚀 3. Only show the notification if I am NOT the sender!
          if (data['sender'] != currentUser) {
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'chat_channel_id', 'Chat Messages',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            );
            const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
            
            // 🚀 FIX 2: Label every single parameter!
            await flutterLocalNotificationsPlugin.show(
              id: 0, 
              title: data['sender'].split('@')[0], 
              body: data['text'].startsWith('[IMAGE]') ? '📷 Sent a photo' : data['text'], 
              notificationDetails: platformDetails,
            );
          }
        }
      });
    });
  }

  Future<void> _fetchData() async {
    try {
      const String baseUrl = 'https://whatsapp-clone-backend-navv.onrender.com/chat/recent';
      
      // 🚀 THE FIX: Safely encode your full name so the URL doesn't crash on the space!
      String safeUser = Uri.encodeComponent(currentUser);

      final chatRes = await http.get(Uri.parse('$baseUrl/chat?user=$safeUser'));
      final groupRes = await http.get(Uri.parse('$baseUrl/group?user=$safeUser'));

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

  // 🚀 Fetch all registered users from your Neon database!
  Future<void> _showContactsList() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder(
          future: http.get(Uri.parse('https://whatsapp-clone-backend-navv.onrender.com/users')),
          builder: (context, AsyncSnapshot<http.Response> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
            }
            if (snapshot.hasError || snapshot.data?.statusCode != 200) {
              return const Center(child: Text("Could not load contacts."));
            }

            List<dynamic> users = jsonDecode(snapshot.data!.body);
            
            // 🚀 Filter out your own email so you don't chat with yourself!
            final myEmail = FirebaseAuth.instance.currentUser?.email;
            users = users.where((u) => u['email'] != myEmail).toList();

            if (users.isEmpty) {
              return const Center(child: Text("No friends have registered yet!", style: TextStyle(color: Colors.grey)));
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Select Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      // Use their Google name if they have one, otherwise use their email
                      final displayName = user['name'] ?? user['email'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF128C7E),
                          backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                          child: user['avatarUrl'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user['email']),
                        onTap: () {
                          // 1. Close the bottom sheet
                          Navigator.pop(context);
                          // 2. Open the Chat Screen with this exact user!
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(contactName: user['email'])),
                          ).then((_) => _fetchData()); // Refresh home screen when you come back
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF128C7E),
          foregroundColor: Colors.white,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _query = val),
                )
              : const Text('WhatsApp Clone', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _query = "";
                    _searchController.clear();
                  }
                });
              },
            ),
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
          onPressed: _showContactsList, // 🚀 Now it opens the cloud contact list!
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChatList(List<dynamic> data, {required bool isGroup}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
    if (data.isEmpty) return Center(child: Text(isGroup ? "No groups yet" : "No chats yet", style: const TextStyle(color: Colors.grey)));

    final filteredData = data.where((item) {
      final name = item['roomID'].toString().toLowerCase();
      return name.contains(_query.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final item = filteredData[index];
          String timeString = "";
          if (item["timestamp"] != null) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(item["timestamp"] as int);
            timeString = DateFormat('h:mm a').format(date);
          }

          // 🚀 Grab the unread count from your backend!
          final int unreadCount = item['unreadCount'] ?? 0;
          final chat = item; // alias so the exact snippet works!

          print("🔥 RAW DATA FROM BACKEND: $chat");

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isGroup ? const Color(0xFF128C7E) : Colors.grey.shade400,
              child: Icon(isGroup ? Icons.group : Icons.person, color: Colors.white),
            ),
            // 🚀 Use the real contactName from the database. 
            // If they haven't set a name yet, it will safely fall back to showing their email.
            title: Text(
              chat['contactName'] ?? chat['email'] ?? 'Unknown User', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            subtitle: Text(
              "${chat['contactName'] ?? chat['email']}: ${chat['text']}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            
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
              // 🚀 1. The "Senior Hack": Instantly hide the green circle locally!
              setState(() {
                item['unreadCount'] = 0; 
              });

              // 2. Open the chat
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contactName: isGroup ? item['roomID'].toString().replaceAll('Group:', '') : item['roomID'],
                  ),
                ),
              );
              
              // 3. When you return, silently fetch the new latest message text in the background
              _fetchData();
            },
          );
        },
      ),
    );
  }
}