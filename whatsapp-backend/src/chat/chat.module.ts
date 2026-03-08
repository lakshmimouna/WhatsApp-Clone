import { Module } from '@nestjs/common';
import { ChatGateway } from './chat.gateway';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { UsersModule } from '../users/users.module'; // 🚀 Import the module

@Module({
  imports: [UsersModule], // 🚀 Add it here so ChatGateway can use UsersService
  controllers: [ChatController],
  providers: [ChatGateway, ChatService],
})
export class ChatModule {}