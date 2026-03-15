import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/socket_service.dart'; 
import '../providers/chat_provider.dart'; 
import 'chat_screen.dart';
import 'onboarding_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String _query = "";
  List<dynamic> _recentGroups = []; 

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
    );

    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      await chatProvider.loadUser();
      await chatProvider.fetchRecentChats();
      
      SocketService().connect(chatProvider.currentUser); 
      
      SocketService().socket!.on('receiveMessage', (data) async {
        if (mounted) {
          print("🏠 HOME SCREEN HEARD A MESSAGE! Updating single chat via Provider...");
          chatProvider.updateSingleChat(data);

          if (data['sender'] != chatProvider.currentUser) {
            String senderEmail = data['sender'];
            String senderName = senderEmail; // Default to email just in case

            // Look up the real name from your existing chat list
            try {
              var matchingChat = chatProvider.recentChats.firstWhere((chat) => chat['email'] == senderEmail || chat['roomID'] == senderEmail);
              if (matchingChat != null && matchingChat['contactName'] != null) {
                senderName = matchingChat['contactName']; // We found the name!
              }
            } catch (e) {
              // If it fails, it just falls back to showing the email
            }

            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'chat_channel_id', 'Chat Messages',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            );
            const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
            
            await flutterLocalNotificationsPlugin.show(
              id: 0, 
              title: senderName, 
              body: data['text'].startsWith('[IMAGE]') ? '📷 Sent a photo' : data['text'], 
              notificationDetails: platformDetails,
            );
          }
        }
      });
    });
  }

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
            
            final myEmail = Provider.of<ChatProvider>(context, listen: false).currentUser;
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
                          // 🚀 FIX: Grab the brain BEFORE closing the bottom sheet!
                          final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(
                              receiverEmail: user['email'],
                              receiverName: displayName,
                            )),
                          ).then((_) {
                            // 🚀 FIX: Safely use the saved brain reference!
                            chatProvider.fetchRecentChats();
                          }); 
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
                final userEmail = Provider.of<ChatProvider>(context, listen: false).currentUser;
                
                if (userEmail.isNotEmpty && userEmail != "Guest User") {
                  try {
                    await http.post(
                      Uri.parse('https://whatsapp-clone-backend-navv.onrender.com/users/clear-token'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({"email": userEmail}),
                    );
                  } catch (e) {
                    print("Failed to clear token: $e");
                  }
                }

                const storage = FlutterSecureStorage();
                await storage.deleteAll();
                
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
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return _buildChatList(chatProvider.recentChats, chatProvider.isLoadingChats, isGroup: false);
              },
            ),
            _buildChatList(_recentGroups, false, isGroup: true),
            const Center(child: Text("Calls Under Construction", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<dynamic> data, bool isLoading, {required bool isGroup}) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)));
    if (data.isEmpty) return Center(child: Text(isGroup ? "No groups yet" : "No chats yet", style: const TextStyle(color: Colors.grey)));

    final filteredData = data.where((item) {
      final name = item['roomID'].toString().toLowerCase();
      return name.contains(_query.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        Provider.of<ChatProvider>(context, listen: false).fetchRecentChats();
      },
      child: ListView.builder(
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final item = filteredData[index];
          String timeString = "";
          if (item["timestamp"] != null) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(item["timestamp"] as int);
            timeString = DateFormat('h:mm a').format(date);
          }

          final int unreadCount = item['unreadCount'] ?? 0;
          final chat = item; 

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isGroup ? const Color(0xFF128C7E) : Colors.grey.shade400,
              child: Icon(isGroup ? Icons.group : Icons.person, color: Colors.white),
            ),
            title: Text(
              chat['contactName'] ?? chat['roomID'] ?? chat['email'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "${chat['senderName'] ?? ''}: ${chat['text']}".replaceAll(RegExp(r'^: '), '').replaceAll(': Tap to start chatting', 'Tap to start chatting'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
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
              // 🚀 FIX: Grab the brain BEFORE the async gap!
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              
              chatProvider.clearUnreadCount(index);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverEmail: chat['email'] ?? chat['roomID'], 
                    receiverName: chat['contactName'] ?? chat['email'] ?? chat['roomID'], 
                  ),
                ),
              );
              
              // 🚀 FIX: Safely refresh silently when returning
              if (mounted) {
                chatProvider.fetchRecentChats();
              }
            },
          );
        },
      ),
    );
  }
}