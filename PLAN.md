# Project Journey: Original Plan vs. Final Execution

When I started this project, the goal was to build a standard messaging app using common third-party tools. However, during development, I realized that to truly demonstrate full-stack engineering, I needed to take complete ownership of the architecture.

Here is how my initial 6-phase plan evolved into a custom-engineered solution:

## Phase 1 & 2: Project Setup & Backend Development
* **Initial Plan:** Use Firebase for Google Authentication and Firebase Cloud Messaging (FCM) for push notifications. Keep the database choice open between MongoDB and PostgreSQL.
* **Actual Execution:** * **Dropped Firebase entirely.**
  * **Database:** Strictly chose **PostgreSQL with Prisma ORM** (hosted on Neon) because chat applications require strong relational data structures (Users -> Chat Rooms -> Messages).
  * **Authentication:** Built a custom Auth Module in NestJS using `bcrypt` for password hashing and **JWT** (JSON Web Tokens) for session management.

## Phase 3 & 4: Frontend Setup & Core UI
* **Initial Plan:** Build the Login/Signup screens integrated with the Google Sign-In plugin. Initialize Riverpod or Bloc for state management.
* **Actual Execution:**
  * Built custom Email/Password UI forms that interface directly with my NestJS REST APIs.
  * Implemented **Provider** for state management to efficiently handle UI updates for the Chat and Group list tabs.

## Phase 5: Integration & Real-Time Sync
* **Initial Plan:** Connect Flutter to NestJS WebSockets and listen for background FCM messages for notifications.
* **Actual Execution:** * Relied entirely on the custom **Socket.io** WebSocket connection for real-time, bidirectional messaging.
  * Instead of using Google's FCM, I engineered the Flutter app to listen to the live socket events and trigger native Android banners locally using the `flutter_local_notifications` package.

## Phase 6: Final Testing & Conclusion
* **Initial Plan:** Test Google Login and push notifications via Firebase.
* **Actual Execution:** Tested the custom JWT auth flow, relational database queries, and socket-driven local notifications.

**Conclusion:** By abandoning the initial plan's reliance on third-party Backend-as-a-Service (BaaS) platforms, I successfully built a highly scalable, independent architecture. I now control the complete data flow from the Flutter frontend to the PostgreSQL backend.
