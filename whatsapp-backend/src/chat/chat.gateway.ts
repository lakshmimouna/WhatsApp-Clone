import { WebSocketGateway, SubscribeMessage, MessageBody, WebSocketServer } from '@nestjs/websockets';
import { OnModuleInit } from '@nestjs/common'; // 🚀 This is the correct import!
import { Server } from 'socket.io';
import { UsersService } from '../users/users.service';
import { ChatService } from './chat.service';
import * as admin from 'firebase-admin';

@WebSocketGateway({
  cors: { origin: '*' },
})
export class ChatGateway implements OnModuleInit {
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly usersService: UsersService,
    private readonly chatService: ChatService
  ) { }

  // 🚀 The Heartbeat!
  onModuleInit() {
    console.log('✅ WEBSOCKET GATEWAY IS ALIVE AND LISTENING!');
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
}