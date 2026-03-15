/*
 * ARCHITECTURE: WEBSOCKET GATEWAY
 * This file acts as the real-time server. It listens for incoming 'sendMessage' 
 * events from the Flutter client. Once received, it does two things simultaneously:
 * 1. Emits the message to the receiver's specific Socket room for real-time delivery.
 * 2. Passes the payload to the ChatService to be permanently saved in the database.
 */
import { WebSocketGateway, SubscribeMessage, MessageBody, WebSocketServer, OnGatewayDisconnect, ConnectedSocket } from '@nestjs/websockets';
import { OnModuleInit } from '@nestjs/common'; 
import { Server, Socket } from 'socket.io';
import { UsersService } from '../users/users.service';
import { ChatService } from './chat.service';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class ChatGateway implements OnModuleInit, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  // 🚀 Track who is online (Socket ID -> Email)
  private activeUsers = new Map<string, string>(); 

  constructor(
    private readonly usersService: UsersService,
    private readonly chatService: ChatService
  ) { }

  // 🚀 The Heartbeat!
  onModuleInit() {
    console.log('✅ WEBSOCKET GATEWAY IS ALIVE AND LISTENING!');
  }

  // 🚀 1. When a user opens the app, they tell the server they are online
  @SubscribeMessage('goOnline')
  handleGoOnline(@MessageBody() email: string, @ConnectedSocket() client: Socket) {
    this.activeUsers.set(client.id, email);
    // Broadcast to everyone that this user is online
    this.server.emit('userStatusChanged', { email: email, status: 'Online' });
  }

  // 🚀 2. When they close the app, Socket.io automatically fires this
  handleDisconnect(client: Socket) {
    const email = this.activeUsers.get(client.id);
    if (email) {
      this.activeUsers.delete(client.id);
      // Tell everyone they left, with a timestamp
      const timeString = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      this.server.emit('userStatusChanged', { email: email, status: `last seen today at ${timeString}` });
    }
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(@MessageBody() payload: { sender: string; roomID: string; text: string }) {
    console.log('✉️ Message received:', payload);
    
    // 🚀 We broadcast the message via the socket. 
    // The Flutter app will hear this and trigger a "Local Notification" if they are outside the chat!
    this.server.emit('receiveMessage', payload);

    try {
      await this.chatService.sendMessage(payload.sender, payload.roomID, payload.text);
    } catch (error) {
      console.error('🚨 Could not save message to database:', error);
    }
    
    // 🚀 Notice: All Firebase/FCM logic has been completely removed from here!
  }

  @SubscribeMessage('typing')
  handleTyping(@MessageBody() payload: { sender: string; roomID: string; isTyping: boolean }) {
    // Broadcast the typing status to the other person in the room
    this.server.emit('displayTyping', payload);
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(@MessageBody() payload: { reader: string; roomID: string }) {
    // 1. Update the database
    await this.chatService.markRoomAsRead(payload.roomID, payload.reader);
    
    // 2. Tell the sender's phone to turn their gray ticks BLUE!
    this.server.emit('messagesRead', { reader: payload.reader, roomID: payload.roomID });
  }
}