# RentHubIndia — Backend API (Node.js + Express + Prisma + PostgreSQL)

## Project Overview
RentHubIndia is a **rental-only marketplace** mobile app (no buying/selling). Users can list items for rent, browse listings, book items, chat with owners, and manage their profile. This document covers everything needed to build the backend API for RentHubIndia.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js |
| Framework | Express.js |
| ORM | Prisma |
| Database | PostgreSQL |
| Cache | Redis |
| Auth | JWT + bcrypt + Passport.js (Google OAuth) |
| Email | Nodemailer (OTP, notifications) |
| Real-time Chat | Firebase Firestore (handled client-side, backend just stores metadata) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| File Storage | Cloudinary |
| Payments | ❌ Not in MVP — architecture must be payment-ready for future Stripe integration |

---

## Folder Structure

```
backend/
├── prisma/
│   ├── schema.prisma         # All DB models
│   └── migrations/           # Auto-generated migrations
├── src/
│   ├── config/
│   │   ├── db.js             # Prisma client instance
│   │   ├── redis.js          # Redis client
│   │   ├── firebase.js       # Firebase Admin SDK
│   │   └── passport.js       # Google OAuth strategy
│   ├── middleware/
│   │   ├── auth.js           # JWT verification middleware
│   │   ├── role.js           # Role-based access (user / admin)
│   │   ├── rateLimit.js      # Listing rate limiter (unverified users)
│   │   └── errorHandler.js   # Global error handler
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.js
│   │   │   ├── auth.controller.js
│   │   │   └── auth.service.js
│   │   ├── users/
│   │   │   ├── users.routes.js
│   │   │   ├── users.controller.js
│   │   │   └── users.service.js
│   │   ├── listings/
│   │   │   ├── listings.routes.js
│   │   │   ├── listings.controller.js
│   │   │   └── listings.service.js
│   │   ├── bookings/
│   │   │   ├── bookings.routes.js
│   │   │   ├── bookings.controller.js
│   │   │   └── bookings.service.js
│   │   ├── categories/
│   │   │   ├── categories.routes.js
│   │   │   ├── categories.controller.js
│   │   │   └── categories.service.js
│   │   ├── reviews/
│   │   │   ├── reviews.routes.js
│   │   │   ├── reviews.controller.js
│   │   │   └── reviews.service.js
│   │   ├── reports/
│   │   │   ├── reports.routes.js
│   │   │   ├── reports.controller.js
│   │   │   └── reports.service.js
│   │   ├── notifications/
│   │   │   ├── notifications.routes.js
│   │   │   ├── notifications.controller.js
│   │   │   └── notifications.service.js
│   │   ├── support/
│   │   │   ├── support.routes.js
│   │   │   ├── support.controller.js
│   │   │   └── support.service.js
│   │   └── admin/
│   │       ├── admin.routes.js
│   │       ├── admin.controller.js
│   │       └── admin.service.js
│   ├── utils/
│   │   ├── jwt.js            # Sign & verify JWT
│   │   ├── otp.js            # Generate & verify OTP
│   │   ├── mailer.js         # Send emails via Nodemailer
│   │   ├── fcm.js            # Send push notifications
│   │   └── currency.js       # Country → currency mapping
│   └── app.js                # Express app setup
├── .env
└── server.js                 # Entry point
```

---

## Prisma Schema (`schema.prisma`)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────

enum UserRole {
  USER
  ADMIN
}

enum VerificationStatus {
  UNVERIFIED
  PENDING
  VERIFIED
}

enum ListingStatus {
  ACTIVE
  PAUSED
  EXPIRED
}

enum BookingStatus {
  PENDING
  ACCEPTED
  CONFIRMED
  COMPLETED
  CANCELLED
}

enum ReportStatus {
  OPEN
  REVIEWED
  RESOLVED
}

enum ReportCategory {
  FRAUD
  SPAM
  ABUSE
  FAKE_LISTING
}

enum ReportTargetType {
  LISTING
  USER
  MESSAGE
}

enum TicketStatus {
  OPEN
  IN_PROGRESS
  RESOLVED
  CLOSED
}

// ─────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────

model User {
  id                 String             @id @default(uuid())
  name               String
  email              String             @unique
  phone              String?
  passwordHash       String?            // null for Google OAuth users
  googleId           String?            @unique
  avatarUrl          String?
  role               UserRole           @default(USER)
  verificationStatus VerificationStatus @default(UNVERIFIED)
  verificationDoc    String?            // URL to uploaded ID/Aadhaar
  isBlocked          Boolean            @default(false)
  country            String?            // auto-detected
  city               String?
  currency           String?            // auto-set from country
  fcmToken           String?            // for push notifications
  rating             Decimal?           @db.Decimal(2, 1)
  createdAt          DateTime           @default(now())
  updatedAt          DateTime           @updatedAt

  listings           Listing[]
  bookingsAsRenter   Booking[]          @relation("RenterBookings")
  bookingsAsOwner    Booking[]          @relation("OwnerBookings")
  reviewsGiven       Review[]           @relation("ReviewsGiven")
  reviewsReceived    Review[]           @relation("ReviewsReceived")
  reports            Report[]           @relation("ReporterReports")
  reportsAgainst     Report[]           @relation("ReportedUserReports")
  notifications      Notification[]
  supportTickets     SupportTicket[]
  otps               OTP[]
}

model OTP {
  id        String   @id @default(uuid())
  userId    String
  code      String
  expiresAt DateTime
  used      Boolean  @default(false)
  createdAt DateTime @default(now())

  user      User     @relation(fields: [userId], references: [id])
}

model Category {
  id       String    @id @default(uuid())
  name     String
  icon     String
  slug     String    @unique
  listings Listing[]
}

model Listing {
  id           String        @id @default(uuid())
  userId       String
  categoryId   String
  title        String
  description  String
  pricePerDay  Decimal       @db.Decimal(10, 2)
  location     String
  latitude     Decimal?      @db.Decimal(9, 6)
  longitude    Decimal?      @db.Decimal(9, 6)
  country      String?
  city         String?
  status       ListingStatus @default(ACTIVE)
  isApproved   Boolean       @default(false)  // admin must approve
  availableFrom DateTime?
  availableTo   DateTime?
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt

  user         User          @relation(fields: [userId], references: [id])
  category     Category      @relation(fields: [categoryId], references: [id])
  images       ListingImage[]
  bookings     Booking[]
  reviews      Review[]
  reports      Report[]      @relation("ListingReports")
}

model ListingImage {
  id        String  @id @default(uuid())
  listingId String
  imageUrl  String
  sortOrder Int     @default(0)

  listing   Listing @relation(fields: [listingId], references: [id])
}

model Booking {
  id          String        @id @default(uuid())
  listingId   String
  renterId    String
  ownerId     String
  startDate   DateTime
  endDate     DateTime
  totalPrice  Decimal       @db.Decimal(10, 2)
  status      BookingStatus @default(PENDING)
  // Payment fields — reserved for future Stripe integration
  // stripePaymentId String?
  // paidAt          DateTime?
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt

  listing     Listing       @relation(fields: [listingId], references: [id])
  renter      User          @relation("RenterBookings", fields: [renterId], references: [id])
  owner       User          @relation("OwnerBookings", fields: [ownerId], references: [id])
  review      Review?
}

model Review {
  id          String   @id @default(uuid())
  bookingId   String   @unique
  listingId   String
  reviewerId  String
  revieweeId  String
  rating      Int      // 1–5
  comment     String?
  createdAt   DateTime @default(now())

  booking     Booking  @relation(fields: [bookingId], references: [id])
  listing     Listing  @relation(fields: [listingId], references: [id])
  reviewer    User     @relation("ReviewsGiven", fields: [reviewerId], references: [id])
  reviewee    User     @relation("ReviewsReceived", fields: [revieweeId], references: [id])
}

model Report {
  id             String           @id @default(uuid())
  reporterId     String
  targetType     ReportTargetType
  targetListingId String?
  targetUserId   String?
  category       ReportCategory
  description    String?
  status         ReportStatus     @default(OPEN)
  adminNote      String?
  createdAt      DateTime         @default(now())
  updatedAt      DateTime         @updatedAt

  reporter       User             @relation("ReporterReports", fields: [reporterId], references: [id])
  targetListing  Listing?         @relation("ListingReports", fields: [targetListingId], references: [id])
  targetUser     User?            @relation("ReportedUserReports", fields: [targetUserId], references: [id])
}

model Notification {
  id        String   @id @default(uuid())
  userId    String
  title     String
  body      String
  type      String   // booking_update | new_message | payment | system
  isRead    Boolean  @default(false)
  data      Json?    // extra metadata (bookingId, listingId, etc.)
  createdAt DateTime @default(now())

  user      User     @relation(fields: [userId], references: [id])
}

model SupportTicket {
  id          String       @id @default(uuid())
  userId      String
  subject     String
  message     String
  status      TicketStatus @default(OPEN)
  adminReply  String?
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  user        User         @relation(fields: [userId], references: [id])
}
```

---

## API Endpoints

### Auth `/api/auth`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/register` | Register with email & password | ❌ |
| POST | `/login` | Login, returns JWT | ❌ |
| POST | `/google` | Google OAuth login/register | ❌ |
| POST | `/forgot-password` | Send OTP to email | ❌ |
| POST | `/verify-otp` | Verify OTP code | ❌ |
| POST | `/reset-password` | Reset password with valid OTP | ❌ |
| POST | `/logout` | Invalidate token (Redis blacklist) | ✅ |

### Users `/api/users`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/me` | Get current user profile | ✅ |
| PUT | `/me` | Update profile (name, phone, avatar) | ✅ |
| POST | `/me/verify` | Submit verification document | ✅ |
| PUT | `/me/fcm-token` | Update FCM token | ✅ |
| GET | `/:id` | Get public user profile | ❌ |

### Listings `/api/listings`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Browse listings (filters: category, location, price, date, country) | ❌ |
| GET | `/:id` | Get listing details | ❌ |
| POST | `/` | Create listing (rate-limited for unverified) | ✅ |
| PUT | `/:id` | Update listing | ✅ (owner) |
| DELETE | `/:id` | Delete listing | ✅ (owner) |
| PATCH | `/:id/status` | Pause / reactivate listing | ✅ (owner) |
| GET | `/my/listings` | Get current user's listings | ✅ |

### Bookings `/api/bookings`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/` | Create booking request | ✅ |
| GET | `/my` | Get current user's bookings (as renter) | ✅ |
| GET | `/incoming` | Get incoming bookings (as owner) | ✅ |
| PATCH | `/:id/accept` | Owner accepts booking | ✅ (owner) |
| PATCH | `/:id/cancel` | Cancel booking | ✅ |
| PATCH | `/:id/complete` | Mark booking as completed | ✅ (owner) |

### Categories `/api/categories`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Get all categories | ❌ |

### Reviews `/api/reviews`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/` | Submit review (after completed booking) | ✅ |
| GET | `/listing/:id` | Get reviews for a listing | ❌ |
| GET | `/user/:id` | Get reviews for a user | ❌ |

### Reports `/api/reports`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/` | Submit a report | ✅ |

### Notifications `/api/notifications`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Get all notifications for current user | ✅ |
| PATCH | `/:id/read` | Mark notification as read | ✅ |
| PATCH | `/read-all` | Mark all as read | ✅ |

### Support `/api/support`
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/tickets` | Create support ticket | ✅ |
| GET | `/tickets` | Get current user's tickets | ✅ |
| GET | `/tickets/:id` | Get ticket details | ✅ |

### Admin `/api/admin` *(requires ADMIN role)*
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/dashboard` | Stats: users, listings, bookings counts |
| GET | `/users` | List all users (filter by country, status) |
| GET | `/users/:id` | View user details |
| PATCH | `/users/:id/block` | Block / unblock user |
| PATCH | `/users/:id/verify` | Approve user verification |
| GET | `/listings` | List all listings (filter by country, status) |
| PATCH | `/listings/:id/approve` | Approve listing |
| DELETE | `/listings/:id` | Remove listing |
| GET | `/bookings` | List all bookings (filter by country) |
| GET | `/reports` | List all reports |
| PATCH | `/reports/:id` | Take action on report (warn/block/remove) |
| GET | `/reviews` | List all reviews |
| DELETE | `/reviews/:id` | Remove inappropriate review |
| GET | `/tickets` | List all support tickets |
| PATCH | `/tickets/:id/reply` | Reply to support ticket |
| GET | `/categories` | List categories |
| POST | `/categories` | Create category |
| PUT | `/categories/:id` | Update category |
| DELETE | `/categories/:id` | Delete category |

---

## Business Logic

### Listing Rate Limiting (Unverified Users)
- Max **2 listings per day**
- Max **5 listings per month**
- Listings with `pricePerDay > 1000 (INR or equivalent)` → require VERIFIED status
- High-value categories → require VERIFIED status
- Limits are **configurable from admin panel** (store in Redis or a config table)

### Booking Flow
```
Renter requests booking → PENDING
Owner accepts → ACCEPTED
Renter confirms → CONFIRMED
Item returned → COMPLETED (owner marks)
Either party cancels → CANCELLED
```
No payment step in MVP. Payment fields reserved in schema for future.

### Location & Currency
- On register/login, detect country from IP using a geolocation library (e.g. `geoip-lite`)
- Map country → currency code (e.g. IN → INR, SG → SGD, US → USD)
- Store `country` and `currency` on user record
- Listings inherit country/city from user's location at post time
- Users can manually override their location

### Verification Flow
- User uploads ID document → stored in Cloudinary
- Record updated: `verificationStatus = PENDING`
- Admin reviews and approves → `verificationStatus = VERIFIED`
- Verified badge shown on profile and listings

---

## Environment Variables (`.env`)
```env
DATABASE_URL=postgresql://user:password@localhost:5432/renthubindia
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
APP_NAME=RentHubIndia
CLIENT_URL=http://localhost:3000
```

---

## Security Notes
- All passwords hashed with **bcrypt** (salt rounds: 12)
- JWT stored in `flutter_secure_storage` on device
- Invalidated JWTs stored in **Redis blacklist** on logout
- All admin routes protected by role middleware
- OTPs expire after **10 minutes** and are single-use
- Input validation on all routes using **Zod** or **express-validator**
- Rate limiting on auth routes to prevent brute force

---

## Future-Ready Architecture Notes
- **Payments**: Booking model already has commented `stripePaymentId` and `paidAt` fields — just uncomment and add Stripe service
- **Ads / Featured Listings**: Add `isFeatured` boolean and `featuredUntil` date to Listing model
- **Subscriptions**: Add a `Subscription` model linked to User
- **Commission**: Add `platformFee` and `commissionRate` fields to Booking
- **Multi-language**: All user-facing strings should use i18n keys from day one
