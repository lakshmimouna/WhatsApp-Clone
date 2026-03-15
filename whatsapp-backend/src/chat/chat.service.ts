/*
 * ARCHITECTURE: DATABASE SERVICE (Prisma/Neon)
 * This service handles all CRUD operations for the chat feature.
 * It uses Prisma ORM to securely connect to the PostgreSQL database on Neon.
 * It resolves queries for chat history and creates new message records 
 * ensuring data persistence if the app is closed or refreshed.
 */
import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class ChatService {
  private prisma = new PrismaClient();

  // 🚀 1. Fetch All Users & Recent Chats
  async getRecentItems(type: 'chat' | 'group', userEmail: string) {
    try {
      const currentUser = await this.prisma.user.findUnique({ where: { email: userEmail } });
      if (!currentUser) return [];

      // 🚀 1. Fetch ALL users except yourself, newest registrations first
      const allUsers = await this.prisma.user.findMany({
        where: { id: { not: currentUser.id } },
        orderBy: { createdAt: 'desc' }, 
      });

      const formattedList: any[] = [];

      for (const otherUser of allUsers) {
        // Look for existing messages
        const chat = await this.prisma.chat.findFirst({
          where: {
            isGroup: false,
            AND: [
              { participants: { some: { userId: currentUser.id } } },
              { participants: { some: { userId: otherUser.id } } }
            ]
          },
          include: {
            messages: {
              orderBy: { createdAt: 'desc' },
              take: 1, // Get only the last message
              include: { sender: true }
            },
            _count: {
              select: { messages: { where: { senderId: otherUser.id, isRead: false } } }
            }
          }
        });

        const latestMessage = chat?.messages[0];

        formattedList.push({
          roomID: otherUser.email,
          contactName: otherUser.name,
          email: otherUser.email,
          text: latestMessage ? latestMessage.text : "Tap to start chatting", 
          sender: latestMessage?.sender.email,
          senderName: latestMessage?.sender.name,
          // 🚀 2. Sort by the latest message time, or when they joined if no messages exist
          timestamp: latestMessage ? latestMessage.createdAt.getTime() : otherUser.createdAt.getTime(),
          unreadCount: chat?._count.messages || 0
        });
      }

      // 🚀 3. Final sort: Push the most recently active chats to the very top!
      formattedList.sort((a, b) => b.timestamp - a.timestamp);

      return formattedList;
    } catch (error) {
      console.error(`🚨 Error fetching list:`, error);
      return [];
    }
  }

  // 🚀 2. Save a New Message to Database
  async sendMessage(senderEmail: string, receiverEmail: string, text: string) {
    const sender = await this.prisma.user.findUnique({ where: { email: senderEmail } });
    const receiver = await this.prisma.user.findUnique({ where: { email: receiverEmail } });

    if (!sender || !receiver) throw new Error("Could not find users in database");

    let chat = await this.prisma.chat.findFirst({
      where: {
        isGroup: false,
        AND: [
          { participants: { some: { userId: sender.id } } },
          { participants: { some: { userId: receiver.id } } }
        ]
      }
    });

    if (!chat) {
      chat = await this.prisma.chat.create({
        data: {
          isGroup: false,
          participants: {
            create: [{ userId: sender.id }, { userId: receiver.id }]
          }
        }
      });
    }

    return this.prisma.message.create({
      data: {
        text: text,
        senderId: sender.id,
        chatId: chat.id
      }
    });
  }

  // 🚀 3. Fetch Old Messages when opening a Chat
  async getChatHistory(user1Email: string, user2Email: string) {
    try {
      const user1 = await this.prisma.user.findUnique({ where: { email: user1Email } });
      const user2 = await this.prisma.user.findUnique({ where: { email: user2Email } });

      if (!user1 || !user2) return [];

      const chat = await this.prisma.chat.findFirst({
        where: {
          isGroup: false,
          AND: [
            { participants: { some: { userId: user1.id } } },
            { participants: { some: { userId: user2.id } } }
          ]
        },
        include: {
          messages: {
            orderBy: { createdAt: 'asc' },
            include: { sender: true }
          }
        }
      });

      if (!chat) return [];

      return chat.messages.map(msg => ({
        text: msg.text,
        sender: msg.sender.email,
        timestamp: msg.createdAt.getTime(),
        isRead: msg.isRead, // 🚀 Now Flutter will know if it's read!
      }));
    } catch (error) {
      console.error('🚨 Error fetching history:', error);
      return [];
    }
  }

  // 🚀 Marks all unread messages from the other person as READ
  async markRoomAsRead(roomID: string, currentUserEmail: string) {
    const currentUser = await this.prisma.user.findUnique({ where: { email: currentUserEmail } });
    const otherUser = await this.prisma.user.findUnique({ where: { email: roomID } });

    if (!currentUser || !otherUser) return;

    const chat = await this.prisma.chat.findFirst({
      where: {
        isGroup: false,
        AND: [
          { participants: { some: { userId: currentUser.id } } },
          { participants: { some: { userId: otherUser.id } } }
        ]
      }
    });

    if (!chat) return;

    await this.prisma.message.updateMany({
      where: {
        chatId: chat.id,
        senderId: otherUser.id, // Only mark messages sent BY the other person
        isRead: false
      },
      data: { isRead: true }
    });
  }
}