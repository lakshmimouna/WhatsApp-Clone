import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🚀 Added Provider
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:swipe_to/swipe_to.dart';
import '../services/socket_service.dart'; 
import '../providers/chat_provider.dart'; // 🚀 Added ChatProvider

class ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  bool isRead; 
  
  ChatMessage({required this.text, required this.sender, required this.isMe, required this.time, this.isRead = false});
}

class ChatScreen extends StatefulWidget {
  final String receiverEmail; 
  final String receiverName; 
  const ChatScreen({super.key, required this.receiverEmail, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode(); // 🚀 1. Keep keyboard open focus node
  
  List<dynamic> messages = [];
  
  // 🚀 myEmail is now instantly available!
  late String myEmail;
  
  bool _isTyping = false; 
  bool _isLoading = true;
  bool _isPeerTyping = false; 
  dynamic _replyingTo; 
  String _peerStatus = "Offline"; 

  Function(dynamic)? _messageHandler;

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  void initState() {
    super.initState();
    
    // 🚀 Instantly grab the email from the Brain—no waiting for Secure Storage!
    myEmail = Provider.of<ChatProvider>(context, listen: false).currentUser;

    _fetchHistory();
    _listenForNewMessages();

    final globalSocket = SocketService().socket!;

    globalSocket.emit('markAsRead', {
      "reader": myEmail,
      "roomID": widget.receiverEmail
    });

    globalSocket.on('userStatusChanged', (data) {
      if (mounted && data['email'] == widget.receiverEmail) {
        setState(() {
          _peerStatus = data['status'];
        });
      }
    });

    // Listen for the read receipt from the other user
    globalSocket.on('messagesRead', (data) {
      if (mounted) {
        setState(() {
          // Loop through all messages on the screen and turn them blue
          for (var msg in messages) {
            msg['isRead'] = true;
          }
        });
      }
    });

    _messageController.addListener(() {
      if (mounted) {
        bool typingNow = _messageController.text.isNotEmpty;
        
        // 🚀 THE FIX: ONLY rebuild the screen if the typing status ACTUALLY changes!
        // This stops the screen from refreshing on every single letter you type or when you hit send.
        if (_isTyping != typingNow) {
          setState(() {
            _isTyping = typingNow;
          });
          
          SocketService().socket!.emit('typing', {
            "roomID": widget.receiverEmail,
            "sender": myEmail,
            "isTyping": typingNow,
          });
        }
      }
    });
  }

  void _listenForNewMessages() {
    final socket = SocketService().socket!;
    _messageHandler = (data) {
      if (mounted && data['sender'] == widget.receiverEmail) {
        setState(() {
          messages.add({
            "text": data['text'],
            "sender": data['sender'],
            "timestamp": data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            "isRead": false,
          });
        });
      }
    };
    socket.on('receiveMessage', _messageHandler!);
  }

  Future<void> _fetchHistory() async {
    final safeMe = Uri.encodeComponent(myEmail);
    final safeThem = Uri.encodeComponent(widget.receiverEmail);
    final url = Uri.parse(
        'https://whatsapp-clone-backend-navv.onrender.com/chat/history?user1=$safeMe&user2=$safeThem');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            messages = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("🚨 Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    final messagePayload = {
      "text": messageText,
      "sender": myEmail,
      "roomID": widget.receiverEmail, 
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      // 🚀 ADD THESE TWO LINES TO CATCH THE REPLY
      "replyToText": _replyingTo != null ? _replyingTo!['text'] : null,
      "replyToSender": _replyingTo != null ? _replyingTo!['sender'] : null,
    };

    setState(() {
      messages.add(messagePayload);
      _messageController.clear();
      _isTyping = false;
      _replyingTo = null; // Clear the reply preview after sending
    });

    SocketService().socket!.emit('sendMessage', messagePayload);
    
    // 🚀 3. Force the keyboard to stay open!
    _messageFocusNode.requestFocus(); 
  }

  @override
  void dispose() {
    final globalSocket = SocketService().socket;
    if (globalSocket != null && _messageHandler != null) {
      globalSocket.off('receiveMessage', _messageHandler);
      globalSocket.off('userStatusChanged'); 
    }
    _messageController.dispose();
    _messageFocusNode.dispose();
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
            Text(widget.receiverName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _isPeerTyping ? "typing..." : _peerStatus, 
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
                    
                    String formattedTime = "";
                    if (message['timestamp'] != null) {
                      DateTime date = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
                      formattedTime = DateFormat('h:mm a').format(date);
                    }

                    return SwipeTo(
                      onRightSwipe: (details) {
                        setState(() => _replyingTo = message);
                      },
                      child: _buildMessageBubble(
                        message['text'] ?? "", 
                        formattedTime, 
                        message['sender'] == myEmail, 
                        message['isRead'] ?? false,
                        // 🚀 ADD THESE TWO VARIABLES
                        message['replyToText'],
                        message['replyToSender'],
                      ),
                    );
                  },
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe, bool isRead, String? replyText, String? replySender) {
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1))], // Added slight shadow for a cleaner look
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 🚀 THE QUOTED MESSAGE BOX
            if (replyText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: Color(0xFF128C7E), width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replySender == myEmail ? "You" : widget.receiverName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF128C7E), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      replyText.startsWith('[IMAGE]') ? '📷 Photo' : replyText,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // YOUR EXISTING MESSAGE CONTENT (Image or Text)
            if (isImage)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: InteractiveViewer( 
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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image == null) return; 

    setState(() => _isLoading = true);

    try {
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

        SocketService().socket!.emit('sendMessage', {
          "roomID": widget.receiverEmail, 
          "text": "[IMAGE]$imageUrl", 
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
          Container(width: 4, height: 40, color: const Color(0xFF128C7E)), 
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!['sender'] == myEmail ? "You" : widget.receiverName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF128C7E))
                ),
                Text(
                  _replyingTo!['text'].toString().startsWith('[IMAGE]') ? '📷 Photo' : _replyingTo!['text'], 
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
        if (_replyingTo != null) _buildReplyPreview(), 
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF128C7E)), onPressed: _pickAndSendImage),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode, // 🚀 2. Attach it here!
                  textCapitalization: TextCapitalization.sentences, 
                  decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: Icon(_isTyping ? Icons.send : Icons.mic, color: const Color(0xFF128C7E)),
                onPressed: () {
                  if (_isTyping) {
                    _sendMessage();
                    _cancelReply(); 
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