import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  
  ChatMessage({required this.text, required this.sender, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel channel;
  final TextEditingController _messageController = TextEditingController();
  
  // 🚀 Variable name is 'messages'
  List<ChatMessage> messages = [];
  final String myName = "Lakshmi Mouna"; 
  
  bool _isTyping = false; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectToAWS();

    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _messageController.text.isNotEmpty;
        });
      }
    });
  }

  void _connectToAWS() async {
    final awsUrl = 'wss://rnb90nsph3.execute-api.ap-southeast-2.amazonaws.com/v2'; 
    channel = WebSocketChannel.connect(Uri.parse(awsUrl));

    await Future.delayed(const Duration(seconds: 2)); 

    if (!mounted) return;

    channel.sink.add(jsonEncode({
      "action": "getMessages",
      "room": widget.contactName
    }));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });

    channel.stream.listen((message) {
      if (!mounted) return;
      try {
        final data = jsonDecode(message);
        setState(() {
          if (data['type'] == 'history') {
            messages.clear();
            for (var msg in data['messages']) {
              String timeString = DateFormat('h:mm a').format(DateTime.now());
              if (msg['timestamp'] != null) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int);
                timeString = DateFormat('h:mm a').format(date);
              }
              
              messages.add(ChatMessage(
                text: msg['text'] ?? '',
                sender: msg['sender'] ?? '',
                isMe: msg['sender'] == myName || msg['sender'] == 'Lakshmi', 
                time: timeString,
              ));
            }
            _isLoading = false;
          } 
          else if (data['type'] == 'live') {
            if (data['room'] == widget.contactName) {
              String timeString = DateFormat('h:mm a').format(DateTime.now());
              if (data['timestamp'] != null) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
                timeString = DateFormat('h:mm a').format(date);
              }
              
              messages.add(ChatMessage(
                text: data['text'],
                sender: data['sender'],
                isMe: data['sender'] == myName || data['sender'] == 'Lakshmi', 
                time: timeString,
              ));
            }
          }
        });
      } catch (e) {
        print("🚨 JSON ERROR: $e");
      }
    }, onDone: () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      channel.sink.add(jsonEncode({
        "action": "sendMessage", 
        "room": widget.contactName,
        "text": text,
        "sender": myName,
      }));
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    channel.sink.close();
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
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)))
              : ListView.builder(
                  reverse: true, // 🚀 Starts the view at the bottom
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // 🚀 Since the list is reversed, we pick items from the end of the array
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