import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { UsersModule } from './users/users.module';
import { JwtModule } from '@nestjs/jwt'; // 🚀 Added for Custom Auth

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    ChatModule,
    UsersModule,
    // 🚀 Register JWT Globally
    JwtModule.register({
      global: true,
      secret: 'BUSYBRAINS_SECRET_KEY', // The key used to encrypt the token
      signOptions: { expiresIn: '30d' }, // The token keeps them logged in for 30 days
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}