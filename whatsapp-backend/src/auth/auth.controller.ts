import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('google')
  async googleLogin(@Body('accessToken') accessToken: string) {
    console.log('Received token from Flutter!');
    
    // We make sure this exactly matches the function name in your service!
    return this.authService.authenticateWithGoogle(accessToken);
  }
}