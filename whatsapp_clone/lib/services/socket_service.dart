/* * ARCHITECTURE: SOCKET SERVICE (Singleton Pattern)
 * This file maintains a single, persistent WebSocket connection to the NestJS backend.
 * By using a Singleton, we ensure the app doesn't open multiple connections 
 * if the user navigates between different screens. It listens for 'receiveMessage' 
 * globally to trigger background local notifications.
 */
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Singleton pattern so the same socket is shared everywhere
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  String? currentUserEmail;

  void connect(String email) {
    if (socket != null && socket!.connected) return; // Don't reconnect if already connected
    
    currentUserEmail = email;

    // Change it to exactly this:
    socket = IO.io('https://whatsapp-clone-backend-navv.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('🌍 GLOBAL SOCKET IS LIVE!');
      socket!.emit('goOnline', currentUserEmail);
    });

    socket!.onDisconnect((_) {
      print('🚨 GLOBAL SOCKET DISCONNECTED.');
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
