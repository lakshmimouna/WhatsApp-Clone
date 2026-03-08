import { Controller, Get, Param, Query } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('recent/:type')
  async getRecent(@Param('type') type: 'chat' | 'group', @Query('user') user: string) {
    return this.chatService.getRecentItems(type, user);
  }

  // 🚀 THE ERASER DOOR: Flutter will hit this URL to clear the green circle
  @Get('mark-read/:roomID')
  async markRead(@Param('roomID') roomID: string, @Query('user') user: string) {
    return this.chatService.markRoomAsRead(roomID, user);
  }
}