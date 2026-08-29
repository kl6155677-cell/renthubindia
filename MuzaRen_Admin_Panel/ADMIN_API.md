# RentHubIndia Admin API Reference

> **Purpose:** This file is the single source of truth for every API endpoint
> available to the admin panel. Use it to understand what's available, what
> payload shape is expected, and what the backend returns.
>
> All requests must include `Authorization: Bearer <admin_token>` unless marked **Public**.
>
> Base URL: `http://localhost:5000/api` (set via `VITE_API_BASE_URL` in `.env`)

---

## Table of Contents

1. [Auth](#1-auth)
2. [Dashboard](#2-dashboard)
3. [Users (Admin)](#3-users-admin)
4. [Listings (Admin)](#4-listings-admin)
5. [Bookings (Admin)](#5-bookings-admin)
6. [Reports (Admin)](#6-reports-admin)
7. [Support Tickets (Admin)](#7-support-tickets-admin)
8. [Categories (Admin CRUD)](#8-categories-admin-crud)
9. [Reviews (Admin)](#9-reviews-admin)
10. [Public Endpoints Usable with Admin Token](#10-public-endpoints-usable-with-admin-token)
11. [Phase 2 — Messaging Moderation](#11-phase-2--messaging-moderation)
12. [Phase 2 — Broadcast & Campaigns](#12-phase-2--broadcast--campaigns)
13. [Phase 2 — Analytics](#13-phase-2--analytics)

---

## 1. Auth

### Login
```
POST /api/auth/login
```
**Body:**
```json
{
  "email": "admin@renthubindia.com",
  "password": "securepassword"
}
```
**Response `200`:**
```json
{
  "data": {
    "accessToken": "<jwt>",
    "user": { "id": "...", "role": "ADMIN" }
  }
}
```
**Used by:** `loginAdmin()` in `adminApi.ts`

---

### Logout
```
POST /api/auth/logout
Authorization: Bearer <token>
```
Blacklists the current JWT. Call on sign-out.

---

## 2. Dashboard

### Get unified KPIs
```
GET /api/admin/dashboard
Authorization: Bearer <admin_token>
```
**Response `200`:**
```json
{
  "data": {
    "totalUsers": 1240,
    "totalListings": 380,
    "totalBookings": 742,
    "openReports": 12,
    "pendingVerifications": 7,
    "openSupportTickets": 4,
    "newUsers7d": 28,
    "newListings7d": 15,
    "bookingCompletionRate7d": 83.4,
    "bookingCancellationRate7d": 11.2
  }
}
```
**Used by:** `fetchDashboardStats()` in `adminApi.ts`

---

## 3. Users (Admin)

### Get all users
```
GET /api/users
Authorization: Bearer <admin_token>
Query params (optional): ?role=USER&verificationStatus=PENDING
```
**Response `200`:** Array of user objects.

**Used by:** `fetchUsers(params?)` in `adminApi.ts`

---

### Get a single user's public profile
```
GET /api/users/:id
Authorization: Bearer <admin_token>
```
Returns stripped public fields (no password).

**Used by:** `fetchUserById(userId)` in `adminApi.ts`

---

### Verify a user's identity
```
PATCH /api/admin/users/:id/verify
Authorization: Bearer <admin_token>
```
Elevates `verificationStatus` to `VERIFIED`.

**Used by:** `verifyUser(userId)` in `adminApi.ts`

---

### Block / Unblock a user
```
PATCH /api/users/:id/block
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "isBlocked": true }
```
Toggles block status. Blocked users cannot log in or create listings.

**Used by:** `toggleUserBlock(userId, isBlocked)` in `adminApi.ts`

---

## 4. Listings (Admin)

### Get all listings
```
GET /api/admin/listings
Authorization: Bearer <admin_token>
```
Returns full listing details including owner and images.

**Used by:** `fetchListings()` in `adminApi.ts`

---

### Approve / Unapprove a listing
```
PATCH /api/admin/listings/:id/approve
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "isApproved": true }
```
Activates a globally pending listing so it appears in public search.

**Used by:** `approveListing(listingId, isApproved)` in `adminApi.ts`

---

## 5. Bookings (Admin)

### Get all bookings
```
GET /api/admin/bookings
Authorization: Bearer <admin_token>
```
Returns all bookings with renter, owner, and listing details.

> **Phase 1 note:** Read-only. Admin override actions (force-cancel, dispute resolution)
> are gated behind backend endpoints not yet implemented.

**Used by:** `fetchBookings()` in `adminApi.ts`

---

## 6. Reports (Admin)

### Get all reports
```
GET /api/admin/reports
Authorization: Bearer <admin_token>
```
Returns all reports with reporter info and target entity.

**Used by:** `fetchReports()` in `adminApi.ts`

---

### Act on a report
```
PATCH /api/admin/reports/:id/action
Authorization: Bearer <admin_token>
```
**Body:**
```json
{
  "status": "RESOLVED",
  "adminNote": "Content removed, user warned."
}
```
| `status` value | Meaning |
|---|---|
| `REVIEWED` | Admin has reviewed but action pending |
| `RESOLVED` | Case closed, action taken |

Triggers a push notification to the original reporter.

**Used by:** `updateReportStatus(reportId, status, adminNote?)` in `adminApi.ts`

---

## 7. Support Tickets (Admin)

### Get all support tickets
```
GET /api/admin/support/tickets
Authorization: Bearer <admin_token>
```
Returns all tickets sorted oldest-open-first for SLA compliance.

**Used by:** `fetchSupportTickets()` in `adminApi.ts`

---

### Reply to a ticket
```
PATCH /api/admin/support/tickets/:id/reply
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "adminReply": "We've resolved your issue, please check again." }
```
Triggers a push notification to the ticket owner.

**Used by:** `replyToSupportTicket(ticketId, adminReply)` in `adminApi.ts`

---

## 8. Categories (Admin CRUD)

### Get all categories
```
GET /api/admin/categories
Authorization: Bearer <admin_token>
```
**Used by:** `fetchCategories()` in `adminApi.ts`

---

### Create a category
```
POST /api/admin/categories
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "name": "Electronics", "description": "Gadgets and devices" }
```
**Used by:** `createCategory(payload)` in `adminApi.ts`

---

### Update a category
```
PUT /api/admin/categories/:id
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "name": "Electronics & Gadgets", "description": "Updated description" }
```
**Used by:** `updateCategory(categoryId, payload)` in `adminApi.ts`

---

### Delete a category
```
DELETE /api/admin/categories/:id
Authorization: Bearer <admin_token>
```
> ⚠️ Destructive. Confirm dependency warning before calling (existing listings reference this category).

**Used by:** `deleteCategory(categoryId)` in `adminApi.ts`

---

## 9. Reviews (Admin)

### Get all reviews
```
GET /api/admin/reviews
Authorization: Bearer <admin_token>
```
**Used by:** `fetchReviews()` in `adminApi.ts`

---

### Delete a review (with audit reason)
```
DELETE /api/admin/reviews/:id
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "reason": "Abusive content violating platform policies" }
```
Automatically recalibrates the listing's and user's aggregate rating.

**Used by:** `deleteReview(reviewId, reason)` in `adminApi.ts`

---

## 10. Public Endpoints Usable with Admin Token

These are regular user-facing endpoints, but the admin JWT is accepted.

### Browse all listings (public)
```
GET /api/listings?category=electronics&priceMin=10&priceMax=500&page=1
```

### Get listing reviews
```
GET /api/reviews/listing/:id?page=1&limit=20
```
**Used by:** `fetchListingReviews(listingId, page?, limit?)` in `adminApi.ts`

---

### Get user reviews
```
GET /api/reviews/user/:id?page=1&limit=20
```
**Used by:** `fetchUserReviews(userId, page?, limit?)` in `adminApi.ts`

---

### Get public categories
```
GET /api/categories
```
**Used by:** `fetchPublicCategories()` in `adminApi.ts`

---

## 11. Phase 2 — Messaging Moderation

> 🔧 **Backend not yet implemented.** These stubs are ready in `adminApi.ts` and
> will activate once the backend messaging moderation module is deployed.

### Get flagged messages
```
GET /api/admin/messages/flagged
Authorization: Bearer <admin_token>
```
Returns messages flagged for policy violations.

**Used by:** `fetchFlaggedMessages()` in `adminApi.ts`

---

### Remove (takedown) a message
```
DELETE /api/admin/messages/:id
Authorization: Bearer <admin_token>
```
**Body:**
```json
{ "reason": "Hate speech — community guidelines violation" }
```
**Used by:** `deleteMessage(messageId, reason)` in `adminApi.ts`

---

## 12. Phase 2 — Broadcast & Campaigns

> 🔧 **Backend not yet implemented.** Stubs ready in `adminApi.ts`.

### Get all broadcasts
```
GET /api/admin/broadcasts
Authorization: Bearer <admin_token>
```
**Used by:** `fetchBroadcasts()` in `adminApi.ts`

---

### Send a push broadcast
```
POST /api/admin/broadcasts
Authorization: Bearer <admin_token>
```
**Body:**
```json
{
  "title": "🎉 New Feature Launch",
  "body": "Check out the new booking review system!",
  "targetAudience": "ALL",
  "scheduledAt": "2025-06-01T09:00:00Z"
}
```
| `targetAudience` | Scope |
|---|---|
| `ALL` | Every registered user |
| `VERIFIED` | Identity-verified users only |
| `UNVERIFIED` | Unverified users (onboarding nudge) |
| `OWNERS` | Users with at least one listing |
| `RENTERS` | Users who have made a booking |

`scheduledAt` is optional. Omit to send immediately.

**Used by:** `sendBroadcast(payload)` in `adminApi.ts`

---

## 13. Phase 2 — Analytics

> 🔧 **Backend not yet implemented.** Stubs ready in `adminApi.ts`.

### Get analytics data
```
GET /api/admin/analytics?range=30d
Authorization: Bearer <admin_token>
```
| `range` | Period |
|---|---|
| `7d` | Last 7 days |
| `30d` | Last 30 days (default) |
| `90d` | Last 90 days |

**Response `200`:**
```json
{
  "data": {
    "userGrowth": [{ "date": "2025-05-01", "count": 14 }],
    "listingGrowth": [{ "date": "2025-05-01", "count": 6 }],
    "bookingFunnel": {
      "created": 320,
      "accepted": 260,
      "completed": 210,
      "cancelled": 50
    },
    "topCategories": [
      { "categoryName": "Electronics", "listingCount": 142 }
    ],
    "geoDemand": [
      { "city": "Riyadh", "country": "SA", "listingCount": 87 }
    ]
  }
}
```
**Used by:** `fetchAnalytics(range?)` in `adminApi.ts`

---

## Backend Gap Backlog (From Blueprint)

These features are documented but require backend implementation before the admin UI can call them:

| Feature | What's needed |
|---|---|
| Verify-reject with reason | `PATCH /api/admin/users/:id/verify` needs `{ approved: false, reason: "..." }` support |
| Admin booking override | `POST /api/admin/bookings/:id/force-cancel` or `/resolve-dispute` |
| Persistent audit log | `GET /api/admin/audit-logs` — every admin action logged server-side |
| Ticket workflow states | Standardise `OPEN → IN_PROGRESS → RESOLVED → CLOSED` in `/api/admin/support/tickets/:id/status` |
| Report for MESSAGE type | Linking `targetType: MESSAGE` to actual chat message entities |
| Messaging moderation | `/api/admin/messages/flagged` + `/api/admin/messages/:id` DELETE |
| Broadcast engine | `/api/admin/broadcasts` GET + POST |
| Analytics pipeline | `/api/admin/analytics?range=30d` |
