# RentHubIndia API Documentation

Base URL: `http://localhost:5000` (or your `PORT` from `.env`)

---

## 🔐 Auth Module (`/api/auth`)

### 1. Register a new user
- **Endpoint**: `POST /api/auth/register`
- **Body** (JSON):
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepassword123"
  }
  ```
- **Response** (201 Created):
  Returns `user` object and a `token` (JWT).

### 2. Login
- **Endpoint**: `POST /api/auth/login`
- **Body** (JSON):
  ```json
  {
    "email": "john@example.com",
    "password": "securepassword123"
  }
  ```
- **Response** (200 OK):
  Returns `user` object and a `token` (JWT). Use this token for protected routes by passing `Authorization: Bearer <token>` in the header.

### 3. Forgot Password
- **Endpoint**: `POST /api/auth/forgot-password`
- **Body** (JSON):
  ```json
  {
    "email": "john@example.com"
  }
  ```
- **Response** (200 OK):
  Sends an OTP to the email address.

### 4. Verify OTP
- **Endpoint**: `POST /api/auth/verify-otp`
- **Body** (JSON):
  ```json
  {
    "email": "john@example.com",
    "code": "123456"
  }
  ```
- **Response** (200 OK):
  Validates if the OTP is correct.

### 5. Reset Password
- **Endpoint**: `POST /api/auth/reset-password`
- **Body** (JSON):
  ```json
  {
    "email": "john@example.com",
    "code": "123456",
    "newPassword": "newsecurepassword123"
  }
  ```
- **Response** (200 OK):
  Updates the password.

### 6. Logout
- **Endpoint**: `POST /api/auth/logout`
- **Headers**: `Authorization: Bearer <token>`
- **Response** (200 OK):
  Blacklists the current token.

---

## 👤 Users Module (`/api/users`)

*Note: All endpoints below strictly require the `Authorization: Bearer <token>` header.*

### 1. Get Logged In Profile
- **Endpoint**: `GET /api/users/profile`
- **Headers**: `Authorization: Bearer <token>`
- **Response** (200 OK):
  Returns the currently authenticated user's private profile.

### 2. Update Profile
- **Endpoint**: `PUT /api/users/profile`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "name": "John Updated",
    "phone": "1234567890",
    "city": "New York"
  }
  ```

### 3. Upload Avatar Image
- **Endpoint**: `POST /api/users/avatar`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (FormData):
  - Key: `avatar` (type: File)
  - Value: `<Select an image file>`

### 4. Update FCM Token (Push Notifications)
- **Endpoint**: `POST /api/users/fcm-token`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "fcmToken": "dh39...your_token_string"
  }
  ```

### 5. Submit ID Verification Document
- **Endpoint**: `POST /api/users/me/verify`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (FormData):
  - Key: `document` (type: File)
  - Value: `<Select an ID image file>`

### 6. Get Public Profile (By ID)
- **Endpoint**: `GET /api/users/:id`
- **Headers**: `Authorization: Bearer <token>`
- **URL Parameter**: Replace `:id` with target User ID.
- **Response** (200 OK): Returns stripped public fields (no email or password).

---

### Admin Only Endpoints

### 7. Get All Users
- **Endpoint**: `GET /api/users`
- **Headers**: `Authorization: Bearer <admin_token>`
- **Query Params (Optional)**: `?role=USER&verificationStatus=PENDING`
- **Response**: List of all users.

### 8. Block / Unblock a User
- **Endpoint**: `PATCH /api/users/:id/block`
- **Headers**: `Authorization: Bearer <admin_token>`
- **URL Parameter**: Replace `:id` with User ID to block.
- **Response**: Toggles block status.

---

## 📦 Categories Module (`/api/categories`)

### 1. Get All Categories
- **Endpoint**: `GET /api/categories`
- **Response** (200 OK):
  Returns a list of all listing categories available in the marketplace (public).

---

## 🏷️ Listings Module (`/api/listings`)

### 1. Browse Listings
- **Endpoint**: `GET /api/listings`
- **Query Params**: `?category=electronics&priceMin=10&priceMax=500&page=1`
- **Response** (200 OK): Paginated list of active and approved listings.

### 2. Get Listing Details
- **Endpoint**: `GET /api/listings/:id`
- **Response** (200 OK): Full public details of a single listing including its owner and images.

### 3. Create a Listing
- **Endpoint**: `POST /api/listings`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "categoryId": "uuid string",
    "title": "Camera for rent",
    "description": "A very nice 4k camera",
    "pricePerDay": 25.50,
    "location": "Downtown"
  }
  ```
- **Note**: Triggers rate limiting for unverified users. Requires VERIFIED account if price > $1000/day.

### 4. Upload Listing Images
- **Endpoint**: `POST /api/listings/:id/images`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (FormData):
  - Key: `images` (type: File)
  - Value: `<Select up to 5 image files>`
- **Note**: Only the owner of the listing can upload images to it.

### 5. Get My Listings
- **Endpoint**: `GET /api/listings/my/listings`
- **Headers**: `Authorization: Bearer <token>`
- **Response** (200 OK): Returns all listings owned by the logged-in user.

### 6. Update Listing Status (Pause / Activate)
- **Endpoint**: `PATCH /api/listings/:id/status`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "status": "PAUSED"
  }
  ```

---

## 📅 Bookings Module (`/api/bookings`)
*All booking paths require the `Authorization: Bearer <token>` header.*

### 1. Create a Booking
- **Endpoint**: `POST /api/bookings`
- **Body** (JSON):
  ```json
  {
    "listingId": "uuid-string-here",
    "startDate": "2024-08-01T10:00:00Z",
    "endDate": "2024-08-05T10:00:00Z"
  }
  ```
- **Response** (201 Created): Generates booking logic (checking constraints natively) and signals push notifications to the owner.

### 2. View My Outgoing Bookings (Renter)
- **Endpoint**: `GET /api/bookings/my`
- **Response** (200 OK): Returns all bookings initiated by the logged in user.

### 3. View My Incoming Bookings (Owner)
- **Endpoint**: `GET /api/bookings/incoming`
- **Response** (200 OK): Returns all booking requests targeting the user's hosted items.

### 4. Accept a Booking
- **Endpoint**: `PATCH /api/bookings/:id/accept`
- **Response** (200 OK): Jumps the sequence from `PENDING` directly to `ACCEPTED` and fires confirmation emails/notifications to the requester.

### 5. Cancel a Booking
- **Endpoint**: `PATCH /api/bookings/:id/cancel`
- **Response** (200 OK): Can be fired from *either* the owner or the renter (triggers notifications appropriately mapping ownership state internally).

### 6. Complete a Booking
- **Endpoint**: `PATCH /api/bookings/:id/complete`
- **Response** (200 OK): Concludes the loop mapping the item to `COMPLETED` so it can be safely reviewed natively.

---

## ⭐ Reviews Module (`/api/reviews`)

### 1. Submit a Review
- **Endpoint**: `POST /api/reviews`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "bookingId": "uuid-string-of-a-completed-booking",
    "rating": 5,
    "comment": "Incredible experience, owner was super communicative!"
  }
  ```
- **Response** (201 Created): Generates the review, asserting the limits cleanly, and processes aggregate recalculations immediately.

### 2. Get Reviews for a Listing
- **Endpoint**: `GET /api/reviews/listing/:id`
- **Query Params**: `?page=1&limit=10`
- **Response** (200 OK): Public. Returns chronological array of reviews left on a particular listing.

### 3. Get Reviews targeting a User
- **Endpoint**: `GET /api/reviews/user/:id`
- **Query Params**: `?page=1&limit=10`
- **Response** (200 OK): Public. Displays average rating bounds targeting this user's profile UUID across all their rentals/listings.

---

## 🚩 Reports Module (`/api/reports`)

### 1. Submit a Report
- **Endpoint**: `POST /api/reports`
- **Headers**: `Authorization: Bearer <token>`
- **Body** (JSON):
  ```json
  {
    "targetType": "LISTING",
    "targetId": "uuid-string-here",
    "category": "FRAUD",
    "description": "This user is asking for payments outside of the platform."
  }
  ```
- **Note**: `targetType` must strictly be `LISTING`, `USER`, or `MESSAGE`. The `category` must strictly be `FRAUD`, `SPAM`, `ABUSE`, or `FAKE_LISTING`.
- **Response** (201 Created): Logs the report under an `OPEN` status exclusively pending Admin resolution algorithms inherently.

---

## 🔔 Notifications Module (`/api/notifications`)
*All notification endpoints strictly require the `Authorization: Bearer <token>` header.*

### 1. Retrieve Account Notifications
- **Endpoint**: `GET /api/notifications`
- **Response** (200 OK): Exposes an array of all native platform alerts structurally sorted by `createdAt` (descending).

### 2. Mark Multiple Notifications as Read
- **Endpoint**: `PATCH /api/notifications/read-all`
- **Response** (200 OK): Dynamically intercepts all boolean `isRead == false` UUID states targeting your user ID globally and flashes them to `true`.

### 3. Mark Single Notification as Read
- **Endpoint**: `PATCH /api/notifications/:id/read`
- **URL Parameter**: Provide exact notification UUID string targeting one row to clear from read states safely.

---

## 🎫 Support Module (`/api/support/tickets`)
*All Support endpoints strictly require the `Authorization: Bearer <token>` header.*

### 1. Create a Support Ticket
- **Endpoint**: `POST /api/support/tickets`
- **Body** (JSON):
  ```json
  {
    "subject": "Missing Payment",
    "message": "I completed a rental but the payment hasn't hit my wallet."
  }
  ```
- **Response** (201 Created): Generates an `OPEN` ticket that Admins will intercept later.

### 2. View My Tickets
- **Endpoint**: `GET /api/support/tickets`
- **Response** (200 OK): Outputs all historical tickets attached to this user account securely.

### 3. View Ticket Details
- **Endpoint**: `GET /api/support/tickets/:id`
- **Response** (200 OK): Exposes specific ticket message details. Rejects UUID queries spanning outside personal ownership.

---

## 🛡️ Admin Module (`/api/admin`)
*CRITICAL: Every endpoint here requires an Admin-level JWT Bearer token.*

### 1. Unified Dashboard
- **Endpoint**: `GET /api/admin/dashboard`
- **Response** (200 OK): Exposes counts array displaying Users, Listings, Bookings, and Open Reports.

### 2. Category Control (CRUD)
- **Endpoints**:
  - `GET /api/admin/categories`
  - `POST /api/admin/categories`
  - `PUT /api/admin/categories/:id`
  - `DELETE /api/admin/categories/:id`

### 3. Moderation (Users/Listings/Reviews/Reports)
- **Endpoints**:
  - `PATCH /api/admin/users/:id/verify` *(Elevates User)*
  - `PATCH /api/admin/users/:id/block` *(Blocks User)*
  - `PATCH /api/admin/listings/:id/approve` *(Activates globally pending Listings)*
  - `DELETE /api/admin/reviews/:id` *(Wipes fake reviews and natively recalibrates User rating sums)*
  - `PATCH /api/admin/reports/:id/action` *(Resolves reports and natively Push Notifies original Reporter)*
  - `PATCH /api/admin/support/tickets/:id/reply` *(Replies to Ticket and triggers Push Notification)*
