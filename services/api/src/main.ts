import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { WINSTON_MODULE_NEST_PROVIDER } from 'nest-winston';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Use Winston for logging
  app.useLogger(app.get(WINSTON_MODULE_NEST_PROVIDER));
  
  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  
  // API prefix
  const apiPrefix = process.env.API_PREFIX || 'api/v1';
  app.setGlobalPrefix(apiPrefix);
  
  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('Sales Signal Processing Platform API')
    .setDescription('API for ingesting and processing sales events')
    .setVersion('1.0')
    .addTag('events')
    .addTag('health')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  
  // Enable CORS
  app.enableCors();
  
  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  console.log(`🚀 API Service is running on: http://localhost:${port}/${apiPrefix}`);
  console.log(`📚 API Documentation: http://localhost:${port}/api/docs`);
}

bootstrap();
