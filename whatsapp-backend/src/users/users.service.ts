import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class UsersService {
  private prisma = new PrismaClient();
  
  // 🚀 Inject JWT Service to create tokens
  constructor(private jwtService: JwtService) {}

  // 1. Fetch all users for the Contact List
  async getAllUsers() {
    try {
      return await this.prisma.user.findMany({
        select: {
          id: true,
          name: true,
          email: true,
          avatarUrl: true,
          // Removed fcmToken
        },
      });
    } catch (error) {
      console.error('Error fetching users:', error);
      return [];
    }
  }

  async updateName(email: string, newName: string) {
    const updatedUser = await this.prisma.user.update({
      where: { email: email },
      data: { name: newName },
    });
    return { success: true, user: updatedUser };
  }

  // 🚀 2. Signup Logic: Encrypts the password before saving to the database
  async signup(email: string, pass: string, name?: string) {
    // Hash the password with a salt round of 10
    const hashedPassword = await bcrypt.hash(pass, 10);
    
    try {
      const newUser = await this.prisma.user.create({
        data: {
          email: email,
          password: hashedPassword,
          name: name || '',
        },
      });
      return { success: true, message: 'User created successfully' };
    } catch (error) {
      throw new Error('User already exists or database error');
    }
  }

  // 🚀 3. Login Logic: Verifies password and issues a JSON Web Token
  async login(email: string, pass: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Compare the plain text password with the hashed password in the DB
    const isPasswordValid = await bcrypt.compare(pass, user.password);
    
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Create the digital ID card (JWT)
    const payload = { email: user.email, sub: user.id };
    const token = this.jwtService.sign(payload);

    return {
      access_token: token,
      user: { email: user.email, name: user.name, id: user.id }
    };
  }
}