import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as admin from 'firebase-admin';
import { join } from 'path';
import WebSocket from 'ws';
import { UsersService } from './users/users.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Initialize Firebase Admin
  const serviceAccount = require(join(process.cwd(), 'firebase-key.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('🔥 Firebase Admin Initialized!');

  app.enableCors();

  // 2. Connect to AWS WebSocket as a Listener
  const awsUrl = 'wss://rnb90nsph3.execute-api.ap-southeast-2.amazonaws.com/v2/';
  const ws = new WebSocket(awsUrl);
  const usersService = app.get(UsersService);

  ws.on('open', () => {
    console.log('📡 NestJS connected to AWS WebSocket Listener!');
  });

  // 🚀 THE MAGIC TRIGGER: Fires when PieSocket (or another phone) sends a message
  ws.on('message', async (data) => {
    try {
      const payload = JSON.parse(data.toString());
      console.log('✉️ Caught message from AWS:', payload);

      // We only send a notification if the message has text
      if (payload.text) {
        const targetUser = "Lakshmi Mouna"; 
        const userToken = await usersService.getUserToken(targetUser);

        if (userToken) {
          await admin.messaging().send({
            token: userToken,
            notification: {
              title: `New Message from ${payload.sender || 'WhatsApp Clone'}`,
              body: payload.text,
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'high_importance_channel',
              },
            },
          });
          console.log(`🔔 SUCCESS: Push notification sent to ${targetUser}!`);
        } else {
          console.log(`🔕 No FCM token found in DynamoDB for ${targetUser}`);
        }
      }
    } catch (error) {
      console.error('🚨 WebSocket Message Error:', error);
    }
  });

  ws.on('error', (err) => {
    console.error('📡 AWS WebSocket Error:', err);
  });

  // Reconnect if the connection drops
  ws.on('close', () => {
    console.log('📡 AWS Connection closed. Please restart server to reconnect.');
  });

await app.listen(process.env.PORT || 3000, '0.0.0.0');
console.log('🚀 Backend is running on: https://whatsapp-clone-backend-navv.onrender.com');
}
bootstrap();