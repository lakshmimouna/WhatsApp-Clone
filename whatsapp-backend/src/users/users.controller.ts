import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('save-token')
  async saveToken(@Body() body: { userName: string; fcmToken: string }) {
    if (!body.userName || !body.fcmToken) {
      throw new HttpException('Missing userName or fcmToken', HttpStatus.BAD_REQUEST);
    }

    try {
      await this.usersService.saveUserToken(body.userName, body.fcmToken);
      return { success: true, message: `Token saved for ${body.userName}` };
    } catch (error) {
      throw new HttpException('Failed to save token to AWS', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
}