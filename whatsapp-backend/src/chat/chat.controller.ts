import { Controller, Get, Param, Query } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('recent/:type')
  async getRecent(@Param('type') type: 'chat' | 'group', @Query('user') user: string) {
    return this.chatService.getRecentItems(type, user);
  }

  // 🚀 ADD THIS NEW ROUTE
  @Get('history')
  async getHistory(@Query('user1') user1: string, @Query('user2') user2: string) {
    return this.chatService.getChatHistory(user1, user2);
  }
}