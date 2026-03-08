import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service'; 

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async authenticateWithGoogle(accessToken: string) {
    try {
      console.log("DEBUG: Verifying Google Access Token...");

      // 1. Ask Google who this token belongs to
      const response = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${accessToken}`);
      const payload = await response.json();

      if (!response.ok) {
        throw new UnauthorizedException('Invalid Google Token');
      }

      // Grab 'sub' (which is the Google ID), email, name, and picture
      const { sub: googleId, email, name, picture: avatarUrl } = payload;
      console.log(`DEBUG: Google verified user: ${email}`);

      // 2. Database Operation: Find or Create User
      const user = await this.prisma.user.upsert({
        where: { email: email },
        update: { 
          name: name,
          avatarUrl: avatarUrl 
        },
        create: {
          googleId: googleId, // Added this line to satisfy your Prisma schema!
          email: email,
          name: name,
          avatarUrl: avatarUrl,
        },
      });

      // 3. Create a secure JWT session token
      const jwtToken = this.jwtService.sign({ userId: user.id });

      console.log(`SUCCESS: ${user.name} logged in successfully!`);
      
      return { 
        user, 
        accessToken: jwtToken 
      };
      
    } catch (error) {
      console.error("AUTH SERVICE ERROR:", error.message);
      throw new UnauthorizedException(error.message);
    }
  }
}