
class ApiConstants {
  static String get baseUrl {
    // Production Vercel Backend
    return 'https://renthubindia-production-b4bd.up.railway.app';
    
    // Local Development Backend
    /*
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://192.168.56.1:5000';
    return 'http://localhost:5000';
    */
  }

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String firebaseLogin = '/api/auth/firebase-login';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resetPassword = '/api/auth/reset-password';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  
  // Cities
  static const String activeCities = '/api/cities/active';

  // Users
  static const String userProfile = '/api/users/profile';
  static const String userAvatar = '/api/users/avatar';
  static const String fcmToken = '/api/users/fcm-token';
  static const String updateFcmToken = '/api/users/fcm-token';
  static const String verifyIdentity = '/api/users/me/verify';
  static String userDetail(String id) => '/api/users/$id';

  // Categories
  static const String categories = '/api/categories';

  // Listings
  static const String listings = '/api/listings';
  static String listingDetail(String id) => '/api/listings/$id';
  static String listingImages(String id) => '/api/listings/$id/images';
  static String listingStatus(String id) => '/api/listings/$id/status';
  static const String myListings = '/api/listings/my/listings';

  // Bookings
  static const String bookings = '/api/bookings';
  static const String myBookings = '/api/bookings/my';
  static const String incomingBookings = '/api/bookings/incoming';
  static String acceptBooking(String id) => '/api/bookings/$id/accept';
  static String cancelBooking(String id) => '/api/bookings/$id/cancel';
  static String completeBooking(String id) => '/api/bookings/$id/complete';

  // Reviews
  static const String reviews = '/api/reviews';
  static String listingReviews(String id) => '/api/reviews/listing/$id';
  static String userReviews(String id) => '/api/reviews/user/$id';

  // Support
  static const String tickets = '/api/support/tickets';
  static String ticketDetail(String id) => '/api/support/tickets/$id';

  // Reports
  static const String reports = '/api/reports';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String readAllNotifications = '/api/notifications/read-all';
  static String readNotification(String id) => '/api/notifications/$id/read';
}
