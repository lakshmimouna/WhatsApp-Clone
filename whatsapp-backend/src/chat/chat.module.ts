import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { UsersService } from '../users/users.service'; // Make sure this is imported

@Module({
  controllers: [ChatController],
  // 🚀 If ChatGateway isn't in this providers array, WebSockets won't turn on!
  providers: [ChatGateway, ChatService, UsersService], 
})
export class ChatModule {}