import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class UsersService {
  // This connects to your new Neon PostgreSQL Database
  private prisma = new PrismaClient();

  // 1. Fetch all users for the Contact List
  async getAllUsers() {
    try {
      return await this.prisma.user.findMany({
        select: {
          id: true,
          name: true,
          email: true,
          avatarUrl: true,
          fcmToken: true,
        },
      });
    } catch (error) {
      console.error('Error fetching users:', error);
      return [];
    }
  }

  // 2. Save the FCM Token when a user logs in
  async saveToken(userId: string, token: string) {
    try {
      const updatedUser = await this.prisma.user.update({
        where: { id: userId },
        data: { fcmToken: token },
      });
      console.log(`✅ Prisma: Token updated for user ${updatedUser.email}`);
      return updatedUser;
    } catch (error) {
      console.error(`🚨 Prisma Save Error:`, error);
      throw error;
    }
  }

  // 3. Get a user's token (We will use this later to send notifications!)
  async getUserToken(userId: string): Promise<string | null> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      return user?.fcmToken || null;
    } catch (error) {
      console.error(`🚨 Prisma Retrieval Error:`, error);
      return null;
    }
  }
}