import { WebSocketGateway, SubscribeMessage, MessageBody, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { UsersService } from '../users/users.service'; // 🚀 Import the service
import * as admin from 'firebase-admin';

@WebSocketGateway({
  cors: { origin: '*' },
  // 🚀 Add your AWS URL here so NestJS listens to it!
  path: 'wss://rnb90nsph3.execute-api.ap-southeast-2.amazonaws.com/v2' 
})
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  constructor(private readonly usersService: UsersService) {} // 🚀 Inject service here

  @SubscribeMessage('sendMessage')
  async handleMessage(@MessageBody() payload: any) {
    console.log('✉️ Message received:', payload);

    // 1. Broadcast message to everyone in the room (Flutter UI updates)
    this.server.emit('receiveMessage', payload);

    // 2. Trigger Push Notification logic
    try {
      // For testing, we send a notification to "Lakshmi Mouna" 
      // In a real app, this would be the 'receiver' name
      const targetUser = "Lakshmi Mouna"; 
      
      const userToken = await this.usersService.getUserToken(targetUser);

      if (userToken) {
        await admin.messaging().send({
          token: userToken,
          notification: {
            title: `Message from ${payload.sender}`,
            body: payload.text,
          },
          // 🚀 This makes the notification pop up even if the app is in background
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel', 
            },
          },
        });
        console.log(`🔔 Push notification sent to ${targetUser}!`);
      } else {
        console.log(`🔕 No FCM token found for ${targetUser}`);
      }
    } catch (error) {
      console.error('🚨 Firebase Notification Error:', error);
    }
  }
}