import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  
  ChatMessage({required this.text, required this.sender, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String contactName; // This is the OTHER person's email
  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  
  List<ChatMessage> messages = [];
  
  String get myEmail {
    return FirebaseAuth.instance.currentUser?.email ?? "Guest User";
  }
  
  bool _isTyping = false; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory(); // 🚀 Fetch old messages first!
    _connectToRender(); // Then connect to live sockets

    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _messageController.text.isNotEmpty;
        });
      }
    });
  }

  // 🚀 GRAB OLD MESSAGES FROM NEON DATABASE
  Future<void> _fetchHistory() async {
    try {
      final safeMe = Uri.encodeComponent(myEmail);
      final safeThem = Uri.encodeComponent(widget.contactName);
      final url = Uri.parse('https://whatsapp-clone-backend-navv.onrender.com/chat/history?user1=$safeMe&user2=$safeThem');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            messages = historyData.map((msg) {
              DateTime date = DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
              String timeString = DateFormat('h:mm a').format(date);
              
              return ChatMessage(
                text: msg['text'],
                sender: msg['sender'],
                isMe: msg['sender'] == myEmail,
                time: timeString,
              );
            }).toList();
            
            _isLoading = false; // Stop the spinner!
          });
        }
      }
    } catch (e) {
      print('🚨 Error fetching history: $e');
      if (mounted) setState(() => _isLoading = false); // Stop spinner even if error
    }
  }

  void _connectToRender() {
    // 🚀 Clean, standard connection. No forced paths or extra headers.
    socket = IO.io('https://whatsapp-clone-backend-navv.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('✅ CONNECTED TO RENDER SOCKET!');
      if (mounted) setState(() => _isLoading = false);
    });

    socket.onConnectError((error) {
      print('🚨 SOCKET ERROR: $error');
      if (mounted) setState(() => _isLoading = false);
    });

    socket.onDisconnect((_) {
      print('⚠️ SOCKET DISCONNECTED');
    });

    socket.on('receiveMessage', (data) {
      if (!mounted) return;
      if ((data['sender'] == myEmail && data['roomID'] == widget.contactName) ||
          (data['sender'] == widget.contactName && data['roomID'] == myEmail)) {
        
        String timeString = DateFormat('h:mm a').format(DateTime.now());
        setState(() {
          messages.add(ChatMessage(
            text: data['text'],
            sender: data['sender'],
            isMe: data['sender'] == myEmail, 
            time: timeString,
          ));
        });
      }
    });

    socket.connect();
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // 🚀 3. SEND THE MESSAGE TO NESTJS (Which saves it to Neon & fires FCM!)
      socket.emit('sendMessage', {
        "roomID": widget.contactName, 
        "text": text,
        "sender": myEmail,
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        title: Text(widget.contactName.split('@')[0]), // Shows name instead of full email
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)))
              : ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index]; 
                    return _buildMessageBubble(message.text, message.time, message.isMe);
                  },
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
            ),
          ),
          IconButton(
            icon: Icon(_isTyping ? Icons.send : Icons.mic, color: const Color(0xFF128C7E)),
            onPressed: () => _isTyping ? _sendMessage() : null,
          ),
        ],
      ),
    );
  }
}