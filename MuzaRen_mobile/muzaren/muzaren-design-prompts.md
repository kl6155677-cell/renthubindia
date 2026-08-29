# RentHubIndia — AI Agent Design Prompts
> This file contains the exact prompts to give to your AI coding agent to build each screen pixel-perfect from the design images. Follow the order strictly. One screen at a time.

---

## How to Use This File

1. First send the **Initialization Prompt** (Section 1) — wait for confirmation
2. Then work through **Phases 1–4** from the tasks file (setup, data layer, BLoCs, router) — no screens yet
3. Once Phases 1–4 are complete, come back here and start **Section 2** (screens) in order
4. For each screen: copy the prompt → attach the correct image → send
5. Wait for the AI to finish and confirm before moving to the next screen
6. Never skip ahead — every screen depends on the previous one being done

---

## SECTION 1 — Initialization Prompt
> Send this ONCE at the very beginning before any code is written.
> Replace the two placeholder blocks with the full content of each MD file.

```
You are a senior Flutter developer working on a mobile app called RentHubIndia.

RentHubIndia is a rental-only marketplace app (no buying/selling) for iOS and 
Android. Before writing any code, you must fully read and understand the 
two documents I will give you.

---

DOCUMENT 1 — Flutter App Specification (renthubindia-flutter.md):
[PASTE FULL CONTENT OF renthubindia-flutter.md HERE]

---

DOCUMENT 2 — Build Task List (renthubindia-flutter-tasks.md):
[PASTE FULL CONTENT OF renthubindia-flutter-tasks.md HERE]

---

Now that you have read both documents, here are your rules:

RULES YOU MUST FOLLOW AT ALL TIMES:

1. TECH STACK — Never suggest or use any package not listed in the spec.
   The stack is final: flutter_bloc, go_router, dio, flutter_secure_storage,
   image_picker, google_maps_flutter, geolocator, cloud_firestore,
   firebase_messaging, hive, cached_network_image, shimmer, lottie.

2. API CALLS — Every single API call must use the exact endpoint paths
   from the cheat sheet at the bottom of Document 1. Never invent or
   assume an endpoint. Base URL is http://localhost:5000.

3. AUTH — JWT only. No firebase_auth. Token is stored in
   flutter_secure_storage. Every protected request must include
   Authorization: Bearer <token> header via the Dio interceptor.

4. IMAGES — Flutter never uploads to Cloudinary directly. Images are
   sent as multipart to the backend which handles Cloudinary. Image URLs
   from the API are Cloudinary CDN URLs — use cached_network_image to
   display them.

5. CHAT — Firebase Firestore is used directly for real-time chat
   (read AND write). No backend relay for messages. Flutter writes
   messages directly to Firestore. Only image uploads in chat go through
   the backend first to get a Cloudinary URL, then that URL is written
   to Firestore.

6. STATE MANAGEMENT — BLoC pattern only. No Provider, no Riverpod,
   no setState except for purely local UI state (like a toggle or
   text field focus). Every feature has its own BLoC.

7. NAVIGATION — go_router only. No Navigator.push() or
   Navigator.pushNamed(). All navigation uses named routes as defined
   in app_router.dart.

8. BOOKING FLOW — The status flow is: PENDING → ACCEPTED → COMPLETED
   (or CANCELLED). There is NO "CONFIRMED" step. Never build UI around
   a confirmation step from the renter.

9. LISTING IMAGES — Images are uploaded in a SEPARATE API call after
   the listing is created. First POST /api/listings to create it and
   get the id, then POST /api/listings/:id/images as multipart.
   Maximum 5 images.

10. NOTIFICATIONS ROUTE ORDER — Always register or handle
    /api/notifications/read-all BEFORE /api/notifications/:id/read
    to avoid Express matching "read-all" as an :id parameter.

11. REPORT BODY — When submitting a report, the body must use a single
    "targetId" field, NOT separate "targetListingId" or "targetUserId".
    Format: { targetType, targetId, category, description }.

12. FOLDER STRUCTURE — Follow the exact folder structure in Document 1.
    Feature code goes in lib/features/, BLoCs in lib/blocs/,
    repositories in lib/data/repositories/, services in
    lib/data/services/, models in lib/data/models/.

13. DESIGN SYSTEM — The UI must be modern and premium. Not an OLX clone.
    Use ONLY these exact colors:
    - Primary:        #0D6E75
    - Accent/Price:   #F5A623
    - Background:     #F7F8FA
    - Surface/Cards:  #FFFFFF
    - Text Primary:   #111827
    - Text Secondary: #6B7280
    - Success:        #16A34A
    - Error:          #DC2626
    - Verified Badge: #1D4ED8
    - Active chip:    #0D6E75 fill + white text
    Typography: Sora or DM Sans for headings, Plus Jakarta Sans for body.

14. DESIGN REFERENCE RULE — I will give you one screen at a time as an
    image. When I give you a screen image, your job is to:
    a) Pixel-perfect replicate the layout, spacing, colors,
       and typography from the image
    b) Never guess or improvise the layout — follow the image exactly
    c) Build each screen as a complete Flutter widget with its correct
       BLoC connection and real API calls
    d) After building each screen, list exactly what you built
       and ask me to confirm before moving to the next screen

15. TASK ORDER — Always follow the phase order in Document 2.
    Never jump to a screen before the data layer and BLoCs are ready.
    Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5.

16. GLOBAL STYLE RULES — Apply these to every single screen:
    - Horizontal screen padding: 16px
    - Card border radius: 12px
    - Button border radius: 12px
    - Card shadow: BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06))
    - Never use Lorem Ipsum — use realistic placeholder text
    - Never truncate code — always show the complete file
    - Never use placeholder hex colors — always use the exact design system colors

17. NO HALLUCINATION — If you are unsure about an endpoint, a field
    name, or a behavior, ask me before writing code. Never assume or
    invent API fields, endpoints, or logic not described in the documents.

18. LOCATION-BASED FILTERING — The app detects the user's country and
    city via GPS (geolocator + geocoding packages) and filters ALL
    listing data by that location. Rules:
    a) LocationBloc is a GLOBAL bloc provided at app root
    b) NEVER call GET /api/listings without a country param unless
       the user explicitly removed the country filter
    c) Home screen shows shimmer until LocationDetected state fires
    d) All listing fetches must read country/city/lat/lng from
       LocationBloc — never hardcode any location value
    e) User can manually change their city from the Home Screen
       top bar chip — this dispatches ManualLocationChanged to
       LocationBloc which re-emits LocationDetected and triggers
       automatic re-fetch on all listening screens
    f) If location permission is denied → try IP fallback →
       if that fails → show non-blocking banner to set manually
    g) LocationBloc dispatches DetectLocation automatically after
       AuthAuthenticated state is emitted

---

Confirm you have read and understood both documents by summarizing:
1. What RentHubIndia is
2. The full tech stack
3. The 10 build phases in order
4. The 5 most important rules you will follow

After your confirmation, wait for me to tell you which task to start with.
```

---

## SECTION 2 — Screen Prompts (In Order)

> ⚠️ Only start this section after Phases 1–4 from the tasks file are fully complete.
> Attach the correct image with each prompt. Build one screen at a time.

---

### Screen 1 — Splash Screen
**Attach:** Image 1 (splash screen)
**File:** `lib/features/auth/splash_screen.dart`

```
Here is the design image for the Splash Screen.
[ATTACH IMAGE 1]

Build this screen exactly as shown in the image.
File: lib/features/auth/splash_screen.dart

What I can see in the design:
- Full screen deep teal gradient background 
  (top: #0D6E75, bottom: slightly darker #064E54)
- Subtle large circle outlines in background (very low opacity white)
- Centered app icon: dark rounded square outer card + 
  light blue (#B2EBF2) inner rounded card + 
  triangle, square, circle icons in dark teal arranged inside
- "RentHubIndia" wordmark below icon in white, heavy bold weight, large
- "Rent Anything. Anywhere." subtitle below in white 
  with ~60% opacity, medium weight

Logic to implement:
- On init: check flutter_secure_storage for saved JWT token
- If token exists → validate with GET /api/users/profile
  - If valid → navigate to /home
  - If invalid (401) → clear token → navigate to /login
- If no token → navigate to /login after 2 second delay
- Show logo animation: scale from 0.8 to 1.0 + fade in (600ms)

Important rules for this screen:
- Do not use any placeholder colors — use exact hex codes above
- Gradient must go from top to bottom
- Circle decorations are subtle — do not make them too visible
- Font weight for "RentHubIndia" must be FontWeight.w800 or w900
- Show me the complete file — no truncation
```

---

### Screen 2 — Login Screen
**Attach:** Image 7 (login screen)
**File:** `lib/features/auth/login_screen.dart`

```
Here is the design image for the Login Screen.
[ATTACH IMAGE 7]

Build this screen exactly as shown in the image.
File: lib/features/auth/login_screen.dart

What I can see in the design:
- Light background (#F7F8FA)
- "RentHubIndia" logo text centered at top in #0D6E75, medium size
- "Welcome back" heading: large, black, heavy bold
- Subtitle: "Enter your credentials to continue your journey." 
  centered, grey (#6B7280), normal weight
- Pill-shaped tab toggle (Login | Register):
  - Outer pill: white with subtle border
  - Active tab (Login): white fill with shadow, teal text (#0D6E75)
  - Inactive tab (Register): transparent, grey text
- "EMAIL ADDRESS" field label: small caps, grey, bold
- Email input: white card, rounded (12px), 
  placeholder "hello@renthubindia.com", envelope icon on right in grey
- "PASSWORD" field label: same style as email label
- Password input: white card, rounded, dots shown, 
  eye toggle icon on right
- "Forgot Password?" right-aligned below password, teal (#0D6E75)
- "Continue" button: full width, #0D6E75 fill, white text, 
  rounded (12px), bold
- Divider: thin grey line — "or continue with" — thin grey line
- "Continue with Google" button: white card with border, 
  Google multicolor G icon left + "Continue with Google" text centered
- "Don't have an account? Sign up" at very bottom center,
  grey text + "Sign up" in teal bold

Connect to AuthBloc:
- Continue button → dispatch LoginRequested(email, password)
- Show CircularProgressIndicator inside button while AuthLoading
- Show SnackBar with error message on AuthError
- On AuthAuthenticated → navigate to /home
- "Sign up" link → navigate to /register
- "Forgot Password?" → navigate to /forgot-password
- Tab toggle: switching to Register → navigate to /register
  (or swap content inline — match exactly what the image shows)

Important rules for this screen:
- All input fields must have inline validation 
  (red border + error text below on invalid submit)
- Show me the complete file — no truncation
```

---

### Screen 3 — Register Screen
**Attach:** Image 7 (same design pattern as login, Register tab active)
**File:** `lib/features/auth/register_screen.dart`

```
Here is the design image for the Login Screen as reference.
[ATTACH IMAGE 7]

Build the Register Screen using the same design language 
but with the Register tab active in the toggle.
File: lib/features/auth/register_screen.dart

Use identical layout and style as login screen but with these fields:
- Full Name input (person icon on right)
- Email Address input (envelope icon on right)
- Phone Number input — optional (phone icon on right, 
  grey "Optional" hint)
- Password input (eye toggle)
- Confirm Password input (eye toggle)
- Button text: "Create Account" (same teal style)
- Bottom: "Already have an account? Login" 
  (grey + teal link)

Connect to AuthBloc:
- Create Account → dispatch RegisterRequested(name, email, phone, password)
- Show loading inside button while AuthLoading
- Show SnackBar on AuthError
- On AuthAuthenticated → navigate to /home
- Login link → navigate to /login

Validation rules:
- Name: required, min 2 characters
- Email: valid email format
- Phone: optional, but if filled must be valid
- Password: min 8 characters
- Confirm Password: must match password

Show me the complete file — no truncation
```

---

### Screen 4 — Forgot Password / OTP / Reset Password
**Attach:** No image — use same design language as login screen
**Files:** 3 separate files

```
No image for these screens — use the exact same design language 
as the Login Screen (same background, same card style, same button style).

Build 3 screens:

--- SCREEN A: lib/features/auth/forgot_password_screen.dart ---
- Back arrow top left
- "Forgot Password" heading bold
- Subtitle: "Enter your email and we'll send you a reset code."
- Email input field (same style as login)
- "Send Code" teal button
- On tap → POST /api/auth/forgot-password with { email }
- On success → navigate to /verify-otp passing email as param
- Show loading + error states

--- SCREEN B: lib/features/auth/verify_otp_screen.dart ---
- Back arrow top left
- "Verify Code" heading bold
- Subtitle: "Enter the 6-digit code sent to [email]"
- 6 separate single-digit input boxes in a row
  (auto-advance to next box on digit entry)
  (auto-go back on backspace)
  Active box: teal border
- "Verify" teal button
- On tap → POST /api/auth/verify-otp with { email, code }
- On success → navigate to /reset-password
- "Resend code" grey link below button
- Show loading + error states

--- SCREEN C: lib/features/auth/reset_password_screen.dart ---
- Back arrow top left  
- "New Password" heading bold
- Subtitle: "Create a strong new password for your account."
- New Password input (eye toggle)
- Confirm Password input (eye toggle)
- "Update Password" teal button
- On tap → POST /api/auth/reset-password with { email, code, newPassword }
- On success → show success SnackBar → navigate to /login
- Show loading + error states

Show me all 3 complete files — no truncation
```

---

### Screen 5 — Bottom Navigation Shell
**Attach:** Any image showing the bottom nav (Image 8 is best)
**File:** `lib/features/shell/main_shell.dart`

```
Here is the design image showing the bottom navigation bar.
[ATTACH IMAGE 8]

Build the main shell with bottom navigation.
File: lib/features/shell/main_shell.dart

What I can see in the design:
- Bottom nav bar: white background with very subtle top border
- 5 tabs: Home | Search | Post | Messages | Profile
- Active tab: icon + label both in #0D6E75 (teal)
- Inactive tab: icon + label both in #6B7280 (grey)
- "Post" center tab: 
  - Icon is a raised circular teal button (#0D6E75) 
    with white "+" icon, elevated above nav bar
  - No label below it
- Icons style: outlined/line icons (not filled) except active
- Nav bar height: standard Flutter BottomNavigationBar

Behavior:
- Home tab → /home
- Search tab → /search
- Post tab → navigate to /listing/post (does NOT stay selected)
- Messages tab → /chat (shows unread count badge from NotificationBloc)
- Profile tab → /profile
- Use ShellRoute from go_router for persistent navigation

Unread badge on Messages:
- Small red circle with white count number
- Position: top right of Messages icon
- Read from NotificationBloc unreadCount state

Show me the complete file — no truncation
```

---

### Screen 6 — Home Screen
**Attach:** Image 8 (home screen)
**File:** `lib/features/home/home_screen.dart`

```
Here is the design image for the Home Screen.
[ATTACH IMAGE 8]

Build this screen exactly as shown in the image.
File: lib/features/home/home_screen.dart

What I can see in the design:

TOP BAR:
- Teal location pin icon + "Singapore, SG" text bold + 
  small dropdown chevron — all in #0D6E75
- Right: bell icon with small red dot badge

SEARCH BAR:
- Full width, light grey (#F0F0F0) rounded pill
- Search icon left, placeholder "What do you want to rent today?"
- Tappable — does not open keyboard here, navigates to /search

BROWSE BY CATEGORY:
- Section title "Browse by Category" in #0D6E75 bold
- Horizontal scrollable chips row:
  - Active chip: #0D6E75 fill + white icon + white text + rounded pill
  - Inactive chip: white fill + grey border + grey icon + grey text
  - Examples: 📷 Electronics, 🚗 Vehicles, 🛋 Furniture, 
    🔧 Tools, 👗 Fashion

FEATURED NEAR YOU:
- "Featured Near You" in #0D6E75 bold + "See all →" teal right
- Horizontal scroll of large cards (card width ~75% of screen):
  - Full width image top (rounded top corners)
  - White bottom section
  - "VERIFIED" blue badge overlay top left of image
  - "SINGAPORE • 0.8 KM" small grey text
  - Title bold
  - Price in #F5A623 amber "/day"
  - Rounded card corners (12px), subtle shadow

NEARBY LISTINGS:
- "Nearby Listings" section title bold dark
- 2-column grid of cards:
  - Square image top (rounded top corners)
  - "⭐ 4.9 (12)" rating below image, small
  - Title (2 lines max) bold
  - Price in #F5A623 "/day"
  - City in grey small
  - Rounded card (12px), subtle shadow

LOADING STATE:
- Shimmer placeholders matching exact shape of cards
- Pull-to-refresh on entire ScrollView

API Calls:
- GET /api/categories → populate category chips
- GET /api/listings?country={locationState.country} → featured section
- GET /api/listings?country={locationState.country}&city={locationState.city}&lat={locationState.lat}&lng={locationState.lng} → nearby grid

⚠️ IMPORTANT: All listing API calls on this screen MUST read country/city/lat/lng
from LocationBloc state. Never hardcode or assume a location.
Show shimmer placeholders while LocationBloc is in LocationDetecting state.
Only fetch listings after LocationDetected state is emitted.

Navigation:
- Search bar tap → /search (passes current country as default filter)
- Category chip tap → /search?categoryId=...&country={locationState.country}
- Listing card tap → /listing/:id
- Bell icon → /notifications
- Location chip tap → open manual location change bottom sheet:
  - Pre-fill current city from LocationBloc
  - Text field + country dropdown
  - "Update Location" button → dispatch ManualLocationChanged to LocationBloc
  - On confirm → LocationBloc re-emits LocationDetected → home screen re-fetches

Show me the complete file — no truncation
```

---

### Screen 7 — Categories Screen
**Attach:** Image 10 (categories screen)
**File:** `lib/features/home/categories_screen.dart`

```
Here is the design image for the All Categories Screen.
[ATTACH IMAGE 10]

Build this screen exactly as shown in the image.
File: lib/features/home/categories_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- "All Categories" title centered bold dark
- Search icon right (grey)

BANNER CARD:
- Full width rounded card (16px radius) with teal image overlay
- Small label: "NEW ARRIVALS" in white, small caps, light weight
- Large heading: "Spring Editorial Collection" in white bold
- Background: interior room photo with teal color overlay

CATEGORY GRID:
- 3-column grid layout
- Each item (no card border — just icon + label):
  - Circular background: light grey (#F3F4F6)
  - Teal icon centered inside circle (#0D6E75)
  - Category name below in dark (#111827), small, centered
- Categories: Furniture, Lighting, Textiles, Outdoor, Kitchen,
  Art, Storage, Bedroom, Wellness, Workspace, Kids, Smart Home
- Generous spacing between items (16px gap)

API Calls:
- GET /api/categories → populate grid dynamically
- Banner can be static (hardcoded content)

Navigation:
- Back arrow → go back
- Category tap → /search?categoryId=...
- Search icon → /search

Show me the complete file — no truncation
```

---

### Screen 8 — Search Results Screen
**Attach:** Image 2 (search results screen)
**File:** `lib/features/search/results_screen.dart`

```
Here is the design image for the Search Results Screen.
[ATTACH IMAGE 2]

Build this screen exactly as shown in the image.
File: lib/features/search/results_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- Rounded search input (pre-filled: "Modern lofts in Tokyo")
  white background, grey border, search icon left
- Filter icon button right (grey square rounded)

FILTER CHIPS ROW (horizontal scroll):
- Active/applied filters: teal fill (#0D6E75) + white text + × remove
  Examples: "Tokyo ×", "Apartment ×"
- Inactive filters: white fill + grey border + dark text
  Examples: "Price Range", "Date"
- Removing a chip → removes that filter + refreshes results

RESULTS HEADER:
- "248 spaces found" left, grey small
- List/Map view toggle right: 
  two icon buttons side by side in a rounded card
  (list icon + map icon, active one has grey bg)

LISTING CARDS (list view):
- White card, rounded (12px), subtle shadow, full width
- Left: image (rounded 12px, fixed size ~120×100)
  + "VERIFIED" blue badge overlay top left
- Right content:
  - Title bold + ⭐ rating inline right (e.g. "★ 4.9")
  - Category label: small caps, teal (#0D6E75), bold
    (e.g. "LUXURY STUDIO")
  - 📍 City, Location (grey small)
  - Review count (grey small, e.g. "128 reviews")
  - Price: #F5A623 amber bold large "/day"
- Separator line between cards (or card spacing)

LOADING STATE:
- Shimmer card at bottom while loading next page
  (visible in the design image)

MAP VIEW:
- Full screen google_maps_flutter
- Teal map pins for each listing
- Bottom sheet with horizontal card scroll

API Call:
- GET /api/listings?country={locationState.country}&search=...&categoryId=...
  &minPrice=...&maxPrice=...&lat=...&lng=...&page=...
- country param always pre-filled from LocationBloc on screen open
- If user removes country chip → search globally (no country param)
- Debounced search: 500ms after user stops typing
- Infinite scroll: load next page on scroll to bottom

LOCATION FILTER CHIP (always shown as first active chip):
- Shows "🇸🇬 Singapore" or whatever user's detected country is
- Has × remove button — removing it searches globally
- Tapping it (without removing) → opens country change picker

Navigation:
- Back arrow → go back
- Listing card tap → /listing/:id
- Filter icon → show filter bottom sheet with:
  Price range slider
  Category selector
  City input (pre-filled with user city)
  Country selector (pre-filled with user country)

Show me the complete file — no truncation
```

---

### Screen 9 — Listing Detail Screen
**Attach:** Image 4 (listing detail screen)
**File:** `lib/features/listing/detail_screen.dart`

```
Here is the design image for the Listing Detail Screen.
[ATTACH IMAGE 4]

Build this screen exactly as shown in the image.
File: lib/features/listing/detail_screen.dart

What I can see in the design:

HERO IMAGE AREA:
- Full width image takes top ~40% of screen (no app bar)
- Floating back button: white circle with shadow, top left
- Floating share + bookmark buttons: white circles, top right
- Dot indicators bottom center of image (for carousel)

WHITE CONTENT CARD (overlaps image, rounded top corners 20px):
- "PHOTOGRAPHY" category chip: small, grey outlined pill, top left
- Price top right: "SGD" small grey + "25" very large teal bold + 
  "/day" small grey
- Title: "Sony Alpha A7 IV Kit" large bold dark
- 📍 location text grey small
- 📅 "Available: Oct 12 - 18" grey small

OWNER CARD (white rounded card inside content):
- Avatar circle left
- Name bold
- "VERIFIED" blue badge (pill with checkmark)
- "View Profile" teal link right
- "⭐ 4.9 (42 reviews)" below name in grey small

DESCRIPTION SECTION:
- "Description" heading bold
- Body text grey, 3 lines then cut off
- "Read more" teal inline link at end

AVAILABILITY SECTION:
- "Availability" heading bold
- Month header: "October 2023" + left/right arrows
- Calendar grid (M T W T F S S columns):
  - Available dates: teal circle background + white text
  - Unavailable/past: grey text no background
  - Today: outlined circle

REVIEWS SECTION:
- "Reviews" heading bold + "⭐ 4.9" right in amber
- Star rating bars: 5 bars (5★ longest, 4★ short, 3★ tiny)
  bar color: #0D6E75
- Review cards: avatar + name + 5 stars + comment text
- "Show all 42 reviews" full width outlined grey button
- "⚠ Report this listing" small grey centered link below button

STICKY BOTTOM BAR:
- Left: "SGD 25" bold dark + "per day total" grey small below
- Right: "Chat" outlined button (teal border + teal text) + 
  "Book Now" teal filled button
- Both buttons rounded (12px)
- Subtle top border on bar

API Calls:
- GET /api/listings/:id → all listing data
- GET /api/reviews/listing/:id?page=1&limit=10 → reviews

Navigation & Actions:
- Back → go back
- View Profile → /profile/:ownerId
- Chat button → create/get Firestore chat → /chat/:chatId
- Book Now → /booking/:listingId
- Report link → show report bottom sheet:
  Category selector (FRAUD/SPAM/ABUSE/FAKE_LISTING)
  Description text field
  Submit → POST /api/reports { targetType:"LISTING", 
  targetId: listingId, category, description }

Show me the complete file — no truncation
```

---

### Screen 10 — Post Listing Screen
**Attach:** Image 5 (post listing screen — step 2 shown)
**File:** `lib/features/listing/post_listing_screen.dart`

```
Here is the design image for the Post Listing Screen (Step 2 of 6 shown).
[ATTACH IMAGE 5]

Build this multi-step wizard screen exactly as shown.
File: lib/features/listing/post_listing_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow + "Post Item" title bold + "RentHubIndia" teal right

STEP INDICATOR (below top bar):
- "Step 2 of 6" teal bold left + step name grey right 
  (e.g. "Photos & Details")
- Progress bar below: teal filled portion + grey remainder
  (linear, full width, 4px height, rounded)

STEP 2 CONTENT SHOWN IN IMAGE:
Photos section:
- "Photos" heading bold
- Helper text grey: "Add up to 8 photos. High-quality images 
  get 3× more rentals."
  NOTE: Show this text but limit actual upload to 5 images 
  (API maximum)
- Dashed border upload zone (grey dashed, rounded 12px):
  - Camera+ icon in teal circle center
  - "Upload Photos" teal text below
  - "PNG, JPG or WebP" grey small below
- Thumbnail row below zone:
  - Uploaded images: square rounded thumbnail + 
    "×" remove button top right corner (dark circle)
  - Empty slot: light grey square with image placeholder icon

Item Title section:
- "Item Title" label bold
- Text input: white, rounded (12px), 
  placeholder "e.g. Sony WH-1000XM4 Noise Cancelli..."

Description section:
- "Description" label bold
- Multiline text input: white, rounded (12px), 
  4 lines visible height
  placeholder "Describe the item's condition, what's 
  included, and any rules for renters..."

BOTTOM BUTTONS:
- "Back" button: grey fill (#E5E7EB), dark text, rounded (12px)
- "Next" button: #0D6E75 fill, white text bold, rounded (12px)
- Both equal width, side by side with gap

ALL 6 STEPS TO BUILD:

Step 1 — Category:
- "Select a Category" heading
- Grid of category cards (from GET /api/categories)
- Each card: icon + name, tappable
- Selected: teal border + teal icon + teal text
- Unselected: grey border

Step 2 — Photos & Details (shown in image):
- Photo upload zone + thumbnails (max 5)
- Item Title input
- Description multiline input

Step 3 — Pricing:
- "Set Your Price" heading
- Large price input: currency symbol left + number input + 
  "/day" right label
- Helper: "You'll earn [X] after platform fee" grey
- If price > ₹1000 equivalent AND user is UNVERIFIED:
  Show amber warning banner:
  "⚠ Verification required for high-value items. 
  Verify your identity to continue."
  with "Verify Now" teal link

Step 4 — Location:
- "Where is the item located?" heading
- Map preview with draggable pin (google_maps_flutter)
- City text input below map
- "📍 Use my current location" teal link

Step 5 — Availability:
- "Set availability dates" heading
- Date range picker: Start date → End date
- Calendar-style or two date pickers

Step 6 — Review & Submit:
- Summary of all entered data
- Each section shown as a readable card
- "Submit Listing" teal button
- On tap:
  1. POST /api/listings with { categoryId, title, description, 
     pricePerDay, location, availableFrom, availableTo }
  2. Get listing id from response
  3. POST /api/listings/:id/images (multipart, all images)
  4. Show success screen → navigate to /my-listings
- Handle 429 rate limit: show RateLimitErrorDialog widget

TRANSITIONS:
- Slide left animation when pressing Next
- Slide right animation when pressing Back

Show me the complete file — no truncation
```

---

### Screen 11 — Booking Screen
**Attach:** Image 11 (booking/request screen)
**File:** `lib/features/booking/booking_screen.dart`

```
Here is the design image for the Booking Screen.
[ATTACH IMAGE 11]

Build this screen exactly as shown in the image.
File: lib/features/booking/booking_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- "Request Booking" title bold teal centered

LISTING SUMMARY CARD (white, rounded 12px, shadow):
- Image left: square rounded (12px), ~80px
- Right content:
  - Title bold: "Leica M6 Classic Edition"
  - "Lent by Julian S." grey small
  - "SGD 25/day" in #F5A623 amber bold

SELECT RENTAL DATES SECTION:
- "Select rental dates" heading bold dark
- Date selector card (white, rounded 12px, shadow):
  - Left: "START DATE" grey small caps + 
    "Oct 12, 2023" large teal bold
  - Center: → arrow in grey
  - Right: "END DATE" grey small caps + 
    "Oct 15, 2023" large teal bold
  - Tapping either opens a date picker

PRICE BREAKDOWN CARD (light grey bg #F3F4F6, rounded 12px):
- "3 days × SGD 25/day" left + "SGD 75" right
- "Service fee" left + "SGD 5" right
- Thin divider line
- "Total" bold left + "SGD 80" #F5A623 amber bold large right
- All values auto-calculated as dates change

MESSAGE SECTION:
- "Any message to the owner?" heading bold
- Multiline text input, white rounded (12px)
- Placeholder: "Hi Julian, I'd love to use your Leica for 
  a street photography project next weekend..."

INFO BOX (light grey bg, rounded 12px, teal border left 3px):
- ℹ️ icon left teal
- "No payment required now." bold
- "Your request will be sent to the owner for approval. 
  Once confirmed, you'll receive a link to finalize 
  the payment." grey small

BOTTOM BUTTON:
- Full width "Send Booking Request" #0D6E75 teal, 
  white bold text, rounded (12px)
- Fixed at bottom of screen

Logic:
- totalDays = endDate.difference(startDate).inDays
- subtotal = totalDays × pricePerDay
- serviceFee = 5 (fixed placeholder)
- total = subtotal + serviceFee
- On Send: POST /api/bookings { listingId, startDate, endDate }
- On success: show success SnackBar + go back to listing detail
- Show loading inside button while submitting
- Disable button if no dates selected

Show me the complete file — no truncation
```

---

### Screen 12 — Notifications Screen
**Attach:** Image 6 (notifications screen)
**File:** `lib/features/notifications/notifications_screen.dart`

```
Here is the design image for the Notifications Screen.
[ATTACH IMAGE 6]

Build this screen exactly as shown in the image.
File: lib/features/notifications/notifications_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- "Notifications" title bold teal
- "Mark all read" right, teal, smaller weight

SECTION LABELS:
- "TODAY", "YESTERDAY", "EARLIER" 
- Small, grey, letter-spaced, all caps
- No background — just text with spacing above

UNREAD NOTIFICATION CARDS (TODAY section):
- White card, rounded (12px), subtle shadow
- Left side: thick teal vertical bar (3px, full card height, rounded)
- Icon circle: light teal background (#E0F2F1) + 
  teal icon inside (calendar, chat, shield, money, star)
- Title: bold dark
- Body: grey, 2 lines
- Timestamp: grey small, top right

READ NOTIFICATION CARDS (YESTERDAY, EARLIER):
- Same layout BUT no left teal bar
- Slightly grey background (#F9FAFB) instead of pure white

ICON TYPES (match icon to notification type):
- booking_update → calendar icon
- new_message → chat bubble icon
- system/security → shield icon
- payment → money/wallet icon
- rewards → star icon

API Calls:
- GET /api/notifications → load all notifications
- Group by date: today, yesterday, earlier (use createdAt field)
- PATCH /api/notifications/read-all → "Mark all read" button
- PATCH /api/notifications/:id/read → on single tap

Navigation on tap (based on notification type field):
- booking_update → /my-listings
- new_message → /chat/:chatId (from notification data)
- system → stay on notifications
- payment → /my-listings

Empty state:
- Centered illustration + "No notifications yet" + 
  "You're all caught up!" grey sub text

Show me the complete file — no truncation
```

---

### Screen 13 — Chat Thread Screen
**Attach:** Image 9 (chat thread screen)
**File:** `lib/features/chat/chat_thread_screen.dart`

```
Here is the design image for the Chat Thread Screen.
[ATTACH IMAGE 9]

Build this screen exactly as shown in the image.
File: lib/features/chat/chat_thread_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- Avatar circle (with small green online dot bottom right)
- Name "Elena Rossi" bold dark
- Listing chip: "MID-CENTURY LOFT >" teal outlined pill 
  (tappable → /listing/:id)
- 3-dot menu icon right

LISTING CONTEXT CARD (white, rounded 12px, shadow):
- Image left (square rounded)
- Title bold: "Mid-Century Modern Loft"
- Price: "$145 / night" in #F5A623 amber
- "View Listing" blue (#1D4ED8) link text
- Heart icon right (grey outline)

DATE SEPARATOR:
- "TODAY" centered, grey small caps, 
  thin grey lines either side

RECEIVED MESSAGE BUBBLES (from other person):
- Left-aligned
- White background, rounded (16px, 
  bottom-left corner less rounded: 4px)
- Dark text (#111827)
- Timestamp below left, grey small

SENT MESSAGE BUBBLES (from current user):
- Right-aligned  
- #0D6E75 teal background, rounded (16px, 
  bottom-right corner less rounded: 4px)
- White text
- Timestamp below right, grey small
- Double tick: grey (✓✓) sent, teal (✓✓) read

BOTTOM INPUT BAR (white, shadow top):
- Image attach button: grey rounded square, 
  image+ icon inside
- Text input: grey rounded pill, 
  "Type your message..." placeholder, expands multiline
- Send button: #0D6E75 teal rounded square, 
  white arrow/send icon

Firestore Integration:
- Stream: firestore.collection('chats')
  .doc(chatId).collection('messages')
  .orderBy('createdAt').snapshots()
- Send text: direct Firestore write:
  { senderId, text, imageUrl: null, createdAt: now, read: false }
- Send image: 
  1. Pick image via image_picker
  2. POST to backend (multipart) → get Cloudinary URL
  3. Write to Firestore: { senderId, text: null, imageUrl, createdAt, read: false }
- Mark read: update all messages where senderId != currentUserId 
  and read == false → set read: true

Auto-scroll: scroll to bottom on new message
Image messages: show rounded image preview in bubble (tappable to expand)

Show me the complete file — no truncation
```

---

### Screen 14 — Profile Screen
**Attach:** Image 3 (profile screen)
**File:** `lib/features/profile/profile_screen.dart`

```
Here is the design image for the Profile Screen.
[ATTACH IMAGE 3]

Build this screen exactly as shown in the image.
File: lib/features/profile/profile_screen.dart

What I can see in the design:

TOP BAR:
- Back arrow left (teal)
- "RentHubIndia" title centered bold dark
- Settings gear icon right (grey)

BANNER + AVATAR:
- Teal-to-blue gradient banner (~130px height)
- Avatar: white-bordered square card (rounded 16px, ~90px) 
  positioned overlapping banner bottom left
- Small blue verified badge: circle bottom-right of avatar
- User illustration/photo inside avatar

USER INFO (below avatar, left-aligned):
- Name: "Marcus Richardson" large bold dark
- 📍 "San Francisco, CA" grey small

STATS ROW (3 equal white cards side by side, rounded 12px, shadow):
- "12" bold large dark + "LISTINGS" grey small caps below
- "34" bold large dark + "RENTALS" grey small caps below
- "4.8 ★" bold large (star in #F5A623) + "RATING" grey small caps

MY LISTINGS SECTION:
- "My Listings" bold dark + "View All" teal right link
- Tab row: "Active" (teal pill active) | "Paused" | "Expired"
  Active: #0D6E75 fill white text
  Inactive: grey text no fill
- Listing cards (vertical list):
  - Image left (square rounded 8px, ~70px)
  - Right content:
    - Status badge top: "ACTIVE" green (#16A34A light bg) OR 
      "PAUSED" amber (#F5A623 light bg) — small pill
    - Pencil + pause/play icons top right of card
    - Title bold (2 lines max)
    - "🗓 3 pending requests" amber small
    - Price amber bold
  - Delete icon: red trash on paused items

ACCOUNT SETTINGS SECTION:
- "Account Settings" heading bold dark
- Setting rows (white rounded cards, shadow):
  Each row: icon (colored rounded square) + label + arrow right
  - Edit Profile: person icon, teal square bg
  - Identity Verification: shield icon, teal square bg
    Sub-label: "Verified ✓" grey small (or "Not verified")
  - Support Center: ? icon, blue square bg
- Logout row: 
  Red arrow/door icon + "Logout" red text + NO arrow

FLOATING BUTTON:
- "＋ Add New Listing" pill button, #0D6E75 fill, white text
- Positioned bottom right (floating above nav bar)

API Calls:
- GET /api/users/profile → user data + stats
- GET /api/listings/my/listings → my listings list
- GET /api/bookings/incoming → pending count per listing

Actions:
- Edit Profile → navigate to edit profile screen
- Identity Verification → /verification
- Support Center → /support
- Logout → POST /api/auth/logout → clear token → /login
- "View All" → /my-listings
- Add New Listing → /listing/post
- Listing card tap → /listing/:id
- Pencil icon → edit listing
- Pause/Play → PATCH /api/listings/:id/status
- Tab switch → filter listings by status client-side

Show me the complete file — no truncation
```

---

## SECTION 3 — Remaining Screens
> These screens have no design images. Build them using the same design language as all previous screens.

---

### Screen 15 — Messages List Screen
**File:** `lib/features/chat/messages_list_screen.dart`

```
No design image for this screen.
Use the same design language as all other screens.
File: lib/features/chat/messages_list_screen.dart

Build a WhatsApp/iMessage-style conversation list screen:

TOP BAR:
- "Messages" title bold dark (no back arrow — this is a tab)
- Search icon right (teal)

SEARCH BAR (below top bar):
- Grey rounded pill, "Search conversations..."
- Filters conversation list locally on type

CONVERSATION LIST:
- Each row (white bg, subtle bottom divider):
  - Avatar circle left (with green dot if online)
  - Middle: Name bold + listing context "Re: Sony Camera" grey small
  - Last message preview: grey small, 1 line truncated
  - Right: timestamp grey small + unread count badge (teal circle white number)
- Unread conversations: name in bold, slightly darker bg (#F9FAFB)
- Read conversations: name normal weight, white bg

EMPTY STATE:
- Centered camera/chat illustration
- "No messages yet" bold
- "Start a conversation from any listing" grey small

Firestore Integration:
- Stream: firestore.collection('chats')
  .where('renterId', isEqualTo: userId)
  OR .where('ownerId', isEqualTo: userId)
  .orderBy('updatedAt', descending: true).snapshots()

Navigation:
- Tap conversation → /chat/:chatId

Show me the complete file — no truncation
```

---

### Screen 16 — My Listings Screen
**File:** `lib/features/profile/my_listings_screen.dart`

```
No design image — use same design language as Profile Screen.
File: lib/features/profile/my_listings_screen.dart

TOP BAR:
- Back arrow + "My Listings" title bold

TAB BAR:
- Active | Paused | Expired (same pill tab style as profile screen)

LISTING CARDS (same style as in profile screen but full width):
- Image left + status badge + action icons + title + pending count + price
- Additional: "X incoming booking requests" shown if count > 0
- Swipe to delete OR trash icon to delete (with confirmation dialog)

EMPTY STATE per tab:
- Active: "No active listings. Post your first item!"
- Paused: "No paused listings."
- Expired: "No expired listings."

FAB:
- "＋ Add New Listing" bottom right floating teal pill button

API Calls:
- GET /api/listings/my/listings → all my listings
- Filter client-side by status for each tab
- PATCH /api/listings/:id/status → pause/activate

Show me the complete file — no truncation
```

---

### Screen 17 — My Bookings Screen
**File:** `lib/features/booking/my_bookings_screen.dart`

```
No design image — use same design language as all screens.
File: lib/features/booking/my_bookings_screen.dart

TOP BAR:
- Back arrow + "My Bookings" title bold

TAB BAR:
- "As Renter" | "As Owner" pill tabs

AS RENTER TAB:
- GET /api/bookings/my → list of outgoing bookings
- Each booking card (white, rounded 12px, shadow):
  - Listing image left (square rounded)
  - Title + owner name grey
  - Date range: "Oct 12 → Oct 15"
  - Total price amber bold
  - Status badge (see below)
  - Cancel button (if PENDING or ACCEPTED)
  - "Leave Review" teal button (if COMPLETED, no review yet)

AS OWNER TAB:
- GET /api/bookings/incoming → incoming booking requests
- Each card same style +
  - Renter name + avatar
  - "Accept" teal button + "Cancel" outlined button (if PENDING)
  - "Mark Complete" teal button (if ACCEPTED)

STATUS BADGES:
- PENDING: amber (#F5A623) light bg + dark amber text
- ACCEPTED: teal (#0D6E75) light bg + teal text
- COMPLETED: grey light bg + grey text
- CANCELLED: red (#DC2626) light bg + red text

API Actions:
- PATCH /api/bookings/:id/accept
- PATCH /api/bookings/:id/cancel
- PATCH /api/bookings/:id/complete

Show me the complete file — no truncation
```

---

### Screen 18 — Verification Screen
**File:** `lib/features/profile/verification_screen.dart`

```
No design image — use same design language as all screens.
File: lib/features/profile/verification_screen.dart

TOP BAR:
- Back arrow + "Identity Verification" title bold

CURRENT STATUS BANNER:
- If UNVERIFIED: amber banner "Your account is not verified"
- If PENDING: blue banner "Under review — we'll notify you soon"
- If VERIFIED: green banner "✓ Your identity is verified"

CONTENT (if UNVERIFIED or showing form):
- Explanation text: why verification is needed
- "Select document type" section:
  Selectable chips: Aadhaar | Passport | National ID
- "Upload Document" dashed upload zone (same style as post listing)
- Image preview if document selected
- "Submit for Verification" teal button
- On tap → POST /api/users/me/verify (multipart, key: "document")
- Show loading + success/error states

Show me the complete file — no truncation
```

---

### Screen 19 — Support Screen
**File:** `lib/features/support/support_screen.dart`

```
No design image — use same design language as all screens.
File: lib/features/support/support_screen.dart

TOP BAR:
- Back arrow + "Support Center" title bold

FAQ SECTION:
- "Frequently Asked Questions" heading bold
- Accordion list of 5-6 common questions (static, hardcoded):
  - "How do I post a listing?"
  - "How does verification work?"
  - "What if an item is damaged?"
  - "How do I cancel a booking?"
  - "How do I report a user?"
- Tap to expand/collapse answer
- Teal chevron arrow rotates on expand

MY TICKETS SECTION:
- "My Support Tickets" heading + "New Ticket" teal right link
- GET /api/support/tickets → ticket list
- Each ticket card (white rounded 12px shadow):
  - Subject bold
  - Status badge: OPEN (amber) IN_PROGRESS (blue) 
    RESOLVED (green) CLOSED (grey)
  - Date grey small
  - Tap → show ticket detail bottom sheet:
    - Full message
    - Admin reply (if adminReply field not null)

NEW TICKET SCREEN:
- Navigate to /support/new
- Subject input
- Message multiline input
- "Submit" teal button
- POST /api/support/tickets

EMPTY STATE:
- "No tickets yet" + "We're here to help!" grey sub

Show me the complete file — no truncation
```

---

## SECTION 4 — After Every Screen

After each screen is built, send this quality check prompt:

```
Before we move to the next screen, confirm:

1. Does the screen use ONLY the design system colors 
   (no hardcoded colors outside the palette)?
2. Are all API calls using the exact endpoints from 
   the cheat sheet in the flutter MD file?
3. Is the BLoC properly connected with correct events and states?
4. Does it handle loading state (shimmer or indicator)?
5. Does it handle error state (snackbar or error widget)?
6. Does it handle empty state (illustration + text)?
7. Is navigation using go_router named routes only 
   (no Navigator.push)?
8. Is the full file shown with no truncation?

If any answer is NO — fix it before we proceed.
```

---

## SECTION 5 — Final Integration Check

After all screens are built, send this final prompt:

```
All screens are built. Now do a final integration check:

1. Run through the complete user journey mentally:
   Splash → Login → Home → Search → Listing Detail → 
   Book → Notifications → Chat → Profile → Post Listing

2. Check every screen has correct BLoC events 
   wired to the right buttons

3. Check the bottom navigation shell correctly 
   highlights the active tab on each screen

4. Check all Firestore chat operations work:
   - Create chat on first message
   - Send text message
   - Send image (via backend → Cloudinary URL → Firestore)
   - Real-time stream updates

5. Check FCM token is registered after login:
   POST /api/users/fcm-token

6. Check location is detected on app start and 
   PUT /api/users/profile is called with city/country

7. Verify the 429 rate limit error is handled 
   on POST /api/listings with a proper dialog

8. List any issues found and fix them one by one.
```
