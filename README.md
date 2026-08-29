# RentHubIndia 🏠

> **Rent Anything. Anywhere.**

RentHubIndia is a full-stack rental marketplace platform — a modern, premium alternative to classifieds apps, built exclusively for renting (not buying or selling). Users can list items for rent, discover nearby listings, book rentals, chat with owners, and manage everything from one place.

---



## 🧱 Project Structure

This monorepo contains three applications:

```
renthubindia/
├── backend/          # Node.js + Express REST API + Socket.IO
├── mobile/           # Flutter iOS & Android app
└── admin/            # React.js admin dashboard panel
```

---

## ✨ Features

### Mobile App (Flutter)
- 🔍 Browse and search rental listings by category, location, and price
- 📍 Auto-detects user country and shows prices in local currency
- 📦 Post items for rent with up to 5 photos
- 📅 Booking request flow (Pending → Accepted → Completed)
- 💬 Real-time chat using WebSocket (Socket.IO)
- 🔔 Push notifications via Firebase Cloud Messaging (FCM)
- ✅ Identity verification system with verified badge
- ⭐ Reviews and ratings after completed rentals
- 🚩 Report listings and users
- 🎫 In-app support ticket system
- 🌍 Location-based filtering — shows listings from user's country
- 💱 Automatic currency detection (30+ currencies supported)
- 🔐 Secure JWT authentication with refresh token rotation

### Admin Dashboard (React)
- 📊 Full analytics system (users, listings, bookings, revenue, engagement)
- 👥 User management — verify, block, search
- 📦 Listing approval and moderation
- 📅 Booking management
- 🚩 Reports moderation with action system
- ⭐ Review moderation
- 🗂️ Category management (full CRUD)
- 🎫 Support ticket management with reply system
- 🌍 Country-wise filtering on all tables
- 📄 Server-side pagination (50 rows per page)

### Backend API (Node.js)
- RESTful API with 40+ endpoints
- Real-time WebSocket chat with Socket.IO
- JWT authentication (15-min access + 30-day refresh tokens)
- Rate limiting via Upstash Redis
- Image uploads to Cloudinary (private folder for ID documents)
- Push notifications via Firebase Admin SDK
- Input validation with Zod on all routes
- Row-level authorization and ownership checks

---

## 🛠️ Tech Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Runtime | Node.js |
| Framework | Express.js |
| ORM | Prisma |
| Database | PostgreSQL (Neon — serverless) |
| Cache / Rate Limiting | Redis (Upstash — serverless) |
| Real-time | Socket.IO |
| Image Storage | Cloudinary |
| Push Notifications | Firebase Admin SDK (FCM) |
| Auth | JWT (bcrypt + refresh tokens) |
| Validation | Zod |
| Security | Helmet, HPP, CORS, Rate Limiting |

### Mobile App
| Layer | Technology |
|-------|-----------|
| Framework | Flutter (iOS + Android) |
| State Management | flutter_bloc |
| Navigation | go_router |
| HTTP Client | Dio (with JWT interceptor + auto-refresh) |
| Secure Storage | flutter_secure_storage |
| Real-time Chat | socket_io_client |
| Push Notifications | firebase_messaging + flutter_local_notifications |
| Maps | google_maps_flutter |
| Location | geolocator + geocoding |
| Images | cached_network_image + image_picker |

### Admin Dashboard
| Layer | Technology |
|-------|-----------|
| Framework | React.js |
| UI | shadcn/ui + Tailwind CSS |
| HTTP Client | Axios (with JWT interceptor) |
| Tables | TanStack Table |
| Charts | Recharts |
| Forms | React Hook Form + Zod |
| State | Zustand |

---

## 🚀 Getting Started

### Prerequisites
- Node.js v18+
- Flutter SDK 3.x
- PostgreSQL database (or Neon account)
- Redis (or Upstash account)
- Firebase project
- Cloudinary account

---

### Backend Setup

```bash
cd backend
npm install
```

Create `.env` file:
```env
# Database — Neon serverless PostgreSQL
DATABASE_URL=postgresql://user:password@ep-xxxx.neon.tech/renthubindia?sslmode=require

# Cache — Upstash Redis
REDIS_URL=rediss://default:xxxx@xxx.upstash.io:6379

# Auth
JWT_SECRET=<64+ random characters>
JWT_REFRESH_SECRET=<different 64+ random characters>

# Firebase (FCM push notifications)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email

# Cloudinary (image storage)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Email (OTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email
EMAIL_PASS=your_password

PORT=5000
NODE_ENV=development
```

Run database migrations:
```bash
npx prisma migrate dev
npx prisma generate
```

Start the server:
```bash
npm run dev       # development
npm start         # production
```

The API will be running at `http://localhost:5000`

---

### Flutter App Setup

```bash
cd mobile
flutter pub get
```

Update the base URL in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://localhost:5000';
```

Add Firebase config files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Run the app:
```bash
flutter run
```

Build for release:
```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
```

---

### Admin Dashboard Setup

```bash
cd admin
npm install
```

Create `.env`:
```env
VITE_API_BASE_URL=http://localhost:5000
VITE_APP_NAME=RentHubIndia Admin
VITE_CLOUDINARY_CLOUD_NAME=your_cloud_name
```

Start development server:
```bash
npm run dev
```

Build for production:
```bash
npm run build
```

---

## 📡 API Overview

Base URL: `http://localhost:5000`

All protected routes require: `Authorization: Bearer <access_token>`

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login (returns access + refresh token) |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout + revoke tokens |
| POST | `/api/auth/forgot-password` | Send OTP to email |
| POST | `/api/auth/verify-otp` | Verify OTP code |
| POST | `/api/auth/reset-password` | Reset password |

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/profile` | Get own profile |
| PUT | `/api/users/profile` | Update profile |
| POST | `/api/users/avatar` | Upload avatar |
| POST | `/api/users/fcm-token` | Register FCM token |
| POST | `/api/users/me/verify` | Submit ID document |
| GET | `/api/users/:id` | Get public profile |

### Listings
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/listings` | Browse listings (with filters) |
| GET | `/api/listings/:id` | Get listing details |
| POST | `/api/listings` | Create listing |
| POST | `/api/listings/:id/images` | Upload images (max 5) |
| PATCH | `/api/listings/:id/status` | Pause / activate |
| GET | `/api/listings/my/listings` | My listings |

### Bookings
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/bookings` | Create booking request |
| GET | `/api/bookings/my` | My outgoing bookings |
| GET | `/api/bookings/incoming` | Incoming booking requests |
| PATCH | `/api/bookings/:id/accept` | Accept booking (owner) |
| PATCH | `/api/bookings/:id/cancel` | Cancel booking |
| PATCH | `/api/bookings/:id/complete` | Mark complete (owner) |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/chat` | Create or get chat |
| GET | `/api/chat/conversations` | All conversations |
| GET | `/api/chat/:chatId/messages` | Message history |
| POST | `/api/chat/:chatId/upload` | Upload image message |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/dashboard` | Platform stats |
| GET | `/api/admin/analytics/*` | Analytics endpoints |
| PATCH | `/api/admin/listings/:id/approve` | Approve listing |
| PATCH | `/api/admin/users/:id/verify` | Verify user |
| PATCH | `/api/admin/users/:id/block` | Block user |
| DELETE | `/api/admin/reviews/:id` | Delete review |
| PATCH | `/api/admin/reports/:id/action` | Resolve report |
| PATCH | `/api/admin/support/tickets/:id/reply` | Reply to ticket |

---

## 🔌 WebSocket Events

Connect: `io('http://localhost:5000', { auth: { token: 'Bearer JWT' } })`

| Client → Server | Payload | Description |
|----------------|---------|-------------|
| `join_chat` | `{ chatId }` | Join chat room |
| `send_message` | `{ chatId, text, replyToId? }` | Send message |
| `delete_message` | `{ messageId, deleteType }` | Delete message |
| `edit_message` | `{ messageId, newText }` | Edit message |
| `react_to_message` | `{ messageId, emoji }` | Add/remove reaction |
| `mark_read` | `{ chatId }` | Mark messages as read |
| `typing` | `{ chatId }` | Typing indicator |
| `stop_typing` | `{ chatId }` | Stop typing |

| Server → Client | Payload | Description |
|----------------|---------|-------------|
| `chat_history` | `{ chatId, messages[] }` | Message history on join |
| `new_message` | `{ message }` | Incoming message |
| `message_sent` | `{ message }` | Send confirmation |
| `message_deleted` | `{ messageId, deleteType }` | Message deleted |
| `message_edited` | `{ messageId, newText, editedAt }` | Message edited |
| `messages_read` | `{ chatId, readBy }` | Read receipt |
| `notification_received` | `{ notification, unreadCount }` | Live notification |

---

## 🗄️ Database Schema

Key models in `prisma/schema.prisma`:

- **User** — accounts, verification status, ratings
- **Listing** — rental listings with images and availability
- **Category** — listing categories
- **Booking** — rental bookings (PENDING → ACCEPTED → COMPLETED)
- **Review** — post-rental reviews and ratings
- **Chat + Message** — real-time messaging with reactions and replies
- **Report** — content moderation reports
- **Notification** — in-app and push notifications
- **SupportTicket** — user support tickets
- **OTP** — one-time passwords for auth flows

---

## 🔐 Security Features

- ✅ Short-lived JWT access tokens (15 min) + refresh tokens (30 days)
- ✅ Refresh token rotation with theft detection
- ✅ Token blacklisting in Redis on logout
- ✅ Brute force protection (account lockout after 10 failed attempts)
- ✅ Rate limiting on all endpoints (Redis-backed)
- ✅ Input validation with Zod on every route
- ✅ Ownership checks on all mutations
- ✅ File upload validation (MIME type + magic bytes + size limit)
- ✅ Government ID documents stored in private Cloudinary folder
- ✅ Helmet.js HTTP security headers
- ✅ CORS locked to allowed origins in production
- ✅ No sensitive data in error responses
- ✅ Flutter: flutter_secure_storage for tokens (iOS Keychain / Android Keystore)
- ✅ Flutter: Code obfuscation in release builds

---

## 📁 Folder Structure

### Backend
```
backend/
├── prisma/
│   └── schema.prisma
├── src/
│   ├── config/         # DB, Redis, Firebase, Socket.IO, Cloudinary
│   ├── middleware/     # Auth, validation, rate limit, ownership, upload
│   ├── modules/        # Feature modules (auth, users, listings, bookings...)
│   ├── utils/          # JWT, notifications, paginate, analytics helpers
│   └── app.js
└── server.js
```

### Mobile App
```
mobile/lib/
├── core/               # Router, theme, constants, utils
├── data/
│   ├── models/         # Data models
│   ├── repositories/   # API call wrappers
│   └── services/       # API, WebSocket, FCM, location, Cloudinary
├── blocs/              # BLoC state management
└── features/           # Screens by feature
```

### Admin Dashboard
```
admin/src/
├── api/                # Axios API clients per module
├── components/         # Shared UI components
├── hooks/              # Custom React hooks
├── pages/              # Page components
└── store/              # Auth state store
```

---

## 🌍 Supported Regions

RentHubIndia is built for global use with automatic currency detection:

🇸🇬 Singapore · 🇮🇳 India · 🇲🇾 Malaysia · 🇮🇩 Indonesia · 🇵🇭 Philippines · 🇹🇭 Thailand · 🇦🇪 UAE · 🇸🇦 Saudi Arabia · 🇬🇧 UK · 🇺🇸 USA · 🇦🇺 Australia · 🇯🇵 Japan · 🇰🇷 South Korea · 🇳🇬 Nigeria · 🇰🇪 Kenya · 🇿🇦 South Africa · and 30+ more countries

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 📩 Contact

**RentHubIndia Support:** support@renthubindia.com

---

*Built with ❤️ — Rent Anything. Anywhere.*
