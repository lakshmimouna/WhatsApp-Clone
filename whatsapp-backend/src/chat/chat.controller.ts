import { Controller, Get, Query, Post, Body } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  // 🚀 1. Fetch recent chats for your Home Screen
  @Get('recent')
  async getRecent(
    @Query('type') type: 'chat' | 'group', 
    @Query('email') email: string
  ) {
    return this.chatService.getRecentItems(type, email);
  }

  // 🚀 2. Fetch the old message history when opening a chat
  @Get('history')
  async getHistory(
    @Query('user1') user1Email: string, 
    @Query('user2') user2Email: string
  ) {
    return this.chatService.getChatHistory(user1Email, user2Email);
  }

  // 🚀 3. Mark messages as read when the user opens the chat
  @Post('read')
  async markAsRead(@Body() body: { roomID: string; email: string }) {
    return this.chatService.markRoomAsRead(body.roomID, body.email);
  }
}