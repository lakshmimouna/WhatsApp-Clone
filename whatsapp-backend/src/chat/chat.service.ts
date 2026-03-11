import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class ChatService {
  private prisma = new PrismaClient();

  // 🚀 1. Fetch Recent Chats for Home Screen
  async getRecentItems(type: 'chat' | 'group', userEmail: string) {
    try {
      const user = await this.prisma.user.findUnique({ where: { email: userEmail } });
      if (!user) return [];

      const isGroupFilter = type === 'group';
      const chats = await this.prisma.chat.findMany({
        where: {
          isGroup: isGroupFilter,
          participants: { some: { userId: user.id } }
        },
        include: {
          participants: { include: { user: true } },
          messages: {
            orderBy: { createdAt: 'desc' },
            take: 1, // Only need the newest message
            include: { sender: true }
          }
        }
      });

      const formattedChats = chats
        .filter(chat => chat.messages.length > 0)
        .map(chat => {
          const latestMessage = chat.messages[0];
          let displayRoomName = chat.name;
          if (!chat.isGroup) {
            const otherPerson = chat.participants.find(p => p.userId !== user.id);
            displayRoomName = otherPerson?.user.name || otherPerson?.user.email || 'Unknown';
          }

          return {
            roomID: displayRoomName,
            text: latestMessage.text,
            sender: latestMessage.sender.email,
            timestamp: latestMessage.createdAt.getTime(),
            unreadCount: 0
          };
        });

      return formattedChats.sort((a, b) => b.timestamp - a.timestamp);
    } catch (error) {
      console.error(`🚨 Error fetching ${type}s:`, error);
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