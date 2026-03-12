import { Controller, Post, Body, Get } from '@nestjs/common';
import { UsersService } from '../users/users.service'; // 🚀 FIXED: Removed the .ts extension

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // 🚀 Fetch contacts/users for your Home Screen
  @Get()
  async getAllUsers() {
    return this.usersService.getAllUsers();
  }

  // 🚀 Catch the FCM token from Flutter for push notifications
  @Post('save-token')
  async saveToken(@Body() body: { email: string; fcmToken: string }) {
    // We pass the exact email and token from the body to your service
    return this.usersService.saveToken(body.email, body.fcmToken);
  }

  // 🚀 Save the actual username from the Flutter pop-up
  @Post('update-name')
  async updateUsername(@Body() body: { email: string; username: string }) {
    return this.usersService.updateName(body.email, body.username);
  }
}