# RentHubIndia Backend API 🏠

> **Production-ready RESTful API** for the RentHubIndia peer-to-peer rental marketplace — where users can list, discover, and rent items from one another across multiple categories.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Folder Structure](#folder-structure)
4. [Tech Stack](#tech-stack)
5. [Modules Explained](#modules-explained)
   - [Auth](#auth-module)
   - [Users](#users-module)
   - [Categories](#categories-module)
   - [Listings](#listings-module)
   - [Bookings](#bookings-module)
   - [Reviews](#reviews-module)
   - [Reports](#reports-module)
   - [Notifications](#notifications-module)
   - [Support](#support-module)
   - [Admin](#admin-module)
6. [Middleware & Security](#middleware--security)
7. [Utilities](#utilities)
8. [Environment Variables](#environment-variables)
9. [Installation & Setup](#installation--setup)
10. [Running the Server](#running-the-server)
11. [API Documentation](#api-documentation)
12. [Testing](#testing)
13. [Key Business Logic](#key-business-logic)
14. [Default Credentials](#default-credentials)

---

## Project Overview

**RentHubIndia** is a rental marketplace platform similar to Airbnb but for everyday items — electronics, vehicles, furniture, tools, clothing, and more. Users can:

- **List** items for rent with pricing, images, and availability
- **Browse** and **book** items from other users
- **Review** owners and renters after completed rentals
- **Report** suspicious listings or users to admins
- **Chat** support with the admin team via tickets
- Receive **real-time push notifications** at every stage of the rental flow

The backend is a fully decoupled REST API designed to be consumed by mobile (iOS/Android) and web frontends.

---

## Architecture

The codebase follows a **modular, domain-driven architecture**. Each feature domain is encapsulated inside its own folder containing:

```
module/
  ├── module.service.js     # Business logic (Prisma queries, calculations)
  ├── module.controller.js  # HTTP handlers (req/res wrappers)
  ├── module.routes.js      # Express router + Swagger JSDoc annotations
  └── module.validation.js  # Zod schemas for request body validation
```

This separation ensures:
- **Controllers** never contain business logic — they only call services and format responses
- **Services** are pure logic — testable without HTTP context
- **Validation** is always enforced before the service layer is reached
- **Routes** are the only place that knows about middleware ordering

### Request Flow

```
Client Request
  → Express Router
    → Rate Limiter (if auth route)
    → Auth Middleware (JWT verification + isBlocked check)
    → Role Middleware (if admin-only route)
    → Zod Validation
      → Controller
        → Service (Prisma / Redis / Firebase / Cloudinary)
          → Response
```

---

## Folder Structure

```
RentHubIndia_Backend/
├── prisma/
│   ├── schema.prisma        # Database schema (all models & enums)
│   ├── seed.js              # Seeds default categories + admin user
│   └── migrations/          # Auto-generated migration history
├── prisma.config.js         # Prisma v7 config (datasource URL, seed command)
├── src/
│   ├── app.js               # Express app setup (middleware + router mounting)
│   ├── server.js            # Entry point (starts HTTP server)
│   ├── config/
│   │   ├── db.js            # Prisma client (with pg adapter for Neon)
│   │   ├── redis.js         # ioredis client (Upstash)
│   │   ├── cloudinary.js    # Cloudinary + Multer upload config
│   │   ├── firebase.js      # Firebase Admin SDK init
│   │   ├── passport.js      # Google OAuth2 strategy
│   │   └── swagger.js       # Swagger/OpenAPI spec config
│   ├── middleware/
│   │   ├── auth.js          # JWT verification + isBlocked circuit breaker
│   │   ├── role.js          # requireAdmin role guard
│   │   ├── rateLimit.js     # authRateLimiter + listingRateLimiter
│   │   └── errorHandler.js  # Global error handler
│   ├── utils/
│   │   ├── jwt.js           # signToken / verifyToken helpers
│   │   ├── otp.js           # OTP generation + email delivery
│   │   ├── mailer.js        # Nodemailer SMTP transporter
│   │   ├── fcm.js           # Firebase Cloud Messaging push sender
│   │   └── currency.js      # IP-based country/currency detection
│   └── modules/
│       ├── auth/            # Registration, login, OAuth, OTP, logout
│       ├── users/           # Profile, avatar, verification, FCM token
│       ├── categories/      # Public category listing
│       ├── listings/        # Marketplace listings CRUD + images
│       ├── bookings/        # Rental booking lifecycle
│       ├── reviews/         # Post-booking review system
│       ├── reports/         # User/listing flagging system
│       ├── notifications/   # In-app notification feed
│       ├── support/         # Help desk ticket system
│       └── admin/           # Full admin control panel
├── tests/
│   └── auth.test.js         # Jest unit tests (Prisma mocked)
├── .env                     # Local secrets (never committed)
├── .env.example             # Template for environment variables
├── .gitignore
├── package.json
├── README.md
└── API_DOCS.md              # Markdown endpoint reference
```

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Runtime | Node.js v18+ | JavaScript server runtime |
| Framework | Express v5 | HTTP routing and middleware |
| ORM | Prisma v7 | Type-safe database access |
| Database | PostgreSQL (Neon) | Primary data store (serverless) |
| Cache | Redis (Upstash) | JWT blacklist + listing rate limits |
| Auth | JWT + Passport.js | Stateless auth + Google OAuth2 |
| Push Notifications | Firebase Admin (FCM) | Mobile push notifications |
| Image Storage | Cloudinary + Multer | Multi-image upload pipeline |
| Email | Nodemailer + Gmail SMTP | OTP + transactional emails |
| Validation | Zod | Runtime request schema validation |
| Geo-detection | geoip-lite | IP → country/currency mapping |
| API Docs | Swagger UI + swagger-jsdoc | Interactive documentation |
| Testing | Jest + Supertest | Unit and integration tests |
| Security | Helmet, CORS, express-rate-limit | HTTP hardening |

---

## Modules Explained

### Auth Module

**Base route:** `/api/auth`

Handles the complete authentication lifecycle.

| Endpoint | Description |
|---|---|
| `POST /register` | Creates a new user account, hashes password with bcrypt (12 rounds), returns JWT |
| `POST /login` | Validates credentials, returns JWT |
| `GET /google` | Redirects to Google OAuth2 consent screen |
| `GET /google/callback` | Handles Google callback, creates/finds user, returns JWT |
| `POST /forgot-password` | Generates a 6-digit OTP, sends it via email, stores it in DB with 10-minute expiry |
| `POST /verify-otp` | Validates OTP, marks it as `used = true` (single-use), returns a reset token |
| `POST /reset-password` | Accepts reset token + new password, updates hash |
| `POST /logout` | Blacklists current JWT in Redis so it can't be reused before expiry |

**Security features:**
- Rate limited to **10 requests per 15 minutes** per IP
- OTPs expire in **10 minutes** and are **single-use**
- JWT tokens are signed with a strong secret and expire in 7 days
- Logged-out tokens are stored in Redis blacklist and checked on every request

---

### Users Module

**Base route:** `/api/users`

Manages user profiles and account-level features.

| Endpoint | Description |
|---|---|
| `GET /profile` | Returns the authenticated user's full profile |
| `PUT /profile` | Updates name, phone, bio, and other profile fields |
| `POST /avatar` | Uploads a profile photo to Cloudinary, stores URL in DB |
| `POST /fcm-token` | Saves device FCM token for push notification delivery |
| `POST /me/verify` | Uploads a KYC document (ID/passport) to Cloudinary, sets `verificationStatus = PENDING` |
| `GET /:id` | Public profile view — shows name, rating, join date |
| `GET /` | Admin only — paginated list of all users |
| `PATCH /:id/block` | Admin only — toggles user block status |

**Verification flow:**
1. User uploads document → `PENDING`
2. Admin reviews → sets to `VERIFIED`
3. `VERIFIED` users unlock the ability to list items above **$1,000/day**

---

### Categories Module

**Base route:** `/api/categories`

Public, read-only endpoint. Returns the platform's taxonomy for the frontend navigation.

Default categories seeded on first deployment:
- 💻 Electronics
- 🚗 Vehicles
- 🛋️ Furniture
- ⚽ Sports & Outdoors
- 👗 Apparel & Fashion
- 🔨 Tools & Hardware

Admins can add, edit, or remove categories via the Admin module without any code changes.

---

### Listings Module

**Base route:** `/api/listings`

The core marketplace module. Handles all item listings.

| Endpoint | Description |
|---|---|
| `GET /` | Browse all approved, active listings. Supports filtering by category, country, price range |
| `GET /:id` | View a single listing with full details and images |
| `GET /my/listings` | Owner's own listings (all statuses) |
| `POST /` | Create a new listing — requires `categoryId`, `title`, `description`, `pricePerDay` |
| `PUT /:id` | Update a listing (owner only) |
| `DELETE /:id` | Delete a listing (owner only) |
| `PATCH /:id/status` | Toggle listing between `ACTIVE` and `PAUSED` |
| `POST /:id/images` | Upload up to **5 images** via Cloudinary (multipart/form-data) |

**Business rules:**
- New listings start with `isApproved = false` — admin must approve before they appear publicly
- **Unverified users** are rate-limited by Redis:
  - Max **2 listings per day**
  - Max **5 listings per month**
- Listings priced above **$1,000/day** require `verificationStatus = VERIFIED`
- Geography (country, city, currency) is automatically inherited from the owner's profile

**Listing status lifecycle:**
```
ACTIVE  ←→  PAUSED  →  EXPIRED
```

---

### Bookings Module

**Base route:** `/api/bookings`

Manages the full rental lifecycle between renters and owners.

| Endpoint | Description |
|---|---|
| `POST /` | Renter creates a booking request for a listing with start/end dates |
| `GET /my` | Renter's outgoing booking history |
| `GET /incoming` | Owner's incoming booking requests on their listings |
| `PATCH /:id/accept` | Owner accepts the booking |
| `PATCH /:id/cancel` | Either party cancels the booking |
| `PATCH /:id/complete` | Owner marks the rental as completed |

**Booking state machine:**
```
PENDING → ACCEPTED → COMPLETED
   ↓          ↓
CANCELLED  CANCELLED
```

**Business logic:**
- **Date overlap protection:** New bookings are rejected if the listing already has an accepted booking for overlapping dates
- **Automatic pricing:** `totalPrice = pricePerDay × numberOfDays`
- **FCM notifications** are sent at every state transition:
  - Owner notified when a new booking arrives
  - Renter notified when booking is accepted or cancelled
  - Renter prompted to leave a review after completion

---

### Reviews Module

**Base route:** `/api/reviews`

Enables trust between users through post-rental feedback.

| Endpoint | Description |
|---|---|
| `GET /listing/:id` | All reviews for a specific listing |
| `GET /user/:id` | All reviews received by a specific user |
| `POST /` | Submit a review (restricted to completed bookings) |

**Business rules:**
- Reviews can **only be submitted** for bookings with `status = COMPLETED`
- Each completed booking can only be reviewed **once**
- After every new review, the system automatically **recalculates the owner's average rating** using a Prisma aggregate query and stores it on the `User` record
- Rating scale: **1–5 stars**

---

### Reports Module

**Base route:** `/api/reports`

Allows users to flag problematic content for admin review.

| Endpoint | Description |
|---|---|
| `POST /` | Submit a report against a listing, user, or message |

**Report categories:** `FRAUD`, `SPAM`, `ABUSE`, `FAKE_LISTING`

**Target types:** `LISTING`, `USER`, `MESSAGE`

All reports start as `OPEN` and are resolved by admins via the Admin module.

---

### Notifications Module

**Base route:** `/api/notifications`

In-app notification feed. Automatically populated by other services (bookings, admin actions, etc.) via the internal `createNotification()` helper.

| Endpoint | Description |
|---|---|
| `GET /` | All notifications for the authenticated user (newest first) |
| `PATCH /read-all` | Mark all unread notifications as read |
| `PATCH /:id/read` | Mark a single notification as read |

> Note: Push notifications (FCM) and in-app notifications (this module) operate in parallel — a booking event triggers both.

---

### Support Module

**Base route:** `/api/support/tickets`

Help desk ticketing system for user support.

| Endpoint | Description |
|---|---|
| `POST /tickets` | Open a new support ticket (`status = OPEN`) |
| `GET /tickets` | All of the user's own tickets |
| `GET /tickets/:id` | Single ticket (ownership enforced — users can only read their own) |

Admins can reply to and resolve tickets via `PATCH /api/admin/support/tickets/:id/reply`, which:
1. Sets `adminReply` text on the ticket
2. Changes `status → RESOLVED`
3. Sends an FCM push notification to the user

---

### Admin Module

**Base route:** `/api/admin`  
**Access:** Requires `role = ADMIN` — all routes protected by both JWT auth and admin role guard.

The admin module is the master control panel for the entire platform.

#### Dashboard
| Endpoint | Description |
|---|---|
| `GET /dashboard` | Platform-wide stats: total users, listings, bookings, open reports |

#### User Management
| Endpoint | Description |
|---|---|
| `GET /users` | Paginated list of all users with filters |
| `GET /users/:id` | Full user record |
| `PATCH /users/:id/block` | Toggle `isBlocked` — immediately kills active sessions |
| `PATCH /users/:id/verify` | Approve KYC → sets `verificationStatus = VERIFIED` + sends FCM notification |

#### Listing Moderation
| Endpoint | Description |
|---|---|
| `GET /listings` | All listings regardless of approval status |
| `PATCH /listings/:id/approve` | Approve a listing → sets `isApproved = true` + notifies owner |
| `DELETE /listings/:id` | Hard delete with cascade (removes images, bookings, reviews) |

#### Content Moderation
| Endpoint | Description |
|---|---|
| `GET /reports` | All reports with reporter info |
| `PATCH /reports/:id/action` | Set report status to `REVIEWED` or `RESOLVED` + notifies reporter |
| `GET /reviews` | All reviews across the platform |
| `DELETE /reviews/:id` | Delete a review + auto-recalculates owner's average rating |

#### Support & Tickets
| Endpoint | Description |
|---|---|
| `GET /support/tickets` | All support tickets |
| `PATCH /support/tickets/:id/reply` | Reply to ticket + mark `RESOLVED` + notify user |

#### Category Management (Full CRUD)
| Endpoint | Description |
|---|---|
| `GET /categories` | All categories |
| `POST /categories` | Create a new category |
| `PUT /categories/:id` | Update an existing category |
| `DELETE /categories/:id` | Delete a category |

---

## Middleware & Security

### `auth.js` — JWT Authentication + Block Check
Every protected route passes through this middleware:
1. Extracts `Bearer <token>` from the `Authorization` header
2. Checks if token is in the **Redis blacklist** (logged-out tokens)
3. Verifies the JWT signature and expiry
4. Queries the database to confirm `isBlocked = false`
5. Injects `req.user` (decoded payload) for downstream use

> If a user is blocked after they already have a valid token, the block takes effect **immediately** on the next request.

### `role.js` — Admin Guard
Simple middleware that checks `req.user.role === 'ADMIN'`. Returns `403` if not.

### `rateLimit.js` — Two Rate Limiters
- **`authRateLimiter`**: Express rate limit — 10 requests per 15 minutes per IP on all `/api/auth` routes (prevents brute force)
- **`listingRateLimiter`**: Redis-backed custom limiter — tracks listing creation per user per day/month (unverified users only)

### `errorHandler.js` — Global Error Handler
The last middleware in the Express chain. Catches all unhandled errors and returns a consistent `{ success: false, message }` JSON response. Prevents stack traces from leaking to clients.

---

## Utilities

| File | Purpose |
|---|---|
| `jwt.js` | `signToken(payload)` and `verifyToken(token)` wrappers around `jsonwebtoken` |
| `otp.js` | Generates a 6-digit OTP, stores it in DB with 10-minute expiry, sends email |
| `mailer.js` | Nodemailer transporter configured for Gmail SMTP |
| `fcm.js` | `sendPushNotification(fcmToken, title, body, data)` — wraps Firebase Admin messaging |
| `currency.js` | Detects country from IP using `geoip-lite`, maps to currency code |

---

## Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | Neon PostgreSQL connection string |
| `REDIS_URL` | ✅ | Upstash Redis URL (`rediss://...`) |
| `JWT_SECRET` | ✅ | Strong random string for JWT signing |
| `JWT_EXPIRES_IN` | ✅ | Token lifetime e.g. `7d` |
| `GOOGLE_CLIENT_ID` | ✅ | Google Cloud Console OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | ✅ | Google Cloud Console OAuth secret |
| `FIREBASE_PROJECT_ID` | ✅ | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | ✅ | Firebase service account private key (with `\n` newlines) |
| `FIREBASE_CLIENT_EMAIL` | ✅ | Firebase service account email |
| `CLOUDINARY_CLOUD_NAME` | ✅ | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | ✅ | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | ✅ | Cloudinary API secret |
| `EMAIL_HOST` | ✅ | SMTP host — `smtp.gmail.com` |
| `EMAIL_PORT` | ✅ | SMTP port — `587` |
| `EMAIL_USER` | ✅ | Gmail address |
| `EMAIL_PASS` | ✅ | 16-char Gmail App Password (no spaces, no dashes) |
| `APP_NAME` | ✅ | App name used in emails — `RentHubIndia` |
| `CLIENT_URL` | ✅ | Frontend origin for CORS — `http://localhost:3000` |

### How to get each credential

**Gmail App Password:**
1. Enable 2-Factor Authentication on your Google account
2. Go to Google Account → Security → App Passwords
3. Create a new app password → copy the 16-character code (no spaces)

**Firebase Service Account:**
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key" → download JSON
3. Copy `project_id`, `private_key`, `client_email` from the JSON

**Neon Database:**
1. Sign up at [neon.tech](https://neon.tech)
2. Create a project → copy the connection string from the dashboard

**Upstash Redis:**
1. Sign up at [upstash.com](https://upstash.com)
2. Create a Redis database → copy the `REDIS_URL`

**Cloudinary:**
1. Sign up at [cloudinary.com](https://cloudinary.com)
2. Dashboard → copy Cloud Name, API Key, API Secret

---

## Installation & Setup

### Prerequisites
- Node.js v18 or higher
- npm v9 or higher
- A Neon PostgreSQL database
- An Upstash Redis database
- A Firebase project with Admin SDK
- A Cloudinary account
- A Gmail account with App Password enabled

### Steps

```bash
# 1. Clone the repository
git clone <repo-url>
cd RentHubIndia_Backend

# 2. Install all dependencies
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env and fill in all values

# 4. Push the Prisma schema to your Neon database
npx prisma db push

# 5. Regenerate the Prisma client
npx prisma generate

# 6. Seed the database with default data
npx prisma db seed
# This creates 6 categories + 1 admin account
```

---

## Running the Server

```bash
# Development mode (auto-restarts on file changes)
npm run dev

# Production mode
npm run start
```

Server starts on **`http://localhost:5000`**

Health check: `GET http://localhost:5000/api/health`

---

## API Documentation

Interactive Swagger UI is available while the server is running:

**`http://localhost:5000/api-docs`**

Features:
- Browse all endpoints grouped by module
- Expand each endpoint to see request/response schema
- Click **Authorize** (top right) and paste your JWT token to test protected endpoints
- Click **Try it out** → fill in the form → **Execute** to make live requests

For a static reference, see [`API_DOCS.md`](./API_DOCS.md).

---

## Testing

```bash
npm run test
```

Tests use `jest` with `jest-mock-extended` to mock the Prisma client — meaning tests run **without a real database connection**, making them fast and safe for CI/CD.

Current test coverage:
- **Auth service:** Registration duplicate email detection, new user creation flow

To add more tests, create files in the `tests/` directory following the `*.test.js` naming convention.

---

## Key Business Logic

### The Verification Threshold System
Users are split into two tiers:
- **Unverified** (`UNVERIFIED` / `PENDING`): Can create listings, but capped at 2/day and 5/month. Cannot list items above $1,000/day.
- **Verified** (`VERIFIED`): No rate limits. Can list items at any price.

This prevents spam listings while giving legitimate power users full flexibility after identity verification.

### The Booking Lifecycle
The system enforces a strict state machine to prevent double-bookings and ensure fair rental flows:
1. Renter requests booking → `PENDING`
2. Owner accepts → `ACCEPTED` (date range is now locked — no other bookings for same dates)
3. Rental happens
4. Owner marks complete → `COMPLETED`
5. Renter is prompted to leave a review via FCM push notification

If either party cancels at any stage, the dates are freed back up for new bookings.

### The Rating System
User ratings are not stored as static numbers — they are **recalculated every time a review is submitted or deleted**:
```
userRating = AVG(rating) of all reviews where revieweeId = userId
```
This ensures ratings always reflect the true current state, even when admins delete fraudulent reviews.

### The Block Circuit Breaker
JWT tokens are stateless by design — normally they remain valid until expiry. To address this, every request to a protected endpoint checks `isBlocked` in the database. If an admin blocks a user:
- Their token is **immediately invalidated** on the next API call
- They receive a `403 Account suspended` response
- No token refresh can bypass this — only unblocking restores access

---

## Default Credentials

After running `npx prisma db seed`:

| Field | Value |
|---|---|
| Email | `admin@renthubindia.com` |
| Password | `Admin@1234` |
| Role | `ADMIN` |
| Verification | `VERIFIED` |

> ⚠️ **Change this password before deploying to production.**
