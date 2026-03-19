# 📱 WhatsApp Clone — Full-Stack Real-Time Chat App

A full-stack, production-deployed WhatsApp clone built with **Flutter** (frontend) and **NestJS** (backend). This project replicates the core experience of WhatsApp including real-time messaging, read receipts (blue ticks), typing indicators, image sharing, push notifications, and a contact list — all running on a live cloud server.

> 🌐 **Live Backend:** [https://whatsapp-clone-backend-navv.onrender.com](https://whatsapp-clone-backend-navv.onrender.com)

---

## 📸 Demo

| Home Screen | Chat Screen |
|---|---|
| Contact list with unread counts and last message preview | Real-time messaging with blue ticks, typing indicators, image sharing, and reply feature |

---

## 🏗️ Architecture Overview

This project is split into two separate codebases that communicate over HTTP and WebSockets:

```
WhatsApp Clone/
├── whatsapp-backend/     ← NestJS REST API + Socket.io Server (deployed on Render)
└── whatsapp_clone/       ← Flutter Mobile App (Android)
```

### System Flow Diagram

```
  Flutter App
      │
      ├── HTTP (REST) ────────► NestJS Backend ────► PostgreSQL (Neon)
      │    └── Auth, History,                             (Prisma ORM)
      │         User List
      │
      └── WebSocket ──────────► Socket.io Gateway ──► Broadcast to rooms
           └── sendMessage,
                markAsRead,
                typing events
```

---

## 🏗️ Architecture Diagram

![Architecture Diagram](WhatsApp%20Clone%20Architecture%20Diagram%20(Updated).png)

---

## 🛠️ Tech Stack

### Backend (`whatsapp-backend/`)

| Technology | Purpose |
|---|---|
| **NestJS v11** | Server framework (TypeScript, modular, decorator-based) |
| **Socket.io v4** | Real-time bidirectional WebSocket communication |
| **Prisma ORM v6** | Type-safe database query builder |
| **PostgreSQL (Neon)** | Cloud-hosted relational database |
| **bcrypt** | Password hashing (never stored as plaintext) |
| **JWT (`@nestjs/jwt`)** | Stateless user authentication (30-day token) |
| **Render** | Cloud deployment platform (live backend host) |

### Frontend (`whatsapp_clone/`)

| Technology | Purpose |
|---|---|
| **Flutter (Dart SDK ^3.11)** | Cross-platform mobile UI framework |
| **socket_io_client** | WebSocket client to connect to Socket.io backend |
| **Provider** | Lightweight state management for the chat list |
| **flutter_secure_storage** | Encrypted local storage for JWT tokens and session data |
| **http** | REST API calls (auth, chat history, user list) |
| **flutter_local_notifications** | In-app push notifications for new messages |
| **image_picker + ImgBB API** | Gallery image selection and cloud upload |
| **swipe_to** | Swipe-to-reply gesture on messages |
| **intl** | Timestamp formatting (e.g., "3:45 PM") |

---

## ✨ Features

- ✅ **Email / Password Authentication** — Signup & Login with bcrypt-hashed passwords and JWT tokens
- ✅ **Real-Time Messaging** — Socket.io WebSocket gateway for instant message delivery
- ✅ **Persistent Chat History** — Messages stored in PostgreSQL and fetched on screen open
- ✅ **Read Receipts (Blue Ticks)** — Double-tick turns blue when the recipient opens the chat
- ✅ **Typing Indicator** — "typing..." appears in the app bar when the other person is writing
- ✅ **Online Status** — Shows "Online" / "Offline" for each contact
- ✅ **Image Sharing** — Pick from gallery, upload to ImgBB CDN, send URL as a message
- ✅ **Reply to Message** — Swipe right on any bubble to quote-reply
- ✅ **Contact List** — All registered users appear automatically on the Home Screen
- ✅ **Unread Message Badge** — Green counter on chat tiles for unread messages
- ✅ **Push Notifications** — Local notifications with contact name and message preview
- ✅ **Search** — Filter chat list by contact name in real time
- ✅ **Logout** — Clears secure storage and redirects to onboarding
- ✅ **Secure Session** — JWT stored in `flutter_secure_storage`, valid for 30 days

---

## 📂 Project Structure — Backend

```
whatsapp-backend/
├── prisma/
│   └── schema.prisma          # Database schema (User + Message models)
├── src/
│   ├── app.module.ts          # Root module — wires together all feature modules
│   ├── main.ts                # Entry point — starts NestJS + enables CORS
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.service.ts    # (Minimal — auth handled in UsersService)
│   │   └── auth.controller.ts
│   ├── users/
│   │   ├── users.module.ts
│   │   ├── users.controller.ts  # REST endpoints: /users/signup, /users/login, GET /users
│   │   └── users.service.ts     # Business logic: bcrypt hashing, JWT signing, DB queries
│   ├── chat/
│   │   ├── chat.module.ts
│   │   ├── chat.gateway.ts      # WebSocket gateway: sendMessage, markAsRead events
│   │   ├── chat.service.ts      # DB operations: saveMessage, getHistory, markMessagesAsRead
│   │   └── chat.controller.ts   # REST endpoints: /chat/history, /chat/recent
│   └── prisma/
│       ├── prisma.module.ts
│       └── prisma.service.ts    # Shared PrismaClient wrapper
└── package.json
```

## 📂 Project Structure — Flutter App

```
whatsapp_clone/lib/
├── main.dart                   # Entry point — sets up Provider, Firebase, routing
├── firebase_options.dart       # Firebase config (used for platform setup)
├── providers/
│   └── chat_provider.dart      # State management: user session, chat list, real-time updates
├── services/
│   └── socket_service.dart     # Singleton WebSocket connection to the backend
└── screens/
    ├── splash_screens.dart      # Initial loading screen — checks for saved JWT
    ├── onboarding_screen.dart   # Welcome / Get Started screen
    ├── login_screen.dart        # Login + Signup form (toggleable)
    ├── home_screen.dart         # Chat list, search, notifications, contact picker
    └── chat_screen.dart         # Active conversation, message bubbles, input bar
```

---

## 🗄️ Database Schema

Defined in `prisma/schema.prisma` and hosted on **Neon (PostgreSQL)**:

### `User` Table
| Column | Type | Notes |
|---|---|---|
| `id` | `String (UUID)` | Auto-generated primary key |
| `email` | `String (unique)` | Used as the login identifier and room key |
| `name` | `String` | Display name shown in the chat list |
| `password` | `String` | bcrypt hash — plaintext is NEVER stored |
| `avatarUrl` | `String?` | Optional profile picture URL |
| `createdAt` | `DateTime` | Auto-set on account creation |

### `Message` Table
| Column | Type | Notes |
|---|---|---|
| `id` | `String (UUID)` | Auto-generated primary key |
| `text` | `String` | Message content (prefix `[IMAGE]` denotes image URL) |
| `senderEmail` | `String?` | Foreign key → `User.email` |
| `roomID` | `String?` | The *receiver's* email, creating a unique 1-on-1 room |
| `timestamp` | `BigInt?` | Unix milliseconds from the client |
| `isRead` | `Boolean` | `false` = grey ticks, `true` = blue ticks |

---

## 🔌 API Reference

### REST Endpoints (`UsersController`)

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/users/signup` | Register a new user. Body: `{ email, password, name }` |
| `POST` | `/users/login` | Login. Returns `{ access_token, user: { email, name, id } }` |
| `GET` | `/users` | Get all registered users (for the contact list) |

### REST Endpoints (`ChatController`)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/chat/history?user1=&user2=` | Fetch full message history between two users |
| `GET` | `/chat/recent?type=chat&email=` | Fetch recent chat list with last messages |

### WebSocket Events (`ChatGateway`)

| Event | Direction | Payload | Description |
|---|---|---|---|
| `connect` | Client → Server | `?email=` in query string | Joins user to their private room |
| `sendMessage` | Client → Server | `{ text, sender, roomID, timestamp, replyToText?, replyToSender? }` | Saves message to DB and broadcasts |
| `receiveMessage` | Server → Client | Saved message object | Delivered to the receiver's room |
| `messageSent` | Server → Sender | Saved message object | Confirmation callback to sender |
| `markAsRead` | Client → Server | `{ reader, roomID }` | Marks messages as read in DB |
| `messagesRead` | Server → Client | `{ by: readerEmail }` | Triggers blue tick update on sender's screen |
| `userStatusChanged` | Server → All | `{ email, status }` | Broadcasts online/offline status |

---

## 🔐 Authentication Flow

```
User Enters Email + Password
         │
         ▼
  POST /users/login
         │
         ▼
  Backend: bcrypt.compare(password, hashedPassword)
         │
   ✅ Match?
         │
         ▼
  jwtService.sign({ email, sub: userId })
         │
         ▼
  Returns { access_token, user: { email, name, id } }
         │
         ▼
  Flutter: Saves token in flutter_secure_storage
         │
         ▼
  Flutter: Connects WebSocket with email as query param
         │
         ▼
  Backend: client.join(email) → creates private room
```

---

## 🔄 Real-Time Message Flow

```
[Sender types & hits send]
         │
         ▼
  socket.emit('sendMessage', { text, sender, roomID, timestamp })
         │
         ▼
  [NestJS ChatGateway receives event]
         │
         ├── 1. chatService.saveMessage(payload) → Writes to PostgreSQL
         │
         ├── 2. server.to(roomID).emit('receiveMessage', savedMsg) → Pushes to receiver
         │
         └── 3. client.emit('messageSent', savedMsg) → Confirms to sender
                        │
                        ▼
             [Receiver's Flutter app]
                        │
               socket.on('receiveMessage')
                        │
             ├── ChatScreen: adds bubble to UI
             └── HomeScreen: updates chat tile + shows notification
```

---

## 🔵 Blue Tick (Read Receipt) Flow

```
[User B opens ChatScreen with User A]
         │
         ▼
  socket.emit('markAsRead', { reader: B, roomID: A })
         │
         ▼
  [Backend]: chatService.markMessagesAsRead(A, B)
             → UPDATE messages SET isRead=true WHERE senderEmail=A AND roomID=B
         │
         ▼
  server.to(roomID).emit('messagesRead', { by: B })
         │
         ▼
  [User A's ChatScreen]: socket.on('messagesRead')
             → Sets all msg['isRead'] = true
             → Grey ✓✓ → Blue ✓✓
```

---

## 🚀 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) v18+
- [Flutter SDK](https://flutter.dev/docs/get-started/install) ^3.11
- [NestJS CLI](https://docs.nestjs.com/)  (`npm install -g @nestjs/cli`)
- A [Neon](https://neon.tech/) PostgreSQL database (free tier available)

---

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/whatsapp-clone.git
cd "whatsapp-clone"
```

---

### 2. Set Up the Backend

```bash
cd whatsapp-backend
npm install
```

Create a `.env` file in `whatsapp-backend/`:

```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST/DATABASE?sslmode=require"
JWT_SECRET="your_secret_key_here"
```

Run Prisma migrations to create the database tables:

```bash
npx prisma migrate dev --name init
npx prisma generate
```

Start the development server:

```bash
npm run start:dev
```

The backend will be running at `http://localhost:3000`.

---

### 3. Set Up the Flutter App

```bash
cd ../whatsapp_clone
flutter pub get
```

Open `lib/providers/chat_provider.dart` and `lib/screens/login_screen.dart` and update the backend URL:

```dart
// Change this:
final String backendUrl = 'https://whatsapp-clone-backend-navv.onrender.com';

// To your local IP (find it with `ipconfig` on Windows):
final String backendUrl = 'http://192.168.x.x:3000';
```

Also update `lib/services/socket_service.dart`:

```dart
socket = IO.io('http://192.168.x.x:3000', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
});
```

Run the app on a connected Android device or emulator:

```bash
flutter run
```

---

## ☁️ Deployment

The backend is deployed on **Render** (free tier):

1. Push `whatsapp-backend/` to its own GitHub repository
2. Create a new **Web Service** on [render.com](https://render.com)
3. Set the **Build Command** to `npm install && npx prisma generate && npm run build`
4. Set the **Start Command** to `npm run start:prod`
5. Add `DATABASE_URL` and `JWT_SECRET` as **Environment Variables**

The live backend URL is then used directly in the Flutter app.

---

## 📄 License

This project is for educational purposes only. WhatsApp is a trademark of Meta Platforms, Inc.
