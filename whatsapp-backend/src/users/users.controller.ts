import { Controller, Post, Body, Get } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // The route to fetch contacts for your Home Screen
  @Get()
  async getAllUsers() {
    return this.usersService.getAllUsers();
  }

  // The route that catches the token from Flutter
  @Post('save-token')
  async saveToken(@Body() body: { email: string; fcmToken: string }) {
    // We pass the exact email and token from the body to your service
    return this.usersService.saveToken(body.email, body.fcmToken);
  }
}