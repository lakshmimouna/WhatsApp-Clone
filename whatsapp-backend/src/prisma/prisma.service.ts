import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    // 1. Create a standard connection pool using your Neon URL
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    // 2. Wrap it in Prisma's PostgreSQL adapter
    const adapter = new PrismaPg(pool);
    
    // 3. Pass the adapter to Prisma 7
    super({ adapter });
  }

  async onModuleInit() {
    try {
      await this.$connect();
      console.log('DATABASE: Connected to Neon successfully.');
    } catch (error) {
      console.error('DATABASE: Connection failed!', error);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}