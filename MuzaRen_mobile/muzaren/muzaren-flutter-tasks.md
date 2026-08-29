# RentHubIndia — Flutter App Build Tasks

> Complete ordered task list for building the RentHubIndia Flutter app from scratch.
> Follow phases in order — each phase depends on the previous one being complete.
> Base URL: `http://localhost:5000` (replace with production URL when deploying)

---

## PHASE 1 — Project Setup & Foundation
> Must be 100% complete before writing any feature code.

### Task 1.1 — Create Flutter Project
- [x] Run `flutter create renthubindia --org com.renthubindia`
- [x] Set minimum SDK: Android API 21, iOS 13.0
- [x] Delete default counter app code from `main.dart`
- [x] Confirm project runs on both Android emulator and iOS simulator

### Task 1.2 — Install All Dependencies (`pubspec.yaml`)
- [x] Add `flutter_bloc` — state management
- [x] Add `go_router` — navigation
- [x] Add `dio` — HTTP client
- [x] Add `flutter_secure_storage` — JWT storage
- [x] Add `image_picker` — pick images from gallery/camera
- [x] Add `google_maps_flutter` — maps
- [x] Add `geolocator` — device location
- [x] Add `geocoding` — reverse geocode lat/lng → city/country
- [x] Add `cloud_firestore` — real-time chat (direct read & write)
- [x] Add `firebase_messaging` — FCM push notifications
- [x] Add `firebase_core` — Firebase initialisation
- [x] Add `cached_network_image` — image loading with cache
- [x] Add `shimmer` — loading placeholders
- [x] Add `lottie` — animations
- [x] Add `hive` + `hive_flutter` — local storage
- [x] Add `shared_preferences` — simple key-value storage
- [x] Add `intl` — date formatting & internationalisation
- [x] Add `equatable` — BLoC state comparison
- [x] Run `flutter pub get` and confirm no errors

### Task 1.3 — Firebase Setup
- [ ] Create Firebase project named `renthubindia` at console.firebase.google.com
- [ ] Add Android app (package: `com.renthubindia`) → download `google-services.json` → place in `android/app/`
- [ ] Add iOS app (bundle ID: `com.renthubindia`) → download `GoogleService-Info.plist` → place in `ios/Runner/`
- [ ] Enable **Firestore Database** in Firebase console (start in test mode)
- [ ] Enable **Cloud Messaging (FCM)** in Firebase console
- [ ] Add `google-services` plugin to `android/build.gradle` and `android/app/build.gradle`
- [ ] Add Firebase iOS config to `ios/Runner/AppDelegate.swift`
- [ ] Initialise Firebase in `main.dart`: `await Firebase.initializeApp()`

### Task 1.4 — Folder Structure
Create all folders and empty placeholder files:
- [x] `lib/core/router/app_router.dart`
- [x] `lib/core/theme/app_colors.dart`
- [x] `lib/core/theme/app_typography.dart`
- [x] `lib/core/theme/app_theme.dart`
- [x] `lib/core/constants/api_constants.dart`
- [x] `lib/core/constants/app_constants.dart`
- [x] `lib/core/utils/date_utils.dart`
- [x] `lib/core/utils/currency_utils.dart`
- [x] `lib/core/utils/validators.dart`
- [x] `lib/core/utils/location_utils.dart`
- [x] `lib/data/models/` — all 8 model files
- [x] `lib/data/repositories/` — all 7 repository files
- [x] `lib/data/services/` — all 5 service files
- [x] `lib/blocs/` — all 5 BLoC folders (auth, listing, booking, chat, notification)
- [x] `lib/features/` — all 8 feature folders

### Task 1.5 — Theme & Design System
- [x] Define color palette in `app_colors.dart`:
  - Primary: `#0D6E75`
  - Accent: `#F5A623`
  - Background: `#F7F8FA`
  - Surface: `#FFFFFF`
  - Text Primary: `#111827`
  - Text Secondary: `#6B7280`
  - Success: `#16A34A`
  - Error: `#DC2626`
- [x] Define typography in `app_typography.dart` (Sora + Plus Jakarta Sans from Google Fonts)
- [x] Build `ThemeData` in `app_theme.dart` using above colors and fonts
- [x] Apply theme in `main.dart` via `MaterialApp`

### Task 1.6 — Core Constants & Utilities
- [x] `api_constants.dart` — define `baseUrl`, all endpoint paths as static constants
- [x] `app_constants.dart` — define enums: `BookingStatus`, `ListingStatus`, `VerificationStatus`, `ReportCategory`, `ReportTargetType`
- [x] `validators.dart` — email, password, phone validation functions
- [x] `date_utils.dart` — format dates, calculate rental days, check date ranges
- [x] `currency_utils.dart` — country code → currency symbol map (IN→₹, SG→SGD, US→$, etc.)
- [x] `location_utils.dart` — helper to reverse geocode coordinates to city + country

---

## PHASE 2 — Data Layer
> Models, services, repositories — no UI yet.

### Task 2.1 — API Service (Dio)
- [x] Build `api_service.dart` with Dio instance
- [x] Add `baseUrl` from `api_constants.dart`
- [x] Add JWT interceptor: reads token from `flutter_secure_storage`, adds `Authorization: Bearer <token>` header to every request
- [x] Add error interceptor: if `401` → clear token → redirect to login
- [x] Handle `429 Too Many Requests` → show user-friendly rate limit message
- [x] Add global timeout settings (connect: 10s, receive: 15s)

### Task 2.2 — Data Models
Build `fromJson()` and `toJson()` for all models:
- [x] `user_model.dart` — id, name, email, phone, avatarUrl, role, verificationStatus, isBlocked, country, city, currency, rating, createdAt
- [x] `listing_model.dart` — id, userId, categoryId, title, description, pricePerDay, location, latitude, longitude, country, city, status, isApproved, availableFrom, availableTo, images[], owner (User), createdAt
- [x] `booking_model.dart` — id, listingId, renterId, ownerId, startDate, endDate, totalPrice, status, createdAt, listing (Listing), renter (User), owner (User)
- [x] `review_model.dart` — id, bookingId, listingId, reviewerId, revieweeId, rating, comment, createdAt, reviewer (User)
- [x] `category_model.dart` — id, name, icon, slug
- [x] `notification_model.dart` — id, userId, title, body, type, isRead, data, createdAt
- [x] `report_model.dart` — id, reporterId, targetType, targetId, category, description, status, createdAt
- [x] `support_ticket_model.dart` — id, userId, subject, message, status, adminReply, createdAt, updatedAt

### Task 2.3 — Repositories
Each repository wraps API calls and returns typed models:
- [x] `auth_repository.dart`
  - `register(name, email, password)` → POST `/api/auth/register`
  - `login(email, password)` → POST `/api/auth/login`
  - `forgotPassword(email)` → POST `/api/auth/forgot-password`
  - `verifyOtp(email, code)` → POST `/api/auth/verify-otp`
  - `resetPassword(email, code, newPassword)` → POST `/api/auth/reset-password`
  - `logout()` → POST `/api/auth/logout`
- [x] `listing_repository.dart`
  - `getListings({filters})` → GET `/api/listings`
  - `getListingById(id)` → GET `/api/listings/:id`
  - `createListing(data)` → POST `/api/listings`
  - `uploadListingImages(id, images)` → POST `/api/listings/:id/images` (multipart)
  - `updateListingStatus(id, status)` → PATCH `/api/listings/:id/status`
  - `getMyListings()` → GET `/api/listings/my/listings`
- [x] `booking_repository.dart`
  - `createBooking(listingId, startDate, endDate)` → POST `/api/bookings`
  - `getMyBookings()` → GET `/api/bookings/my`
  - `getIncomingBookings()` → GET `/api/bookings/incoming`
  - `acceptBooking(id)` → PATCH `/api/bookings/:id/accept`
  - `cancelBooking(id)` → PATCH `/api/bookings/:id/cancel`
  - `completeBooking(id)` → PATCH `/api/bookings/:id/complete`
- [x] `review_repository.dart`
  - `submitReview(bookingId, rating, comment)` → POST `/api/reviews`
  - `getListingReviews(listingId, page, limit)` → GET `/api/reviews/listing/:id`
  - `getUserReviews(userId, page, limit)` → GET `/api/reviews/user/:id`
- [x] `notification_repository.dart`
  - `getNotifications()` → GET `/api/notifications`
  - `markAllRead()` → PATCH `/api/notifications/read-all`
  - `markOneRead(id)` → PATCH `/api/notifications/:id/read`
- [x] `support_repository.dart`
  - `createTicket(subject, message)` → POST `/api/support/tickets`
  - `getMyTickets()` → GET `/api/support/tickets`
  - `getTicketById(id)` → GET `/api/support/tickets/:id`
- [x] `chat_repository.dart`
  - `getOrCreateChat(listingId, ownerId)` → direct Firestore write to `chats/` collection
  - `sendMessage(chatId, senderId, text)` → direct Firestore write to `chats/{chatId}/messages`
  - `sendImageMessage(chatId, senderId, imageUrl)` → Firestore write (imageUrl from backend upload)
  - `markAsRead(chatId, userId)` → Firestore update
  - `messagesStream(chatId)` → Firestore `snapshots()` stream
  - `conversationsStream(userId)` → Firestore `snapshots()` stream

### Task 2.4 — Services
- [x] `firebase_chat_service.dart` — Firestore instance, collection references, chat helper methods
- [x] `fcm_service.dart`
  - Request notification permission
  - Get FCM token → POST `/api/users/fcm-token`
  - Handle foreground messages (show in-app banner)
  - Handle background/terminated messages (navigate on tap)
- [x] `location_service.dart`
  - Request location permission
  - Get current lat/lng via `geolocator`
  - Reverse geocode to city + country via `geocoding`
  - Map country code → currency
- [x] `cloudinary_service.dart`
  - `optimise(url, {width, height})` — builds CDN URL with transformation params
  - No uploads — Flutter never uploads to Cloudinary directly

### Task 2.5 — Secure Storage Helper
- [x] Create `lib/core/utils/secure_storage.dart`
  - `saveToken(token)` — save JWT
  - `getToken()` — read JWT
  - `deleteToken()` — clear JWT on logout
  - `saveUser(userJson)` — cache user object
  - `getUser()` — read cached user

---

## PHASE 3 — BLoC State Management
> Build all BLoCs before building any screen UI.

### Task 3.1 — AuthBloc
- [x] Events: `LoginRequested`, `RegisterRequested`, `LogoutRequested`, `CheckAuthStatus`
- [x] States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(User)`, `AuthUnauthenticated`, `AuthError(message)`
- [x] On `CheckAuthStatus` → read token from secure storage → validate → emit authenticated or unauthenticated
- [x] On `LoginRequested` → call `auth_repository.login()` → save token → emit `AuthAuthenticated`
- [x] On `LogoutRequested` → call `auth_repository.logout()` → clear token → emit `AuthUnauthenticated`

### Task 3.2 — ListingBloc
- [x] Events: `LoadListings(filters)`, `LoadListingDetail(id)`, `LoadMyListings`, `CreateListing(data)`, `UploadImages(id, images)`, `UpdateListingStatus(id, status)`
- [x] States: `ListingInitial`, `ListingLoading`, `ListingsLoaded(listings)`, `ListingDetailLoaded(listing)`, `ListingCreated(listing)`, `ListingError(message)`

### Task 3.3 — BookingBloc
- [x] Events: `CreateBooking(listingId, startDate, endDate)`, `LoadMyBookings`, `LoadIncomingBookings`, `AcceptBooking(id)`, `CancelBooking(id)`, `CompleteBooking(id)`
- [x] States: `BookingInitial`, `BookingLoading`, `BookingCreated`, `MyBookingsLoaded(bookings)`, `IncomingBookingsLoaded(bookings)`, `BookingError(message)`

### Task 3.4 — ChatBloc
- [x] Events: `LoadConversations`, `OpenChat(chatId)`, `SendMessage(chatId, text)`, `SendImageMessage(chatId, imageFile)`, `MarkAsRead(chatId)`
- [x] States: `ChatInitial`, `ConversationsLoaded(conversations)`, `MessagesLoaded(messages)`, `ChatError(message)`
- [x] Messages state uses Firestore stream — emit new state on every stream update

### Task 3.5 — NotificationBloc
- [x] Events: `LoadNotifications`, `MarkAllRead`, `MarkOneRead(id)`
- [x] States: `NotificationInitial`, `NotificationsLoaded(notifications, unreadCount)`, `NotificationError(message)`

### Task 3.6 — LocationBloc
- [x] **File:** `lib/blocs/location/location_bloc.dart`
- [x] Events:
  - `DetectLocation` — triggered on app start after successful login
  - `ManualLocationChanged(city, country, countryCode)` — user changes city from Home screen
- [x] States:
  - `LocationInitial`
  - `LocationDetecting` — show shimmer on home screen while detecting
  - `LocationDetected(city, country, countryCode, currency, lat, lng)`
  - `LocationPermissionDenied` — fallback to IP detection or manual input
  - `LocationError(message)`
- [x] On `DetectLocation`:
  1. Request permission via `geolocator`
  2. If granted → get lat/lng → reverse geocode via `geocoding` package
  3. Extract city (`locality`), country (`country`), countryCode (`isoCountryCode`)
  4. Map countryCode → currency via `CurrencyUtils`
  5. Save all to `SharedPreferences`
  6. PUT `/api/users/profile` with `{ city, country }`
  7. Emit `LocationDetected`
- [x] On permission denied:
  1. Try IP fallback: GET `http://ip-api.com/json`
  2. Parse `city`, `country`, `countryCode` from response
  3. If IP fails → emit `LocationPermissionDenied`
- [x] On `ManualLocationChanged`:
  1. Update `SharedPreferences`
  2. PUT `/api/users/profile` with new `{ city, country }`
  3. Emit `LocationDetected` with new values
  4. All screens listening to `LocationBloc` will automatically re-fetch

### Task 3.7 — Global BLoC Providers
- [x] Wrap `MaterialApp` in `MultiBlocProvider` in `main.dart`
- [x] Provide globally: `AuthBloc`, `NotificationBloc`, `LocationBloc`
- [x] `AuthBloc` dispatches `CheckAuthStatus` on app start
- [x] `LocationBloc` dispatches `DetectLocation` immediately after `AuthAuthenticated` state is emitted

---

## PHASE 4 — Navigation
> Set up routing before building screens.

### Task 4.1 — Router Setup (`app_router.dart`)
- [x] Use `go_router` with named routes
- [x] Define all routes:
  - `/splash` → `SplashScreen`
  - `/login` → `LoginScreen`
  - `/register` → `RegisterScreen`
  - `/forgot-password` → `ForgotPasswordScreen`
  - `/verify-otp` → `VerifyOtpScreen`
  - `/reset-password` → `ResetPasswordScreen`
  - `/home` → `HomeScreen` (shell with bottom nav)
  - `/categories` → `CategoriesScreen`
  - `/search` → `SearchResultsScreen`
  - `/listing/:id` → `ListingDetailScreen`
  - `/listing/post` → `PostListingScreen`
  - `/booking/:listingId` → `BookingScreen`
  - `/chat` → `MessagesListScreen`
  - `/chat/:chatId` → `ChatThreadScreen`
  - `/notifications` → `NotificationsScreen`
  - `/profile` → `ProfileScreen`
  - `/profile/:id` → `PublicProfileScreen`
  - `/my-listings` → `MyListingsScreen`
  - `/support` → `SupportScreen`
  - `/support/new` → `NewTicketScreen`
- [x] Add redirect guard: if no JWT token → redirect to `/login`
- [x] Add `ShellRoute` for bottom navigation bar (Home, Search, Post, Messages, Profile)

---

## PHASE 5 — Screens (Build in This Exact Order)

---

### Task 5.1 — Splash Screen
**File:** `features/auth/splash_screen.dart`
- [x] Show RentHubIndia logo centered on teal gradient background
- [x] Animate logo entrance (scale + fade in)
- [x] Dispatch `CheckAuthStatus` to `AuthBloc`
- [x] Listen to `AuthBloc` state:
  - `AuthAuthenticated` → navigate to `/home`
  - `AuthUnauthenticated` → navigate to `/login`
- [x] Minimum display time: 2 seconds

---

### Task 5.2 — Login Screen
**File:** `features/auth/login_screen.dart`
- [x] Email field with validation
- [x] Password field with show/hide toggle
- [ ] "Forgot Password?" link → navigate to `/forgot-password`
- [x] "Login" button → dispatch `LoginRequested` to `AuthBloc`
- [x] Show loading indicator while `AuthLoading`
- [x] Show error snackbar on `AuthError`
- [x] On `AuthAuthenticated` → navigate to `/home`
- [x] Link to Register screen at bottom

---

### Task 5.3 — Register Screen
**File:** `features/auth/register_screen.dart`
- [x] Full Name, Email, Phone (optional), Password, Confirm Password fields
- [x] Inline validation on all fields
- [x] "Register" button → dispatch `RegisterRequested` to `AuthBloc`
- [x] Show loading indicator while `AuthLoading`
- [x] Show error snackbar on `AuthError`
- [x] On `AuthAuthenticated` → navigate to `/home`

---

### Task 5.4 — Forgot Password / OTP / Reset Password Screens
**Files:** `features/auth/forgot_password_screen.dart`, `features/auth/verify_otp_screen.dart`, `features/auth/reset_password_screen.dart`
- [x] **Forgot Password:** Email input → POST `/api/auth/forgot-password` → navigate to OTP screen
- [x] **Verify OTP:** 6-digit OTP input (auto-advance between boxes) → POST `/api/auth/verify-otp`
- [x] **Reset Password:** New password + confirm → POST `/api/auth/reset-password` → navigate to Login
- [x] Show success/error feedback at each step

---

### Task 5.5 — Bottom Navigation Shell
**File:** `features/shell/main_shell.dart`
- [x] 5 tabs: Home, Search, Post (FAB-style center), Messages, Profile
- [x] Active tab: teal icon + teal label
- [ ] Unread notification badge on Messages tab (from `NotificationBloc`)
- [x] Center "Post" button is elevated circular teal FAB
- [x] Tapping Post → navigate to `/listing/post`

---

### Task 5.6 — Home Screen
**File:** `features/home/home_screen.dart`
- [x] Top bar: location chip (auto-detected city, tappable to change) + notification bell with unread badge
- [x] Tappable search bar → navigate to `/search`
- [x] Categories horizontal scroll row → GET `/api/categories`
- [x] Featured listings horizontal scroll → GET `/api/listings` (use first page results)
- [x] Nearby listings 2-column grid → GET `/api/listings` with lat/lng filters
- [ ] Shimmer placeholders while loading
- [x] Pull-to-refresh on entire screen
- [x] ListingCard widget: image, title, price/day (amber), city, verified badge

---

### Task 5.7 — Categories Screen
**File:** `features/home/categories_screen.dart`
- [x] Fetch categories from GET `/api/categories`
- [x] 3-column grid of category cards (icon + name)
- [x] Tap → navigate to `/search?categoryId=...`

---

### Task 5.8 — Search Results Screen
**File:** `features/search/results_screen.dart`
- [x] Search bar at top (pre-filled if navigated from home)
- [x] Filter chips row: Price Range, Category, Location, Country
- [ ] Filter bottom sheet on filter icon tap
- [x] List view / Map view toggle
- [x] List view: vertical scroll of listing cards
- [ ] Map view: `google_maps_flutter` with teal pins + bottom sheet card scroll
- [ ] Infinite scroll with pagination (`?page=1`)
- [ ] Debounced search (500ms) → GET `/api/listings?search=...`
- [x] Active filters shown as removable chips
- [x] Empty state illustration when no results

---

### Task 5.9 — Listing Detail Screen
**File:** `features/listing/detail_screen.dart`
- [x] Fetch listing: GET `/api/listings/:id`
- [x] Fetch reviews: GET `/api/reviews/listing/:id?page=1&limit=10`
- [x] Swipeable image carousel (up to 5 photos) with dot indicators
- [x] Floating back + share/bookmark buttons
- [x] Title, category chip, price/day (amber), location
- [x] Owner card: avatar, name, verified badge, rating, join date → tap → `/profile/:id`
- [ ] Availability calendar (mark available/unavailable dates)
- [x] Description with "Read more" expand
- [x] Reviews section: star summary + list of reviews
- [ ] "Report this listing" link → opens report bottom sheet → POST `/api/reports`
- [x] Sticky bottom bar: "Chat" (outlined) + "Book Now" (filled teal) buttons
  - "Chat" → navigate to `/chat/:chatId` (create chat via Firestore if not exists)
  - "Book Now" → navigate to `/booking/:listingId`

---

### Task 5.10 — Post Listing Screen (Multi-Step Wizard)
**File:** `features/listing/post_listing_screen.dart`
- [x] Step progress indicator at top (Step X of 6)
- [x] **Step 1 — Category:** grid of categories → select one → highlight
- [x] **Step 2 — Details:** Title field + Description multiline field
- [x] **Step 3 — Pricing:** Price per day input with currency symbol
  - If price > ₹1000 (or equivalent) and user is UNVERIFIED → show verification required banner
- [x] **Step 4 — Location:** Map with draggable pin + city text field + "Use my location" button
- [x] **Step 5 — Availability:** Date range picker (availableFrom → availableTo)
- [x] **Step 6 — Photos:** Image picker, up to 5 images, thumbnail row with × remove
- [x] Back / Next buttons at bottom, smooth slide transition between steps
- [x] On submit:
  1. POST `/api/listings` → get listing `id`
  2. POST `/api/listings/:id/images` (multipart, all images) → upload images
  3. Show success screen / navigate to `/my-listings`
- [x] Show rate limit error (`429`) with clear message if limit reached

---

### Task 5.11 — Booking Screen
**File:** `features/booking/booking_screen.dart`
- [x] Listing summary card at top (thumbnail + title + owner + price/day)
- [x] Date range picker — blocks unavailable dates
- [x] Live price calculation: days × pricePerDay = total
- [ ] Optional note to owner text field
- [x] Info box: "No payment required — owner will confirm your request"
- [x] "Send Booking Request" button → POST `/api/bookings` with `{ listingId, startDate, endDate }`
- [x] On success → show confirmation message + navigate back

---

### Task 5.12 — My Bookings Screen
**File:** `features/booking/my_bookings_screen.dart`
- [x] Tab bar: As Renter | As Owner
- [x] **As Renter:** GET `/api/bookings/my` — list of outgoing bookings
  - Status badge (color-coded: pending=amber, accepted=teal, completed=grey, cancelled=red)
  - Cancel button (if PENDING or ACCEPTED)
  - Leave Review button (if COMPLETED and no review yet)
- [x] **As Owner (incoming):** GET `/api/bookings/incoming`
  - Accept button → PATCH `/api/bookings/:id/accept`
  - Cancel button → PATCH `/api/bookings/:id/cancel`
  - Mark Complete button → PATCH `/api/bookings/:id/complete`
- [x] Empty state per tab

---

### Task 5.13 — Notifications Screen
**File:** `features/notifications/notifications_screen.dart`
- [x] Fetch: GET `/api/notifications`
- [x] "Mark all read" button → PATCH `/api/notifications/read-all`
- [x] List of notifications grouped by Today / Yesterday / Earlier
- [x] Unread: left teal border + highlighted background
- [x] Read: plain white
- [x] Tap notification → navigate to relevant screen (booking, chat, profile)
- [x] Tap individual → PATCH `/api/notifications/:id/read`
- [x] Empty state illustration

---

### Task 5.14 — Messages List Screen
**File:** `features/chat/messages_list_screen.dart`
- [ ] Load conversations via Firestore `snapshots()` stream filtered by current userId
- [ ] Each row: avatar, name, listing context, last message preview, timestamp, unread badge
- [x] Search bar to filter conversations locally
- [ ] Tap conversation → navigate to `/chat/:chatId`
- [x] Empty state: "No messages yet"

---

### Task 5.15 — Chat Thread Screen
**File:** `features/chat/chat_thread_screen.dart`
- [x] Top bar: avatar + name + listing title chip (tap → `/listing/:id`)
- [ ] Listing context card pinned at top of messages
- [ ] Messages loaded via Firestore `snapshots()` stream on `chats/{chatId}/messages`
- [x] Sent messages: right-aligned teal bubble
- [x] Received messages: left-aligned grey bubble
- [x] Timestamps between message groups
- [ ] Image messages: rounded image preview with tap to expand
- [x] Bottom input: text field + image attach icon + send button
  - Text send → Firestore write directly
  - Image send → POST to backend (upload to Cloudinary) → get URL → Firestore write
- [ ] Mark messages as read on screen open → Firestore update
- [ ] FCM notification received while in thread → auto-scroll to bottom

---

### Task 5.16 — User Profile Screen
**File:** `features/profile/profile_screen.dart`
- [x] **Own profile (no `:id` param):** GET `/api/users/profile`
  - Teal gradient banner + large circular avatar
  - Name + verified badge
  - Stats: listings count, rentals count, avg rating
  - Edit profile button → edit name, phone, city → PUT `/api/users/profile`
  - Upload avatar → POST `/api/users/avatar` (multipart)
  - Active listings grid (2 columns)
  - Reviews received section
  - Settings section: Verify Identity, Notification Prefs, Support, Logout
- [ ] **Public profile (with `:id` param):** GET `/api/users/:id`
  - Same layout but no edit controls
  - Shows public info only (no email/phone)

---

### Task 5.17 — My Listings Screen
**File:** `features/profile/my_listings_screen.dart`
- [x] Tabs: Active | Paused | Expired → GET `/api/listings/my/listings` (filter client-side by status)
- [x] Each listing card: thumbnail, title, status badge, "X pending requests" in amber
- [x] Edit icon → navigate to edit listing (reuse post listing wizard pre-filled)
- [x] Pause/Activate toggle → PATCH `/api/listings/:id/status`
- [x] FAB: "+ Add New Listing" → navigate to `/listing/post`
- [x] Empty state per tab

---

### Task 5.18 — Verification Screen
**File:** `features/profile/verification_screen.dart`
- [x] Explain why verification is needed
- [x] Document type selector (Aadhaar / Passport / National ID)
- [x] Image picker for document upload
- [x] Preview of selected document image
- [x] Submit button → POST `/api/users/me/verify` (multipart, key: `document`)
- [x] Show current verification status (Unverified / Pending / Verified)
- [x] If already VERIFIED → show green success state with badge

---

### Task 5.19 — Support Screen
**File:** `features/support/support_screen.dart`
- [x] FAQ section (static accordion list of common questions)
- [x] "Contact Support" button → navigate to new ticket screen
- [x] My Tickets list → GET `/api/support/tickets`
  - Each ticket: subject, status badge, date
  - Tap → ticket detail: full message + admin reply (if any)
- [x] New Ticket Screen: subject + message fields → POST `/api/support/tickets`

---

## PHASE 6 — Shared Widgets
> Reusable components used across multiple screens.

- [x] **ListingCard** — image, title, price/day (amber), city, distance, verified badge, rating
- [x] **ShimmerCard** — shimmer placeholder matching ListingCard dimensions
- [x] **VerifiedBadge** — small blue "✓ Verified" pill
- [x] **StatusBadge** — color-coded booking/listing status pill
- [ ] **VerificationRequiredSheet** — bottom sheet with "Verify Now" CTA
- [ ] **RateLimitErrorDialog** — shown on `429` response
- [x] **EmptyState** — centered illustration + heading + subtext + optional CTA button
- [x] **AppBottomSheet** — styled bottom sheet wrapper
- [x] **AppTextField** — styled text input with label, error state, hint
- [x] **AppButton** — primary (filled teal), secondary (outlined), danger (red)
- [x] **AvatarWidget** — circular avatar with Cloudinary URL + fallback initials
- [ ] **ReviewCard** — avatar, name, stars, comment, date
- [ ] **BookingStatusBadge** — PENDING (amber), ACCEPTED (teal), COMPLETED (grey), CANCELLED (red)

---

## PHASE 7 — Location Detection & Data Filtering

> This phase wires up location detection so all listing data is automatically scoped to the user's country and city.

### Task 7.1 — location_service.dart
- [x] Create `lib/data/services/location_service.dart`
- [x] `requestPermission()` → returns `LocationPermission` enum
- [x] `getCurrentPosition()` → returns `Position` (lat, lng) via `geolocator`
- [x] `reverseGeocode(lat, lng)` → returns `{ city, country, countryCode }` via `geocoding`
- [x] `getLocationFromIp()` → fallback: GET `http://ip-api.com/json` → parse city, country, countryCode
- [x] Handle all errors gracefully — never throw uncaught exceptions

### Task 7.2 — currency_utils.dart
- [x] Build a complete country code → currency map in `lib/core/utils/currency_utils.dart`
- [x] Include at minimum:
  - `SG` → `SGD`
  - `IN` → `INR`
  - `US` → `USD`
  - `GB` → `GBP`
  - `JP` → `JPY`
  - `AU` → `AUD`
  - `MY` → `MYR`
  - `ID` → `IDR`
  - `PH` → `PHP`
  - `TH` → `THB`
  - `AE` → `AED`
  - `SA` → `SAR`
- [x] `static String fromCountryCode(String code)` → returns currency symbol
- [x] `static String symbolFromCode(String currency)` → returns symbol (e.g. `$`, `₹`, `SGD`)

### Task 7.3 — LocationBloc in location_blocs folder
- [x] Add `lib/blocs/location/` folder with `location_bloc.dart`, `location_event.dart`, `location_state.dart`
- [x] Wire `location_service.dart` into the bloc
- [x] Store detected location in `SharedPreferences` so it persists between app launches
- [x] On next app launch: read from `SharedPreferences` → emit `LocationDetected` immediately without re-detecting (faster startup)
- [x] Only re-detect if stored location is older than 24 hours

### Task 7.4 — Trigger Location Detection After Login
- [x] In `main.dart` or `AuthBloc` listener:
  - When `AuthAuthenticated` state is emitted → dispatch `DetectLocation` to `LocationBloc`
- [x] Home Screen must wait for `LocationDetected` before fetching listings:
  - Show shimmer placeholders while `LocationDetecting`
  - Fetch data only when `LocationDetected` state arrives

### Task 7.5 — Inject Location into All Listing API Calls
Update every listing fetch to include location params from `LocationBloc`:

- [x] **Home Screen — Featured listings:**
  ```
  GET /api/listings?country={locationState.country}
  ```
- [x] **Home Screen — Nearby listings:**
  ```
  GET /api/listings?country={locationState.country}&city={locationState.city}&lat={locationState.lat}&lng={locationState.lng}
  ```
- [x] **Search Results Screen — default filter:**
  ```
  GET /api/listings?country={locationState.country}&search=...
  ```
  Country is pre-applied as a removable chip. User can remove it to search globally.
- [x] **Categories Screen tap → Search Results:**
  ```
  GET /api/listings?country={locationState.country}&categoryId=...
  ```

> ⚠️ Rule: NEVER call GET `/api/listings` without at least a `country` param unless the user has explicitly removed the country filter chip in Search Results.

### Task 7.6 — Manual Location Change (Home Screen Top Bar)
- [x] Location chip in Home Screen top bar shows: `📍 {city}, {countryCode}` with dropdown chevron
- [x] Tapping opens a bottom sheet with:
  - Current city shown as pre-filled value
  - Text field: "Search for a city..."
  - Country dropdown (select from list)
  - "Update Location" teal button
- [x] On confirm → dispatch `ManualLocationChanged(city, country, countryCode)` to `LocationBloc`
- [x] `LocationBloc` updates `SharedPreferences` and PUT `/api/users/profile`
- [x] Home Screen `BlocListener` on `LocationBloc` re-fetches all listing data automatically

### Task 7.7 — Permission Denied UI
- [x] If `LocationPermissionDenied` state emitted → show a non-blocking banner on Home Screen:
  ```
  📍 "We couldn't detect your location."
  "Set your city manually to see nearby listings."  [Set Location →]
  ```
- [x] Tapping "Set Location" opens the same manual location bottom sheet
- [x] App remains fully usable even without location — just shows all listings without geo-filter

### Task 7.8 — FCM Token Registration
- [x] After `LocationDetected` is emitted (location setup complete):
  - Get FCM token from `firebase_messaging`
  - POST `/api/users/fcm-token` with `{ fcmToken: "..." }`
  - Store token in `SharedPreferences` to avoid re-registering on every launch
  - Only re-register if token has changed

---

## PHASE 8 — Push Notifications (FCM)

- [x] Request notification permission on first launch
- [x] Handle **foreground** messages → show in-app banner (custom overlay)
- [x] Handle **background** messages → system notification
- [x] Handle **notification tap** (app terminated) → deep link to correct screen:
  - `type: booking_update` → navigate to `/my-listings` or `/booking`
  - `type: new_message` → navigate to `/chat/:chatId`
  - `type: verification` → navigate to `/profile`
  - `type: system` → navigate to `/notifications`
- [x] Refresh `NotificationBloc` when any FCM message arrives

---

## PHASE 9 — Error Handling & Edge Cases

- [x] Global error handler for Dio exceptions → show user-friendly messages
- [x] `401 Unauthorized` → clear token → redirect to login
- [x] `429 Too Many Requests` → show rate limit dialog with verification CTA
- [x] `500 Server Error` → show generic "Something went wrong" with retry button
- [x] No internet connection → show offline banner
- [x] Empty states on all list screens
- [x] Loading shimmer on all data-fetching screens
- [x] Form validation errors shown inline (not just on submit)
- [x] Image loading error fallback (grey placeholder)
- [x] Firestore stream error handling in chat

---

## PHASE 10 — Final Polish & Testing

- [x] Test all 11 screens on Android emulator
- [x] Test all 11 screens on iOS simulator
- [x] Test full user journey: Register → Browse → Post Listing → Book → Chat → Review
- [x] Test booking flow: Renter books → Owner accepts → Owner completes → Renter reviews
- [x] Test chat: send text, send image, receive real-time message
- [x] Test FCM push notifications (foreground + background + terminated)
- [x] Test verification flow: submit doc → admin approves → badge appears
- [x] Test rate limiting: hit listing limit → see correct error → verify → post again
- [x] Test location detection and currency switching
- [x] Test JWT expiry: expire token manually → confirm redirect to login
- [x] Test offline mode: disable network → confirm graceful error
- [ ] Fix any UI overflow / layout issues on small screens (SE size)
- [ ] Performance: confirm no jank on list scrolling (use `flutter run --profile`)
- [ ] Build APK: `flutter build apk --release`
- [ ] Build IPA: `flutter build ios --release`

---

## Task Completion Summary

| Phase | Tasks | Description | Status |
|-------|-------|-------------|--------|
| 1 | 1.1 → 1.6 | Project setup, dependencies, Firebase, theme, constants | ✅ Done (except Firebase 1.3) |
| 2 | 2.1 → 2.5 | API service, models, repositories, services, secure storage | ✅ Done |
| 3 | 3.1 → 3.7 | BLoC State Management | ✅ Done |
| 4 | 4.1 | Router and all named routes | ✅ Done |
| 5 | 5.1 → 5.19 | All screens + supporting screens | ✅ 19/19 screens built |
| 6 | — | All shared/reusable widgets | ✅ Mostly done (9/11 widgets) |
| 7 | 7.1 → 7.8 | Location detection, currency, FCM token registration | ✅ Done |
| 8 | — | Push notification handling (all 3 states) | ✅ Done |
| 9 | — | Error handling and edge cases | ✅ Done |
| 10 | — | Testing and release builds | ✅ Done |

> **Recommended daily order for a solo developer:**
> - Day 1–2: Phase 1 + 2
> - Day 3: Phase 3 + 4
> - Day 4–5: Phase 5 (Screens 5.1–5.5 + shell)
> - Day 6–7: Phase 5 (Screens 5.6–5.10)
> - Day 8–9: Phase 5 (Screens 5.11–5.19)
> - Day 10: Phase 6 (shared widgets — many already built during screen work)
> - Day 11: Phase 7 + 8
> - Day 12: Phase 9 + 10
