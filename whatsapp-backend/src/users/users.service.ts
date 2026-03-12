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
  async saveToken(email: string, token: string) {
    try {
      // 🚀 Changed from 'update' to 'upsert'
      const updatedUser = await this.prisma.user.upsert({
        where: { email: email },
        update: { fcmToken: token }, // If they exist, just update the token
        create: {                    // If they DO NOT exist, create them!
          email: email,
          fcmToken: token,
        },
      });
      console.log(`✅ Prisma: Token saved/updated for user ${updatedUser.email}`);
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

  // Add this inside your UsersService class:
  async updateName(email: string, newName: string) {
    // 🚀 PRISMA SYNTAX: This will actually save the name to Neon!
    const updatedUser = await this.prisma.user.update({
      where: { email: email },
      data: { name: newName }, // Note: Change 'name' to 'username' if that is what your Prisma schema uses!
    });

    return { success: true, user: updatedUser };
  }

  // 🚀 Erase the token on logout so they stop getting notifications
  async clearToken(email: string) {
    try {
      return await this.prisma.user.update({
        where: { email: email },
        data: { fcmToken: null }, // Wipe it out!
      });
    } catch (error) {
      console.error('Error clearing token:', error);
      return null;
    }
  }
}
