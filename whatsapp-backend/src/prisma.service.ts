import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import 'dotenv/config'; // <-- This guarantees the Neon URL is loaded!

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    // Now this will definitively connect to Neon, not a blank local database
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const adapter = new PrismaPg(pool);
    
    // Prisma 7 strictly requires the adapter to be passed like this
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }
}