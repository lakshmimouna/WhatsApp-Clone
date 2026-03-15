import { Controller, Post, Body, Get } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // Fetch contacts for your Home Screen
  @Get()
  async getAllUsers() {
    return this.usersService.getAllUsers();
  }

  @Post('update-name')
  async updateUsername(@Body() body: { email: string; username: string }) {
    return this.usersService.updateName(body.email, body.username);
  }

  // 🚀 NEW: Custom Signup Route
  @Post('signup')
  async signup(@Body() body: { email: string; password: string; name?: string }) {
    return this.usersService.signup(body.email, body.password, body.name);
  }

  // 🚀 NEW: Custom Login Route (Generates the JWT)
  @Post('login')
  async login(@Body() body: { email: string; password: string }) {
    return this.usersService.login(body.email, body.password);
  }
}