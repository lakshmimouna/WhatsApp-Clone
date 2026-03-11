import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
// 🚀 1. Import the Socket.io Adapter!
import { IoAdapter } from '@nestjs/platform-socket.io'; 

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // 🚀 2. FORCE NestJS to actually turn the WebSocket engine on!
  app.useWebSocketAdapter(new IoAdapter(app));

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  
  console.log(`🚀 Server is running on port ${port}`);
}
bootstrap();