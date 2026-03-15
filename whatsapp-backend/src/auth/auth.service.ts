import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {
  // 🚀 Google Login has been completely removed based on the interviewer's feedback.
  // All custom Email/Password authentication and JWT generation 
  // is now handled securely inside the UsersService.
}