import { Module } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import { UsersModule } from '../users/users.module'; // 🚀 1. Import it here

@Module({
  imports: [UsersModule], // 🚀 2. Add it to the imports array
  controllers: [ChatController],
  providers: [ChatService, ChatGateway], 
})
export class ChatModule {}