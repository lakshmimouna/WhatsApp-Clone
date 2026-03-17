# Project Journey: Plan vs. Execution

When I started this project, the goal was to build a standard messaging app. However, during development, I realized that to truly demonstrate full-stack engineering, I needed to take ownership of the entire data pipeline. 

Here is how the project evolved from a standard template to a custom architecture:

### 1. Authentication
* **Initial Plan:** Use Google Sign-In and Firebase Authentication for quick setup.
* **What I Did:** Built a custom Auth Module in NestJS.
* **Why:** To maintain full ownership of user data and implement custom JWT security and `bcrypt` password hashing.

### 2. Real-Time Data & Notifications
* **Initial Plan:** Rely on Firebase Cloud Messaging (FCM) to push notifications and update the UI.
* **What I Did:** Implemented a custom WebSocket Gateway (`Socket.io`) on the backend and used `flutter_local_notifications` on the frontend.
* **Why:** To eliminate the dependency on Google's push services. WebSockets provide a faster, direct, two-way connection for real-time messaging, allowing the app to trigger native notifications locally via the open socket.

### 3. Database Strategy
* **Initial Plan:** Store messages in Firebase Firestore (NoSQL).
* **What I Did:** Migrated to a strict Relational Database (PostgreSQL on Neon) using Prisma ORM.
* **Why:** A chat application relies heavily on data relationships (Users -> Chat Rooms -> Messages). SQL ensures data integrity, prevents duplicate records, and makes querying complex chat histories much more efficient than NoSQL document stores.

### Conclusion
By abandoning the "easy route" of third-party BaaS, I built a highly scalable, independent architecture where I control the complete flow of data from the device screen to the database rows.
