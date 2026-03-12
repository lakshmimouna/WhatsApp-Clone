import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:swipe_to/swipe_to.dart'; // 🚀 Add this import
import '../services/socket_service.dart'; // Add this import

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  bool isRead; // 🚀 No longer final!
  
  ChatMessage({required this.text, required this.sender, required this.isMe, required this.time, this.isRead = false});
}

class ChatScreen extends StatefulWidget {
  final String contactName; // This is the OTHER person's email
  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  List<ChatMessage> messages = [];
  
  String get myEmail {
    return FirebaseAuth.instance.currentUser?.email ?? "Guest User";
  }
  
  bool _isTyping = false; 
  bool _isLoading = true;
  bool _isPeerTyping = false; // To track if the other person is typing
  ChatMessage? _replyingTo; // Remembers the swiped message
  String _peerStatus = "Offline"; // Defaults to offline until the server says otherwise

  // 🚀 This specific variable remembers our Chat Screen's ear!
  Function(dynamic)? _messageHandler;

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory(); // 🚀 Fetch old messages first!

    // 🚀 1. Attach to the Global Socket
    final globalSocket = SocketService().socket!;

    // 🚀 2. Tell the server we are looking at this chat
    globalSocket.emit('markAsRead', {
      "reader": myEmail,
      "roomID": widget.contactName
    });

    // 🚀 1. Define exactly what this screen should do when it hears a message
    _messageHandler = (data) {
      print("🔥 CHAT SCREEN HEARD MESSAGE 2+: ${data['text']}"); // Proof it works!
      
      if (!mounted) return;
      if ((data['roomID'] == widget.contactName && data['sender'] == myEmail) || 
          (data['roomID'] == myEmail && data['sender'] == widget.contactName)) {
        setState(() {
          messages.insert(0, ChatMessage( // Change to .add() if your list is upside down
            text: data['text'],
            sender: data['sender'],
            isMe: data['sender'] == myEmail,
            time: TimeOfDay.now().format(context),
            isRead: false, 
          ));
        });
      }
    };

    // 🚀 2. Attach the specific ear to the socket
    globalSocket.on('receiveMessage', _messageHandler!);

    // 🚀 4. Listen for Online Status
    globalSocket.on('userStatusChanged', (data) {
      if (mounted && data['email'] == widget.contactName) {
        setState(() {
          _peerStatus = data['status'];
        });
      }
    });

    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _messageController.text.isNotEmpty;
        });
        // 🚀 Emit typing status to the server
        SocketService().socket!.emit('typing', {
          "roomID": widget.contactName,
          "sender": myEmail,
          "isTyping": _messageController.text.isNotEmpty,
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
                isRead: msg['isRead'] ?? false,
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

  // Deleted _connectToRender()

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final textToSend = _messageController.text;
    _messageController.clear();
    setState(() => _isTyping = false);

    // 🚀 1. INSTANTLY draw it on YOUR screen so it feels fast!
    setState(() {
      messages.insert(0, ChatMessage( // Change to messages.add(...) if your screen is upside down
        text: textToSend,
        sender: myEmail,
        isMe: true,
        time: TimeOfDay.now().format(context),
        isRead: false,
      ));
    });

    // 2. Send it to the cloud for the other person
    SocketService().socket!.emit('sendMessage', {
      "roomID": widget.contactName,
      "text": textToSend,
      "sender": myEmail,
    });
  }

  // 🚀 IMPORTANT: Clean up the listeners when you leave the chat screen!
  @override
  void dispose() {
    final globalSocket = SocketService().socket;
    if (globalSocket != null && _messageHandler != null) {
      // 🚀 3. Remove ONLY this screen's ear! The Home Screen stays alive.
      globalSocket.off('receiveMessage', _messageHandler);
      globalSocket.off('userStatusChanged'); // Leave this general drop since home screen doesn't use it
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName.split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _isPeerTyping ? "typing..." : _peerStatus, // 🚀 Shows typing, Online, or Last Seen!
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
                    return SwipeTo(
                      onRightSwipe: (details) {
                        setState(() => _replyingTo = message);
                      },
                      child: _buildMessageBubble(message.text, message.time, message.isMe, message.isRead),
                    );
                  },
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe, bool isRead) {
    // 1. Check if it's an image
    bool isImage = text.startsWith('[IMAGE]');
    String imageUrl = isImage ? text.replaceAll('[IMAGE]', '') : '';

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
            
            // 2. Draw the Image OR the Text
            if (isImage)
              GestureDetector(
                // 🚀 3. Make the image clickable to open full-screen!
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: InteractiveViewer( // Allows pinching and zooming!
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 200, height: 200, 
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)))
                      );
                    },
                  ),
                ),
              )
            else
              Text(text, style: const TextStyle(fontSize: 16)),
            
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 14, color: isRead ? Colors.blue : Colors.grey),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    // 1. Pick an image from the gallery (compressed to save data)
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return; // The user canceled picking an image

    // Show the loading spinner while it uploads
    setState(() => _isLoading = true);

    try {
      // 🚀 2. THE SHORTCUT: Upload to ImgBB's free API
      const String imgbbApiKey = 'c78e4b02ab9842b6bc7a08916d3c2666'; 
      
      final File file = File(image.path);
      final request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (jsonResponse['success'] == true) {
        final String imageUrl = jsonResponse['data']['url'];
        print('✅ Image uploaded successfully: $imageUrl');

        // 🚀 3. Send the Image URL through your NestJS WebSocket!
        SocketService().socket!.emit('sendMessage', {
          "roomID": widget.contactName,
          "text": "[IMAGE]$imageUrl", // Our special tag!
          "sender": myEmail,
        });
      } else {
        print("🚨 ImgBB Upload Failed: ${jsonResponse['error']['message']}");
      }
    } catch (e) {
      print("🚨 Image Upload Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: const Color(0xFF128C7E)), // WhatsApp green line
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!.isMe ? "You" : widget.contactName.split('@')[0], 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF128C7E))
                ),
                Text(
                  _replyingTo!.text.startsWith('[IMAGE]') ? '📷 Photo' : _replyingTo!.text, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null) _buildReplyPreview(), // 🚀 Pops up when swiped!
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF128C7E)), onPressed: _pickAndSendImage),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  // 🚀 ADD THIS LINE: Forces the keyboard to capitalize the first letter of sentences!
                  textCapitalization: TextCapitalization.sentences, 
                  decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: Icon(_isTyping ? Icons.send : Icons.mic, color: const Color(0xFF128C7E)),
                onPressed: () {
                  if (_isTyping) {
                    _sendMessage();
                    _cancelReply(); // 🚀 Clear the reply box after sending!
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}