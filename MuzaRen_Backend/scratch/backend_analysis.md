# RentHubIndia Backend Architecture Analysis

This document provides a comprehensive overview of the RentHubIndia Node.js/Express/Prisma backend architecture based on a full review of the source code.

## 1. High-Level Architecture
- **Framework**: Express.js (v5.2.1) running on Node.js.
- **Database**: PostgreSQL accessed via Prisma ORM (v7.6.0).
- **Real-time Engine**: Socket.IO for chat and instant notifications.
- **Caching & Rate Limiting**: Redis via `ioredis` (v5.10.1).
- **Authentication**: JWT-based authentication with bcrypt for password hashing, plus Google OAuth2 via Passport.js.
- **Push Notifications**: Firebase Admin SDK (`firebase-admin`).
- **File Storage**: Cloudinary integration for image uploads via `multer-storage-cloudinary`.
- **Validation**: Zod for request payload validation.

## 2. Directory Structure (`/src`)
The project follows a modular, feature-based architecture pattern:
- **`config/`**: Setup for external services (db, redis, firebase, cloudinary, passport, swagger, socket).
- **`middleware/`**: Cross-cutting concerns (auth checks, role checks, error handling, rate limiting).
- **`modules/`**: The core business logic, divided by feature domain. Each module typically contains `*.routes.js`, `*.controller.js`, `*.service.js`, and `*.validation.js`.
- **`utils/`**: Shared helper functions (currency mapping, location normalization, mailer, fcm pushes, jwt signing, otp generation).

## 3. Database Schema Overview (`schema.prisma`)
The PostgreSQL schema consists of several interconnected models:

- **User**: Core entity managing identity, auth, and profile. Handles roles (`USER`, `ADMIN`) and verification states (`UNVERIFIED`, `PENDING`, `VERIFIED`).
- **OTP**: Stores one-time passwords for password reset flows.
- **Category**: Defines the taxonomy for listings.
- **Listing & ListingImage**: Represents items available for rent. Listings enforce location, pricing, and availability states (`ACTIVE`, `PAUSED`, `EXPIRED`).
- **Booking**: The core transaction model. Transitions through `PENDING`, `ACCEPTED`, `COMPLETED`, `CANCELLED`.
- **Review**: Tied to a specific booking, representing feedback from either owner or renter. Calculates overall User `rating`.
- **Chat & Message**: Facilitates communication between Owner and Renter concerning a specific Listing. Supports rich features (editing, soft-deleting, read receipts).
- **Notification**: Stores in-app alerts pushed to users.
- **Report & SupportTicket**: Admin tracking and moderation models.

## 4. Module Deep Dives

### Auth Module
- **Flows**: Standard Email/Password registration/login and Google OAuth callback.
- **Reset Flow**: Utilizes a 6-digit OTP sent via email (Nodemailer) that must be verified before setting a new password.

### Users Module
- **Profile**: Allows users to manage their public and private details. Limits updates to safe fields.
- **FCM**: Manages device token registration for Firebase pushes, ensuring a token is only bound to one user at a time.
- **Verification**: Allows uploading a document to trigger an admin review for upgrading to a "VERIFIED" state (required for listings > $1000/day).

### Listings Module
- **Security**: Strict rate limiting for unverified users (max 2/day, 5/month). High-value items require verification.
- **Creation/Update**: Validates location strings and enforces schema validation. Currently auto-approves new listings in dev, but can enforce an admin approval gate.
- **Deletion**: Protected by foreign key constraints—cannot delete if active bookings exist.

### Bookings Module
- **Creation**: Strict overlap validation. Cannot book your own item. Cannot book past dates or dates outside listing availability.
- **Acceptance**: Automatically rejects and cancels any overlapping *pending* requests when one is accepted. Notifies all affected parties.
- **Completion**: Moves an accepted booking to completed, unlocking the ability to leave a review.

### Chat Module (Socket.IO + REST)
- **Hybrid Approach**: Initial loads and mutations via REST. Live delivery, typing indicators, read receipts, editing, and deletion handled via Socket.IO events.
- **Capabilities**: Uploading images, soft deleting ("for me" vs "for everyone" within 24h), editing text (within 15m), and reactions.

### Reviews Module
- **Constraints**: Only allowed on `COMPLETED` bookings. Only one review per booking.
- **Side Effects**: Automatically recalculates and pushes the new average rating to the target User record.

### Notifications Module
- **Flow**: Whenever a key event happens (Booking update, message, system alert), a notification is saved to the DB, emitted instantly via Socket.IO (if online), and dispatched via FCM push (if token exists).
- **Management**: Users can fetch their history and mark items as read.

### Admin Module
- **Scope**: Powerful oversight over users, listings, reports, and support tickets.
- **Capabilities**: Can block users, manually verify users, delete listings, resolve reports, reply to tickets, and manage categories.

## 5. Security & Best Practices Implemented
- **Rate Limiting**: Protects auth endpoints (15m window) and limits listing spam for unverified users.
- **Payload Validation**: Zod aggressively schemas all incoming request bodies.
- **Sanitization**: Cloudinary handles image processing safely.
- **Error Handling**: Centralized `errorHandler.js` prevents stack traces leaking in production.
- **Concurrency**: Redis is utilized for token blacklisting on logout.

## 6. Key Interactions for Mobile Client Integration
- **JWT Handling**: Client must pass `Bearer <token>` in the `Authorization` header.
- **Socket Connection**: Must connect to `ws://server` and pass the JWT token in the handshake auth payload (`socket.io({ auth: { token: 'Bearer <jwt>' } })`).
- **File Uploads**: Expect `multipart/form-data` with keys like `avatar`, `image`, or `document` depending on the route.

This backend is robust, feature-complete for a peer-to-peer rental marketplace, and strictly enforces state transitions and data integrity.
