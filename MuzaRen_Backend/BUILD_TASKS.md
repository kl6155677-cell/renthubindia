# RentHubIndia Backend — Ordered Build Tasks

> This file lists every task needed to build the RentHubIndia backend API,
> in the exact order they should be implemented. Each task is grouped
> into a phase. Complete each phase before starting the next.

---

## ✅ PHASE 0 — Foundation (Already Done)

- [x] Initialize Node.js project (`package.json`)
- [x] Install Prisma and `@prisma/client`
- [x] Write `prisma/schema.prisma` with all models and enums
- [x] Configure `prisma.config.ts` for Prisma 7 (connection URL moved out of schema)
- [x] Set up `.env` with `DATABASE_URL` pointing to Neon PostgreSQL

---

## ✅ PHASE 1 — Project Setup & Core Infrastructure (Done)

### 1.1 Install All Dependencies
- [ ] Install runtime packages:
  ```
  express dotenv bcryptjs jsonwebtoken passport passport-google-oauth20
  geoip-lite nodemailer firebase-admin redis ioredis zod cors helmet morgan
  express-rate-limit uuid cloudinary multer multer-storage-cloudinary
  ```
- [ ] Install dev packages:
  ```
  nodemon
  ```

### 1.2 Create Folder Structure
- [ ] Create `src/config/`
- [ ] Create `src/middleware/`
- [ ] Create `src/modules/auth/`
- [ ] Create `src/modules/users/`
- [ ] Create `src/modules/listings/`
- [ ] Create `src/modules/bookings/`
- [ ] Create `src/modules/categories/`
- [ ] Create `src/modules/reviews/`
- [ ] Create `src/modules/reports/`
- [ ] Create `src/modules/notifications/`
- [ ] Create `src/modules/support/`
- [ ] Create `src/modules/admin/`
- [ ] Create `src/utils/`

### 1.3 Environment Variables
- [ ] Add all required keys to `.env`:
  - `REDIS_URL`
  - `JWT_SECRET`, `JWT_EXPIRES_IN`
  - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
  - `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL`
  - `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
  - `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`
  - `APP_NAME`, `CLIENT_URL`



## ✅ PHASE 2 — Config Layer (Done)

- [x] **`db.js`** — Export a singleton Prisma Client instance
- [x] **`redis.js`** — Connect to Redis via `ioredis`, export client
- [x] **`firebase.js`** — Initialize Firebase Admin SDK using service account env vars; export `firebaseAdmin` and `messaging`
- [x] **`cloudinary.js`** — Configure Cloudinary client and `multer` storage wrapper; export `cloudinary` and upload middleware
- [x] **`passport.js`** — Configure Google OAuth 2.0 strategy using Passport.js

---

## ✅ PHASE 3 — Middleware (Done)

- [x] **`auth.js`** — JWT verification middleware
  - Reads `Authorization: Bearer <token>` header
  - Verifies token with `JWT_SECRET`
  - Checks Redis blacklist for invalidated tokens
  - Attaches `req.user` on success
- [x] **`role.js`** — Role guard middleware
  - `requireAdmin` — blocks non-ADMIN users with 403
- [x] **`rateLimit.js`** — Listing rate limiter for unverified users
  - Max 2 listings/day, max 5 listings/month (read limits from Redis config key)
- [x] **`errorHandler.js`** — Global Express error handler
  - Returns structured JSON errors with status codes

---

## ✅ PHASE 4 — Utilities (Done)

- [x] **`jwt.js`** — `signToken(userId)` and `verifyToken(token)` helpers
- [x] **`otp.js`** — `generateOTP()` (6-digit, expires in 10 min) and `verifyOTP(userId, code)` using DB
- [x] **`mailer.js`** — Nodemailer transporter; `sendOtpEmail(to, code)` and `sendNotificationEmail(to, subject, body)`
- [x] **`fcm.js`** — `sendPushNotification(fcmToken, title, body, data)` via Firebase Messaging
- [x] **`currency.js`** — Country code → currency code map (IN→INR, SG→SGD, US→USD, MY→MYR, etc.)

---

## ✅ PHASE 5 — App Bootstrap (Done)

- [x] **`src/app.js`** — Set up Express app:
  - `helmet()` — security headers
  - `cors()` — allow frontend origin from `CLIENT_URL`
  - `morgan()` — request logging
  - `express.json()` — JSON body parsing
  - Global rate limiting on `/api/auth` routes
  - Mount all module routers under `/api`
  - Mount `errorHandler` as the last middleware
- [x] **`server.js`** — Entry point: import app, connect DB and Redis, start listening on `PORT`

---

## ✅ PHASE 6 — Auth Module (Done)

**Service (`auth.service.js`):**
- [x] `register(name, email, password)` — hash password with bcrypt (12 rounds), create User, return JWT
- [x] `login(email, password)` — find user, compare hash, return JWT
- [x] `googleLogin(googleProfile)` — find or create user by `googleId`, return JWT
- [x] `forgotPassword(email)` — generate OTP, store in DB, send via email
- [x] `verifyOtp(email, code)` — validate OTP from DB (10-min expiry, single-use)
- [x] `resetPassword(email, code, newPassword)` — verify OTP then update `passwordHash`
- [x] `logout(token)` — add token to Redis blacklist with remaining TTL

**Controller + Routes:**
- [x] `POST /api/auth/register`
- [x] `POST /api/auth/login`
- [x] `GET /api/auth/google` (Passport Google OAuth)
- [x] `POST /api/auth/forgot-password`
- [x] `POST /api/auth/verify-otp`
- [x] `POST /api/auth/reset-password`
- [x] `POST /api/auth/logout` *(auth required)*

**Validation:** Zod schemas for all request bodies

---

## ✅ PHASE 7 — Users Module (Done)

**Service (`users.service.js`):**
- [x] `getProfile(userId)` — return user data (exclude passwordHash)
- [x] `updateProfile(userId, data)` — update name, phone, bio, avatarUrl
- [x] `submitVerification(userId, docUrl)` — set `verificationStatus = PENDING`, store doc URL
- [x] `updateFcmToken(userId, token)` — update `fcmToken` field
- [x] `getPublicProfile(targetUserId)` — return public fields (no email/passwordHash)
- [x] `getAllUsers(filters)` — admin only
- [x] `blockUser(userId)` — admin only

**Controller + Routes:**
- [x] `GET /api/users/profile` *(auth)*
- [x] `PUT /api/users/profile` *(auth)*
- [x] `POST /api/users/avatar` *(auth, multer middleware) — upload avatar*
- [x] `POST /api/users/fcm-token` *(auth)*
- [x] `GET /api/users/:id` *(public profile)*
- [x] `POST /api/users/me/verify` *(auth)*
- [x] `GET /api/users` *(auth, admin)*
- [x] `PATCH /api/users/:id/block` *(auth, admin)*

---

## ✅ PHASE 8 — Categories Module (Done)

**Service:**
- [x] `getAllCategories()` — return all categories

**Controller + Routes:**
- [x] `GET /api/categories`

> Admin can create/update/delete categories — covered in Admin phase.

---

## ✅ PHASE 9 — Listings Module (Done)

**Service (`listings.service.js`):**
- [x] `browseListings(filters)` — filter by `category`, `location`, `priceMin/Max`, `availableFrom/To`, `country`, `city`; only approved + active; paginated
- [x] `getListingById(id)` — return listing + images + category + owner (public fields)
- [x] `createListing(userId, data, userProfile)`:
  - Check rate limit via `rateLimit.js` middleware (unverified users)
  - Check if price > 1000 or high-value category → require VERIFIED
  - Inherit `country`/`city` from user's current location
  - Set `isApproved = false` (admin must approve)
- [x] `updateListing(userId, listingId, data)` — owner only
- [x] `deleteListing(userId, listingId)` — owner only
- [x] `updateListingStatus(userId, listingId, status)` — pause/reactivate
- [x] `getMyListings(userId)` — return all of current user's listings
- [x] `uploadListingImages(userId, listingId, files)` — upload max 5 images to Cloudinary 

**Controller + Routes:**
- [x] `GET /api/listings`
- [x] `GET /api/listings/my/listings` *(auth)*
- [x] `GET /api/listings/:id`
- [x] `POST /api/listings` *(auth + rate limit)*
- [x] `PUT /api/listings/:id` *(auth, owner)*
- [x] `DELETE /api/listings/:id` *(auth, owner)*
- [x] `PATCH /api/listings/:id/status` *(auth, owner)*
- [x] `POST /api/listings/:id/images` *(auth, owner, multer max 5)*

---

## ✅ PHASE 10 — Bookings Module (Done)

**Booking Flow:**
```
PENDING → ACCEPTED → COMPLETED
                   → CANCELLED (any party)
```

**Service (`bookings.service.js`):**
- [x] `createBooking(renterId, listingId, startDate, endDate)`:
  - Validate listing is ACTIVE + APPROVED
  - Check no date overlap with existing ACCEPTED/CONFIRMED bookings
  - Calculate `totalPrice = pricePerDay × days`
  - Set `ownerId` from listing
  - Send push notification to owner
- [x] `getMyBookings(userId)` — bookings where `renterId = userId`
- [x] `getIncomingBookings(userId)` — bookings where `ownerId = userId`
- [x] `acceptBooking(ownerId, bookingId)` — set `ACCEPTED`, notify renter
- [x] `cancelBooking(userId, bookingId)` — either party, set `CANCELLED`, notify other party
- [x] `completeBooking(ownerId, bookingId)` — set `COMPLETED`, notify renter

**Controller + Routes:**
- [x] `POST /api/bookings` *(auth)*
- [x] `GET /api/bookings/my` *(auth)*
- [x] `GET /api/bookings/incoming` *(auth)*
- [x] `PATCH /api/bookings/:id/accept` *(auth, owner)*
- [x] `PATCH /api/bookings/:id/cancel` *(auth)*
- [x] `PATCH /api/bookings/:id/complete` *(auth, owner)*

---

## ✅ PHASE 11 — Reviews Module (Done)

**Service (`reviews.service.js`):**
- [x] `submitReview(reviewerId, bookingId, rating, comment)`:
  - Validate booking is `COMPLETED`
  - Validate reviewer was part of the booking
  - Prevent duplicate review (booking has `@unique` constraint)
  - Update reviewee's `rating` average on User model
- [x] `getListingReviews(listingId)` — paginated
- [x] `getUserReviews(userId)` — paginated

**Controller + Routes:**
- [x] `POST /api/reviews` *(auth)*
- [x] `GET /api/reviews/listing/:id`
- [x] `GET /api/reviews/user/:id`

---

## ✅ PHASE 12 — Reports Module (Done)

**Service (`reports.service.js`):**
- [x] `submitReport(reporterId, targetType, targetId, category, description)`:
  - `targetType`: `LISTING | USER | MESSAGE`
  - Set `status = OPEN`

**Controller + Routes:**
- [x] `POST /api/reports` *(auth)*

---

## ✅ PHASE 13 — Notifications Module (Done)

**Service (`notifications.service.js`):**
- [x] `createNotification(userId, title, body, type, data)` — internal helper used by other services
- [x] `getUserNotifications(userId)` — return all notifications, newest first
- [x] `markAsRead(userId, notificationId)`
- [x] `markAllAsRead(userId)`

**Controller + Routes:**
- [x] `GET /api/notifications` *(auth)*
- [x] `PATCH /api/notifications/:id/read` *(auth)*
- [x] `PATCH /api/notifications/read-all` *(auth)*

---

## ✅ PHASE 14 — Support Module (Done)

**Service (`support.service.js`):**
- [x] `createTicket(userId, subject, message)` — set `status = OPEN`
- [x] `getMyTickets(userId)` — return user's own tickets
- [x] `getTicketById(userId, ticketId)` — return single ticket (must belong to user)

**Controller + Routes:**
- [x] `POST /api/support/tickets` *(auth)*
- [x] `GET /api/support/tickets` *(auth)*
- [x] `GET /api/support/tickets/:id` *(auth)*

---

## ✅ PHASE 15 — Admin Module (Done)

> All routes require `auth` + `requireAdmin` middleware.

**Service (`admin.service.js`):**

**Dashboard:**
- [x] `getDashboardStats()` — count users, listings, bookings (total + by status)

**Users:**
- [x] `listUsers(filters)` — filter by country, blocked status; paginated
- [x] `getUserById(id)` — full user details
- [x] `toggleBlockUser(userId)` — flip `isBlocked`
- [x] `approveVerification(userId)` — set `verificationStatus = VERIFIED`

**Listings:**
- [x] `listAllListings(filters)` — filter by country, status; paginated
- [x] `approveListing(listingId)` — set `isApproved = true`
- [x] `deleteListing(listingId)` — hard delete (or soft delete)

**Bookings:**
- [x] `listAllBookings(filters)` — filter by country, status

**Reports:**
- [x] `listReports()` — all reports with target info
- [x] `actionReport(reportId, status, adminNote)` — set REVIEWED / RESOLVED

**Reviews:**
- [x] `listAllReviews()` — all reviews
- [x] `deleteReview(reviewId)` — remove inappropriate review

**Support Tickets:**
- [x] `listAllTickets()` — all tickets; filter by status
- [x] `replyToTicket(ticketId, adminReply)` — set reply + status = RESOLVED

**Categories:**
- [x] `listCategories()` — all categories
- [x] `createCategory(name, icon, slug)`
- [x] `updateCategory(id, data)`
- [x] `deleteCategory(id)`

**Controller + Routes:**
- [x] `GET /api/admin/dashboard`
- [x] `GET /api/admin/users`
- [x] `GET /api/admin/users/:id`
- [x] `PATCH /api/admin/users/:id/block`
- [x] `PATCH /api/admin/users/:id/verify`
- [x] `GET /api/admin/listings`
- [x] `PATCH /api/admin/listings/:id/approve`
- [x] `DELETE /api/admin/listings/:id`
- [x] `GET /api/admin/bookings`
- [x] `GET /api/admin/reports`
- [x] `PATCH /api/admin/reports/:id/action`
- [x] `GET /api/admin/reviews`
- [x] `DELETE /api/admin/reviews/:id`
- [x] `GET /api/admin/support/tickets`
- [x] `PATCH /api/admin/support/tickets/:id/reply`
- [x] `GET /api/admin/categories`
- [x] `POST /api/admin/categories`
- [x] `PUT /api/admin/categories/:id`
- [x] `DELETE /api/admin/categories/:id`

---

## ✅  PHASE 16 — Seed Data (Done)

- [x] Create `prisma/seed.js`:
  - Seed default categories (Electronics, Vehicles, Furniture, Sports, Clothes, Tools, etc.)
  - Seed a default ADMIN user
- [x] Add `"prisma": { "seed": "node prisma/seed.js" }` to `package.json`
- [x] Run `npx prisma db seed`

---

## ✅ PHASE 17 — Security Hardening (Done)

- [x] Add `express-rate-limit` globally on `/api/auth` routes (max 10 req/15min)
- [x] Validate all request bodies with **Zod** schemas in every module
- [x] Sanitize inputs to prevent injection
- [x] Ensure `isBlocked` check on every authenticated route (middleware)
- [x] Confirm bcrypt salt rounds = 12 in auth service
- [x] Confirm OTP expiry = 10 minutes, single-use flag enforced

---

## ✅ PHASE 18 — Testing & Documentation (Done)

- [x] Install `jest` and `supertest`
- [x] Write unit tests for services (auth, listings, bookings, reviews)
- [x] Write integration tests for critical API routes
- [x] Add Swagger/OpenAPI docs (use `swagger-jsdoc` + `swagger-ui-express`)
  - Document all endpoints with request/response schemas
- [x] Add a `README.md` with setup instructions, env vars table, and how to run

---

## ✅ PHASE 19 — Final Polish & Deployment Prep (Done)

- [x] Add `start` and `dev` scripts to `package.json`
  - `"dev": "nodemon server.js"`
  - `"start": "node server.js"`
- [x] Add `.gitignore` entries for `node_modules`, `.env`, `generated/`
- [x] Test all endpoints end-to-end with Postman or Bruno collection
- [x] Confirm Prisma Client generates correctly from Neon DB
- [x] Review all TODO comments and cleanup

---

## 📋 Build Order Summary

| Phase | What |
|-------|------|
| 0 | ✅ Database schema + Prisma config (done) |
| 1 | Project setup, dependencies, folder structure, env vars, migration |
| 2 | Config layer (DB, Redis, Firebase, Passport) |
| 3 | Middleware (auth, role, rate limit, error handler) |
| 4 | Utilities (JWT, OTP, mailer, FCM, currency) |
| 5 | Express app + server entry point |
| 6 | Auth module (register, login, Google OAuth, OTP flow, logout) |
| 7 | Users module (profile, verification, FCM token) |
| 8 | Categories module |
| 9 | Listings module (browse, create, update, delete, rate limit) |
| 10 | Bookings module (full booking flow) |
| 11 | Reviews module |
| 12 | Reports module |
| 13 | Notifications module |
| 14 | Support module |
| 15 | Admin module (full management panel) |
| 16 | Seed data (categories + admin user) |
| 17 | Security hardening (rate limiting, Zod validation) |
| 18 | Testing + Swagger docs |
| 19 | Final polish + deployment prep |
