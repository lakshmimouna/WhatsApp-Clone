# WhatsApp Clone - Custom Full-Stack Architecture

A fully functional, real-time messaging application built from the ground up without relying on third-party Backend-as-a-Service (BaaS) platforms like Firebase. 

## 🏗️ Architecture Diagram
![Architecture Diagram](WhatsApp%20Clone%20Architecture%20Diagram%20(Updated).png)

## 🚀 Tech Stack
* **Frontend:** Flutter, Provider (State Management), `flutter_local_notifications`
* **Backend:** NestJS (Node.js/TypeScript), Socket.io (WebSockets), Passport.js (JWT)
* **Database:** PostgreSQL (hosted on Neon), Prisma ORM
* **Deployment:** Render (Backend API & WebSockets)

## ✨ Core Features
* **Custom Authentication:** Secure Email/Password login using `bcrypt` for password hashing and JWT for session management.
* **Real-Time Messaging:** Bidirectional, low-latency chat powered by custom WebSockets (`Socket.io`).
* **Relational Data Management:** Structured SQL schema handling complex relationships between Users, Chats, and Messages.
* **Local Notifications:** Background socket listeners trigger native Android UI notifications instantly when a message is received.

---
📖 **[Read the full Architecture Journey: Plan vs. Execution here](Plan.md)**
