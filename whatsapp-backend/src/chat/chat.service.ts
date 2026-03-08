import { Injectable } from '@nestjs/common';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand, PutCommand } from '@aws-sdk/lib-dynamodb';

@Injectable()
export class ChatService {
  private docClient: DynamoDBDocumentClient;

  constructor() {
    const client = new DynamoDBClient({ 
      region: 'ap-southeast-2',
      credentials: {
        accessKeyId: 'AKIASU63Z2FZZGMKTUOW', 
        secretAccessKey: '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'
      }
    });
    this.docClient = DynamoDBDocumentClient.from(client);
  }

  async getRecentItems(type: 'chat' | 'group', currentUser: string) {
    try {
      const command = new ScanCommand({ TableName: 'WhatsAppMessages' });
      const response = await this.docClient.send(command);
      const messages = response.Items || [];

      const rooms = {};
      messages.forEach((msg) => {
        if (!msg.roomID) return; 
        
        const isGroupMsg = msg.roomID.startsWith('Group:');
        
        if ((type === 'group' && isGroupMsg) || (type === 'chat' && !isGroupMsg)) {
          if (!rooms[msg.roomID]) {
            rooms[msg.roomID] = { latestMessage: msg, unreadCount: 0 };
          }
          if (msg.timestamp > rooms[msg.roomID].latestMessage.timestamp) {
            rooms[msg.roomID].latestMessage = msg;
          }
          if (msg.sender !== currentUser && msg.isRead !== true) {
            rooms[msg.roomID].unreadCount += 1;
          }
        }
      });

      return Object.values(rooms).map((r: any) => ({
        ...r.latestMessage,
        unreadCount: r.unreadCount
      })).sort((a: any, b: any) => b.timestamp - a.timestamp);
    } catch (error) {
      console.error(`🚨 Error fetching ${type}s:`, error);
      return [];
    }
  }

  // 🚀 THE ERASER LOGIC: Finds unread messages and updates DynamoDB!
  async markRoomAsRead(roomID: string, currentUser: string) {
    try {
      const command = new ScanCommand({ TableName: 'WhatsAppMessages' });
      const response = await this.docClient.send(command);
      const messages = response.Items || [];

      for (const msg of messages) {
        // If it's the right room, sent by someone else, and not read yet...
        if (msg.roomID === roomID && msg.sender !== currentUser && msg.isRead !== true) {
          msg.isRead = true; // Mark it!
          
          // Save it back to DynamoDB
          await this.docClient.send(new PutCommand({
            TableName: 'WhatsAppMessages',
            Item: msg
          }));
        }
      }
      return { success: true };
    } catch (error) {
      console.error('🚨 Error marking as read:', error);
      return { success: false };
    }
  }
}