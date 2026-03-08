import { Injectable } from '@nestjs/common';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

@Injectable()
export class UsersService {
    private docClient: DynamoDBDocumentClient;
    private readonly tableName = 'WhatsAppUsers';

    constructor() {
        const client = new DynamoDBClient({
            region: 'ap-southeast-2',
            credentials: {
                // 🚀 Read from the hidden .env file!
                accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
            }
        });
        this.docClient = DynamoDBDocumentClient.from(client);
    }

    async saveUserToken(userName: string, fcmToken: string) {
        const command = new PutCommand({
            TableName: this.tableName,
            Item: {
                userName: userName,
                fcmToken: fcmToken,
                updatedAt: Date.now(),
            },
        });

        try {
            await this.docClient.send(command);
            console.log(`✅ DynamoDB: Token updated for ${userName}`);
        } catch (error) {
            console.error(`🚨 DynamoDB Save Error:`, error);
        }
    }

    async getUserToken(userName: string): Promise<string | null> {
        const command = new GetCommand({
            TableName: this.tableName,
            Key: { userName: userName },
        });

        try {
            const response = await this.docClient.send(command);
            return response.Item ? response.Item.fcmToken : null;
        } catch (error) {
            console.error(`🚨 DynamoDB Retrieval Error for ${userName}:`, error);
            return null;
        }
    }
}