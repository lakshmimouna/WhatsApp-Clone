import { WebSocketGateway, SubscribeMessage, MessageBody, WebSocketServer, OnGatewayDisconnect, ConnectedSocket } from '@nestjs/websockets';
import { OnModuleInit } from '@nestjs/common'; // 🚀 This is the correct import!
import { Server, Socket } from 'socket.io';
import { UsersService } from '../users/users.service';
import { ChatService } from './chat.service';
import * as admin from 'firebase-admin';

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
    this.server.emit('receiveMessage', payload);

    try {
      await this.chatService.sendMessage(payload.sender, payload.roomID, payload.text);
    } catch (error) {
      console.error('🚨 Could not save message to database:', error);
    }

    try {
      const targetEmail = payload.roomID;
      const userToken = await this.usersService.getUserToken(targetEmail);

      if (userToken) {
        await admin.messaging().send({
          token: userToken,
          notification: {
            title: `New message from ${payload.sender}`,
            body: payload.text,
          },
          android: {
            priority: 'high',
            notification: { channelId: 'high_importance_channel' },
          },
        });
        console.log(`🔔 Push notification sent to ${targetEmail}!`);
      }
    } catch (error) {
      console.error('🚨 Firebase Notification Error:', error);
    }
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