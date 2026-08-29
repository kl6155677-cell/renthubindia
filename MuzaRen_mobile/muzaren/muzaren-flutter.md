# RentHubIndia — Flutter Mobile App

## Project Overview
RentHubIndia is a **rental-only marketplace** app for iOS and Android. Users can list items for rent, discover nearby listings, book items, chat with owners, and manage their profile. The UI must be **modern, clean, and premium** — not an OLX clone. The design should feel more trustworthy and user-friendly than existing classifieds apps.

---

## Tech Stack

| Purpose | Package |
|---------|---------|
| Framework | Flutter (iOS + Android) |
| State Management | `flutter_bloc` |
| Navigation | `go_router` |
| HTTP Client | `dio` |
| Auth Storage | `flutter_secure_storage` |
| Image Upload | `image_picker` + Cloudinary (via REST API) |
| Maps & Location | `google_maps_flutter` + `geolocator` |
| Real-time Chat | `cloud_firestore` (Firebase) — direct read & write |
| Push Notifications | `firebase_messaging` (FCM) |
| Local Storage | `hive` + `shared_preferences` |
| UI Extras | `cached_network_image`, `shimmer`, `lottie` |

> ⚠️ No Stripe / payment package — removed from MVP. No `firebase_auth` — auth is handled by backend JWT. No direct Firebase Storage — images go through backend to **Cloudinary**.

---

## Folder Structure

```
lib/
├── main.dart
├── core/
│   ├── router/
│   │   └── app_router.dart          # go_router setup, all named routes
│   ├── theme/
│   │   ├── app_colors.dart          # Brand color palette
│   │   ├── app_typography.dart      # Font styles
│   │   └── app_theme.dart           # ThemeData
│   ├── constants/
│   │   ├── api_constants.dart       # Base URL, endpoints
│   │   └── app_constants.dart       # Enums, limits, categories
│   └── utils/
│       ├── date_utils.dart
│       ├── currency_utils.dart      # Format price by country currency
│       ├── validators.dart
│       └── location_utils.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── listing_model.dart
│   │   ├── booking_model.dart
│   │   ├── review_model.dart
│   │   ├── category_model.dart
│   │   ├── notification_model.dart
│   │   ├── report_model.dart
│   │   └── support_ticket_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── listing_repository.dart
│   │   ├── booking_repository.dart
│   │   ├── chat_repository.dart
│   │   ├── review_repository.dart
│   │   ├── notification_repository.dart
│   │   └── support_repository.dart
│   └── services/
│       ├── api_service.dart         # Dio HTTP client with JWT interceptor
│       ├── firebase_chat_service.dart  # Direct Firestore read & write for real-time chat
│       ├── fcm_service.dart         # Push notification handler
│       ├── location_service.dart    # Geolocator + country detection
│       └── cloudinary_service.dart  # Cloudinary image URL builder (no direct upload)
│
├── blocs/
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   ├── listing/
│   │   ├── listing_bloc.dart
│   │   ├── listing_event.dart
│   │   └── listing_state.dart
│   ├── booking/
│   │   ├── booking_bloc.dart
│   │   ├── booking_event.dart
│   │   └── booking_state.dart
│   ├── chat/
│   │   ├── chat_bloc.dart
│   │   ├── chat_event.dart
│   │   └── chat_state.dart
│   └── notification/
│       ├── notification_bloc.dart
│       ├── notification_event.dart
│       └── notification_state.dart
│
└── features/
    ├── auth/
    ├── home/
    ├── search/
    ├── listing/
    ├── booking/
    ├── chat/
    ├── profile/
    └── notifications/
```

---

## All 11 Screens

### Zone 1 — Onboarding

---

#### Screen 1: Splash Screen
**File:** `features/auth/splash_screen.dart`

**Purpose:** Entry point of the app.

**Logic:**
- Show RentHubIndia logo with animated entrance
- Check `flutter_secure_storage` for a saved JWT token
- If token exists → validate with backend → navigate to **Home**
- If no token → navigate to **Login**
- Duration: ~2 seconds

**UI:**
- Full screen with brand gradient background
- Centered logo + app name "RentHubIndia"
- Subtle loading animation (Lottie or circular indicator)

---

#### Screen 2: Sign Up / Login Screen
**File:** `features/auth/login_screen.dart`, `features/auth/register_screen.dart`

**Purpose:** Authenticate user.

**Login Fields:**
- Email
- Password
- "Forgot Password?" link

**Register Fields:**
- Full Name
- Email
- Phone (optional)
- Password
- Confirm Password

**Actions:**
- Email/password login → POST `/api/auth/login` → save JWT
- Email/password register → POST `/api/auth/register` → save JWT
- Forgot password → navigate to OTP screen

> ⚠️ Google OAuth button exists in the UI but confirm with backend if `POST /api/auth/google` is implemented before wiring it up.

**OTP Flow:**
- User enters email → POST `/api/auth/forgot-password`
- OTP screen: 6-digit input → POST `/api/auth/verify-otp` (body: `{ email, code }`)
- Reset password screen → POST `/api/auth/reset-password` (body: `{ email, code, newPassword }`)

**UI Notes:**
- Clean card-based layout, not cluttered
- Smooth tab switch between Login / Register
- Google button with brand styling
- Inline field validation

---

### Zone 2 — Discovery

---

#### Screen 3: Home Screen
**File:** `features/home/home_screen.dart`

**Purpose:** Main discovery screen — first thing users see after login.

**Sections:**
1. **Top Bar:** Location selector (auto-detected city) + notification bell icon
2. **Search Bar:** Tappable, navigates to Search Results screen
3. **Categories Row:** Horizontal scrollable icons (Electronics, Vehicles, Furniture, Tools, Fashion, Sports, etc.)
4. **Featured Listings:** Horizontal scroll of highlighted listing cards
5. **Nearby Listings:** Grid of listing cards filtered by user's location

**API Calls:**
- GET `/api/categories`
- GET `/api/listings?country={userCountry}` — featured listings scoped to user's country
- GET `/api/listings?country={userCountry}&city={userCity}&lat={lat}&lng={lng}` — nearby listings

> ⚠️ Both listing calls must always include the `country` param from `LocationBloc`. Never call GET `/api/listings` without a country filter — the home screen must only show listings from the user's detected country by default.

**UI Notes:**
- Location chip in top bar shows detected city (e.g. "Singapore, SG") — tappable to change
- Listing cards show: image, title, price/day, city, distance
- Shimmer loading placeholders while location is being detected
- Pull-to-refresh re-fetches with current location params
- If location not yet detected → show shimmer until `LocationBloc` emits `LocationDetected`

---

#### Screen 4: Categories Screen
**File:** `features/home/categories_screen.dart`

**Purpose:** Full grid of all rental categories.

**Behavior:**
- Tapping a category → navigates to Search Results filtered by that category

**UI Notes:**
- 3-column grid layout
- Each cell: icon + category name
- Visually distinct icons per category

---

#### Screen 5: Search Results Screen
**File:** `features/search/results_screen.dart`

**Purpose:** Keyword search + filtered browse.

**Filter Options:**
- Price range (min/max per day)
- Location (city within current country — or expand to other countries)
- Date range (availability)
- Category
- Country *(defaults to user's detected country — user can change)*

**Views:**
- **List View:** Vertical list of listing cards
- **Map View:** Google Maps with listing pins

**Behavior:**
- Always pre-filtered by user's country from `LocationBloc` on screen open
- Country filter chip shows current country (e.g. "🇸🇬 Singapore") — tappable to change
- Infinite scroll / pagination
- Debounced keyword search (500ms)
- Active filters shown as removable chips
- Removing the country chip → searches all countries globally

**API Call:**
- GET `/api/listings?country={userCountry}&search=...&categoryId=...&minPrice=...&maxPrice=...&lat=...&lng=...&startDate=...&endDate=...`
- If user removes country filter: GET `/api/listings?search=...` (no country param)

---

### Zone 3 — Listings

---

#### Screen 6: Product Details Screen
**File:** `features/listing/detail_screen.dart`

**Purpose:** Full details of a rental listing.

**Sections:**
1. **Photo Gallery:** Swipeable full-width image carousel (up to **5** photos — max supported by backend)
2. **Title, Price/Day, Location**
3. **Availability Calendar:** Visual calendar showing available dates
4. **Description**
5. **Owner Card:** Avatar, name, verified badge (if verified), rating, join date → tappable to owner profile
6. **Reviews:** Star rating summary + review list (`GET /api/reviews/listing/:id?page=1&limit=10`)
7. **Report Button:** Flag this listing → `POST /api/reports` with body `{ targetType: "LISTING", targetId: listingId, category, description }`
8. **CTA Buttons:**
   - **Book Now** → navigates to Booking screen
   - **Chat** → opens chat with owner

**API Calls:**
- GET `/api/listings/:id`
- GET `/api/reviews/listing/:id?page=1&limit=10`

**UI Notes:**
- Premium card layout
- Smooth image transitions
- Clear available/unavailable date indicators on calendar

---

#### Screen 7: Post Item for Rent
**File:** `features/listing/post_listing_screen.dart`

**Purpose:** Multi-step form to create a new listing.

**Steps:**
1. **Category** — Select from grid
2. **Details** — Title, description
3. **Pricing** — Price per day
4. **Location** — Map picker + manual city input
5. **Availability** — Start & end date picker
6. **Review & Submit** → POST `/api/listings` (creates listing first)
7. **Photos** — After listing is created, upload up to **5** images via `POST /api/listings/:id/images` (multipart, key: `images`, multiple files)

> ⚠️ Image upload is a **separate API call** after listing creation — not part of the initial POST body. The listing is created first (returns `id`), then images are uploaded using that `id`. Handle this as a 2-step submit in the UI: show a loading/uploading state after the form submits.

**Validation:**
- If user is UNVERIFIED and price > ₹1000 equivalent → show "Verification Required" message
- If daily listing limit reached → show limit alert with verification CTA
- All fields validated before each step advances

**API Calls:**
- POST `/api/listings` — creates the listing (no images in this request)
- POST `/api/listings/:id/images` — uploads up to 5 images as multipart after listing is created
- Images are picked via `image_picker`, sent as multipart form-data to the backend, which uploads them to **Cloudinary** and stores the returned CDN URLs. The Flutter app never talks to Cloudinary directly.

**UI Notes:**
- Step indicator at top (e.g. Step 2 of 6)
- Progress is saved so user doesn't lose data on back navigation
- Clean step-by-step wizard, not one long form

---

### Zone 4 — Transactions

---

#### Screen 8: Booking Screen
**File:** `features/booking/booking_screen.dart`

**Purpose:** Request to rent an item.

**Sections:**
1. **Date Picker** — Linked to listing's availability calendar
2. **Price Breakdown:**
   - Daily rate × number of days
   - Service fee (placeholder for future)
   - Total
3. **Booking Notes** — Optional message to owner
4. **Submit Booking** button

**No payment in MVP.** Booking is a request that the owner accepts/declines.

**Booking Status Flow:**
```
PENDING → ACCEPTED → COMPLETED
        ↘ CANCELLED  ↗ CANCELLED
```
> ⚠️ There is no CONFIRMED step in the actual API. The flow goes directly `PENDING → ACCEPTED → COMPLETED`. Do not build a "confirm" screen for the renter.

**API Call:**
- POST `/api/bookings`
- Body: `{ "listingId": "uuid", "startDate": "ISO date", "endDate": "ISO date" }`
- On success: backend auto-sends push notification to the owner

**UI Notes:**
- Unavailable dates blocked on calendar
- Price auto-calculates as dates change
- Clear confirmation message after submission

---

#### Screen 9: Notifications Screen
**File:** `features/notifications/notifications_screen.dart`

**Purpose:** In-app notification center.

**Notification Types:**
- Booking request received (owner)
- Booking accepted/rejected (renter)
- Booking confirmed / completed / cancelled
- New chat message
- Verification status update
- System announcements

**Behavior:**
- Unread notifications highlighted
- Tap notification → navigate to relevant screen
- Mark all as read button
- FCM push notifications for all above events

**API Calls:**
- GET `/api/notifications`
- PATCH `/api/notifications/:id/read`
- PATCH `/api/notifications/read-all`

---

### Zone 5 — User Hub

---

#### Screen 10: Chat / Messages
**File:** `features/chat/messages_list_screen.dart`, `features/chat/chat_thread_screen.dart`

**Purpose:** Real-time 1-on-1 messaging between renter and owner.

**Architecture:** Flutter talks **directly to Firebase Firestore** for all chat reads and writes. The backend is only involved for push notifications (FCM) via Cloud Functions or Firebase triggers — not for message delivery.

```
Flutter (send message)  →  Firestore write directly
Firestore               →  real-time stream
Flutter (receives)      ←  snapshots() listener
```

**Messages List:**
- All conversations for current user
- Each row: avatar, name, listing context ("Re: Sony Camera"), last message preview, timestamp, unread count badge
- Loaded via Firestore `snapshots()` stream on `chats/` collection filtered by `renterId` or `ownerId`

**Chat Thread:**
- Real-time messages via direct Firestore `snapshots()` stream
- Text messages + image sharing
- Listing context card at top (image + title + "View Listing" link)
- Can be opened from listing detail screen (before booking) or from booking screen

**Firestore Structure:**
```
chats/
  {chatId}/
    metadata: { listingId, renterId, ownerId, lastMessage, updatedAt }
    messages/
      {messageId}: { senderId, text, imageUrl, createdAt, read }
```

**firebase_chat_service.dart responsibilities:**
```dart
class FirebaseChatService {
  // Create or get existing chat room
  Future<String> getOrCreateChat(String listingId, String renterId, String ownerId);

  // Send text message — direct Firestore write
  Future<void> sendMessage(String chatId, String senderId, String text);

  // Send image — upload to Cloudinary via backend, then write URL to Firestore
  Future<void> sendImage(String chatId, String senderId, File image);

  // Mark messages as read — direct Firestore write
  Future<void> markAsRead(String chatId, String userId);

  // Real-time message stream — direct Firestore snapshots
  Stream<List<Message>> messagesStream(String chatId);

  // Real-time conversations list stream
  Stream<List<Conversation>> conversationsStream(String userId);
}
```

**Behavior:**
- Chat available before AND after booking
- Real-time updates via Firestore `snapshots()` — no polling, no backend relay
- FCM push notification triggered by Firestore Cloud Function when new message is written
- Image messages: image uploaded to Cloudinary via backend, URL stored in Firestore message doc

---

#### Screen 11: User Profile + My Listings
**File:** `features/profile/profile_screen.dart`, `features/profile/my_listings_screen.dart`

**Profile Screen (Public view):**
- Avatar + name
- Verified badge (if verified)
- Star rating + number of reviews
- Join date
- Active listings grid
- Reviews section

**My Listings (Owner dashboard):**
- Tabs: **Active | Paused | Expired**
- Each listing card: thumbnail, title, status, incoming bookings count
- Actions per listing: Edit | Pause/Activate | Delete
- Incoming booking requests per listing with Accept / Decline buttons

**Settings (within profile):**
- Edit profile (name, phone, avatar)
- Change location / currency
- Submit verification documents
- Notification preferences
- Support & FAQ link
- Logout

**API Calls:**
- GET `/api/users/profile` — current user's private profile
- PUT `/api/users/profile` — update name, phone, city
- POST `/api/users/avatar` — upload avatar (multipart, key: `avatar`)
- GET `/api/users/:id` — public profile (requires auth)
- GET `/api/listings/my/listings`
- GET `/api/bookings/incoming`

---

## UI/UX Design Guidelines

### Design Principles
- **Modern & Premium** — not a classifieds clone
- **Clean** — generous whitespace, no clutter
- **Trustworthy** — verified badges, ratings, clear booking flow
- **Simple navigation** — bottom nav bar with 4 tabs max

### Color Palette (suggestion — can be overridden)
- Primary: Deep Teal `#1A6B72` or Indigo `#3D5AFE`
- Accent: Warm Amber `#FFB300`
- Background: Off-white `#F8F9FA`
- Surface: White `#FFFFFF`
- Text Primary: `#1C1C1E`
- Text Secondary: `#6B7280`
- Success: `#22C55E`
- Error: `#EF4444`

### Typography
- Use **Inter** or **Poppins** font family
- Headings: Bold, 20–28sp
- Body: Regular, 14–16sp
- Labels: Medium, 12–13sp

### Listing Card Design
- Rounded corners (12px radius)
- Full-width image (16:9 or 4:3)
- Price per day in accent color
- Verified badge if owner is verified
- Distance from user
- Subtle drop shadow

### Bottom Navigation
```
[ Home ] [ Search ] [ Post ] [ Messages ] [ Profile ]
```
- "Post" center button with prominent styling (FAB-style)

---

## State Management (BLoC Pattern)

Each feature has its own BLoC:

```dart
// Example: AuthBloc
AuthBloc
  Events: LoginRequested, RegisterRequested, GoogleLoginRequested, LogoutRequested
  States: AuthInitial, AuthLoading, AuthAuthenticated(user), AuthError(message)
```

Global blocs provided at app root:
- `AuthBloc` — user session
- `NotificationBloc` — unread count badge
- `LocationBloc` — current country / city / currency / lat / lng

```dart
// LocationBloc — provided globally at app root
LocationBloc
  Events:
    DetectLocation                          // trigger on app start after login
    ManualLocationChanged(city, country, countryCode)  // user changes city manually
  States:
    LocationInitial
    LocationDetecting
    LocationDetected(city, country, countryCode, currency, lat, lng)
    LocationPermissionDenied               // user denied — show manual input
    LocationError(message)
```

> ⚠️ Every screen that fetches listings **must read from `LocationBloc`** to get the current country/city params before making API calls. Never hardcode a country or city in any screen.

---

## Location & Currency Logic

### Core Principle
The app detects the user's real-world location and uses it to **filter all listing data** — home screen, search results, and nearby listings all show only items from the user's detected country and city by default. The user can manually change their city at any time.

### Detection Flow (runs on every app start after login)

```dart
// Step 1: Request permission
// Use geolocator to request location permission.
// If denied → fallback to IP-based detection or ask user to enter city manually.

// Step 2: Get coordinates
// Position position = await Geolocator.getCurrentPosition()
// lat = position.latitude
// lng = position.longitude

// Step 3: Reverse geocode → city + country
// List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
// city    = placemarks.first.locality         // e.g. "Singapore"
// country = placemarks.first.country          // e.g. "Singapore"
// countryCode = placemarks.first.isoCountryCode // e.g. "SG"

// Step 4: Map country code → currency
// currency = CurrencyUtils.fromCountryCode(countryCode)
// e.g. 'SG' → 'SGD', 'IN' → 'INR', 'US' → 'USD', 'JP' → 'JPY'

// Step 5: Save to local storage
// SharedPreferences.setString('user_city', city)
// SharedPreferences.setString('user_country', country)
// SharedPreferences.setString('user_country_code', countryCode)
// SharedPreferences.setString('user_currency', currency)
// SharedPreferences.setDouble('user_lat', lat)
// SharedPreferences.setDouble('user_lng', lng)

// Step 6: Send to backend
// PUT /api/users/profile { city, country }
// This updates the user record so backend also knows their location

// Step 7: Inject into LocationBloc
// LocationBloc emits LocationDetected(city, country, countryCode, currency, lat, lng)
// All screens listen to LocationBloc for location-aware data fetching
```

### How Location Filters All Data

Every API call that fetches listings **must include location params** derived from `LocationBloc`:

```dart
// Home Screen — Featured listings (country-scoped)
GET /api/listings?country=SG

// Home Screen — Nearby listings (city + radius scoped)
GET /api/listings?country=SG&city=Singapore&lat=1.3521&lng=103.8198

// Search Results — always pre-filtered by user country
GET /api/listings?country=SG&search=...&categoryId=...

// User can expand search to other countries manually via filter
```

### LocationBloc

```dart
// States:
LocationInitial
LocationDetecting
LocationDetected(city, country, countryCode, currency, lat, lng)
LocationPermissionDenied   // fallback: show manual city input
LocationError(message)

// Events:
DetectLocation             // triggered on app start after login
ManualLocationChanged(city, country, countryCode)  // user changes city
```

### Manual Location Change (Home Screen Top Bar)

- User taps the city chip in the top bar of the Home Screen
- A bottom sheet opens with:
  - Current detected city shown
  - Text field to search/type a different city
  - Country selector dropdown
- On confirm → dispatch `ManualLocationChanged` to `LocationBloc`
- `LocationBloc` updates `SharedPreferences` and re-emits `LocationDetected`
- All screens that depend on location automatically re-fetch with new params
- Also PUT `/api/users/profile` with updated `{ city, country }`

### Permission Denied Fallback

If the user denies location permission:
1. Try IP-based fallback using a free geolocation API (e.g. `http://ip-api.com/json`)
2. If that also fails → show a "Set your location" prompt asking user to type their city
3. Store whatever city/country they enter and proceed
4. Never block the user from using the app — location is best-effort

### FCM Token Registration
```dart
// After login, get FCM token and POST to /api/users/fcm-token
// Body: { "fcmToken": "..." }
// Do this after location detection is complete
```

---

## Verification Gate UI

When an unverified user tries to:
- Post a listing with price > ₹1000 equivalent
- Exceed 2 listings/day or 5 listings/month

Show a bottom sheet or dialog:
```
"Verification Required"
To post high-value items or increase your listing limit,
please verify your identity.
[ Verify Now ] [ Maybe Later ]
```

---

## Push Notification Handling (FCM)

| Trigger | Notification |
|---------|-------------|
| New booking request | "Someone wants to rent your [item]" |
| Booking accepted | "Your booking for [item] was accepted!" |
| Booking cancelled | "Booking for [item] was cancelled" |
| Booking completed | "Your rental of [item] is complete. Leave a review!" |
| New chat message | "[Name]: [message preview]" |
| Verification approved | "Your identity has been verified ✓" |

Handle FCM in foreground (show in-app banner) and background (system notification).

---

## API Service (Dio Setup)

```dart
class ApiService {
  static final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  static void init() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired → logout user
        }
        handler.next(error);
      },
    ));
  }
}
```

---

## Backend Infrastructure (What the Flutter App Connects To)

The Flutter app talks exclusively to the **Node.js REST API**. It never connects directly to any infrastructure service. Here is what the backend uses under the hood:

| Service | Provider | Purpose |
|---------|----------|---------|
| PostgreSQL | **Neon** (serverless) | All relational data — users, listings, bookings, reviews, etc. |
| Redis | **Upstash** (serverless) | JWT blacklist (logout), rate limiting, OTP caching, session cache |
| Image Storage | **Cloudinary** | All listing images and user avatars — backend uploads, returns CDN URLs |
| Real-time Chat | Firebase Firestore | Direct read & write from Flutter — no backend relay |
| Push Notifications | Firebase FCM | Push notifications — triggered by Firestore Cloud Functions or backend |

### What this means for Flutter:
- **Images:** Always loaded from **Cloudinary CDN URLs**. Use `cached_network_image`. Never upload to Cloudinary directly from Flutter — images go through backend which uploads to Cloudinary and returns the URL.
- **Auth:** JWT issued by backend, stored in `flutter_secure_storage`. Neon/Upstash are invisible to the app.
- **Rate limiting:** Enforced server-side via Upstash Redis — handle `429 Too Many Requests` gracefully with a user-friendly message.
- **Chat:** Flutter reads and writes **directly to Firestore**. No backend relay for messages. FCM push notifications are triggered by Firestore Cloud Functions when a new message document is created.
- **FCM:** Flutter receives push notifications passively. Never calls FCM send APIs directly.

```dart
// cloudinary_service.dart — URL transformation helper
class CloudinaryService {
  static const String _baseUrl = 'https://res.cloudinary.com/renthubindia/image/upload';

  /// Returns an optimised image URL with transformation params
  static String optimise(String publicIdOrUrl, {int width = 400, int height = 300}) {
    // Extract public ID if full URL passed
    final publicId = publicIdOrUrl.contains('/upload/')
        ? publicIdOrUrl.split('/upload/').last
        : publicIdOrUrl;
    return '$_baseUrl/w_$width,h_$height,c_fill,q_auto,f_auto/$publicId';
  }
}
```

---

## Future-Ready Notes
- **Payments:** Add `flutter_stripe` package + Booking payment screen when backend adds Stripe
- **Ads:** Home screen has a dedicated slot reserved between sections for future ad banners
- **Featured Listings:** Listing card already supports a `isFeatured` flag for gold border/badge
- **Multi-language:** Wrap all strings in `AppLocalizations` from day one
- **Admin app:** Admin panel is a separate web app, not part of this Flutter app

---

## ✅ Real API Endpoint Cheat Sheet (Source of Truth)

Use this as the definitive reference when writing repository or service code in Flutter.

| Module | Method | Endpoint | Auth |
|--------|--------|----------|------|
| Auth | POST | `/api/auth/register` | ❌ |
| Auth | POST | `/api/auth/login` | ❌ |
| Auth | POST | `/api/auth/forgot-password` | ❌ |
| Auth | POST | `/api/auth/verify-otp` | ❌ |
| Auth | POST | `/api/auth/reset-password` | ❌ |
| Auth | POST | `/api/auth/logout` | ✅ |
| Users | GET | `/api/users/profile` | ✅ |
| Users | PUT | `/api/users/profile` | ✅ |
| Users | POST | `/api/users/avatar` | ✅ multipart |
| Users | POST | `/api/users/fcm-token` | ✅ |
| Users | POST | `/api/users/me/verify` | ✅ multipart |
| Users | GET | `/api/users/:id` | ✅ |
| Categories | GET | `/api/categories` | ❌ |
| Listings | GET | `/api/listings` | ❌ |
| Listings | GET | `/api/listings/:id` | ❌ |
| Listings | POST | `/api/listings` | ✅ |
| Listings | POST | `/api/listings/:id/images` | ✅ multipart |
| Listings | PATCH | `/api/listings/:id/status` | ✅ |
| Listings | GET | `/api/listings/my/listings` | ✅ |
| Bookings | POST | `/api/bookings` | ✅ |
| Bookings | GET | `/api/bookings/my` | ✅ |
| Bookings | GET | `/api/bookings/incoming` | ✅ |
| Bookings | PATCH | `/api/bookings/:id/accept` | ✅ |
| Bookings | PATCH | `/api/bookings/:id/cancel` | ✅ |
| Bookings | PATCH | `/api/bookings/:id/complete` | ✅ |
| Reviews | POST | `/api/reviews` | ✅ body: `{ bookingId, rating, comment }` |
| Reviews | GET | `/api/reviews/listing/:id?page=1&limit=10` | ❌ |
| Reviews | GET | `/api/reviews/user/:id?page=1&limit=10` | ❌ |
| Reports | POST | `/api/reports` | ✅ body: `{ targetType, targetId, category, description }` |
| Notifications | GET | `/api/notifications` | ✅ |
| Notifications | PATCH | `/api/notifications/read-all` | ✅ — register BEFORE `/:id/read` |
| Notifications | PATCH | `/api/notifications/:id/read` | ✅ |
| Support | POST | `/api/support/tickets` | ✅ |
| Support | GET | `/api/support/tickets` | ✅ |
| Support | GET | `/api/support/tickets/:id` | ✅ |

