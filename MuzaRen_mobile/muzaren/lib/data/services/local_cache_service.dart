import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/listing_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/booking_model.dart';
import '../../core/utils/logger.dart';

/// Hive-backed local cache for listings, conversations, and messages.
///
/// All data is stored as JSON strings in three separate boxes.
/// No TypeAdapters needed — all models implement toJson/fromJson.
class LocalCacheService {
  static const _listingsBox = 'listings_cache';
  static const _convsBox = 'conversations_cache';
  static const _messagesBox = 'messages_cache';
  static const _bookingsBox = 'bookings_cache';
  static const _categoriesBox = 'categories_cache';
  static const _miscBox = 'misc_cache';

  // TTL for listings only (prices/status can change)
  static const _listingsTtl = Duration(minutes: 30);

  // Internal key suffixes
  static const _ttlSuffix = '__ttl';

  // ─── HIVE INITIALISATION ────────────────────────────────────
  /// Call once in main() before runApp().
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_listingsBox);
    await Hive.openBox(_convsBox);
    await Hive.openBox(_messagesBox);
    await Hive.openBox(_bookingsBox);
    await Hive.openBox(_categoriesBox);
    await Hive.openBox(_miscBox);
    AppLogger.success('📦 LocalCacheService: Hive boxes opened');
  }

  /// Wipe ALL cached data. Must be called on logout to prevent
  /// user A's data from being visible after user B logs in.
  static Future<void> clearAll() async {
    try {
      await Hive.box(_listingsBox).clear();
      await Hive.box(_convsBox).clear();
      await Hive.box(_messagesBox).clear();
      await Hive.box(_bookingsBox).clear();
      await Hive.box(_categoriesBox).clear();
      await Hive.box(_miscBox).clear();
      AppLogger.success('📦 LocalCacheService: All caches cleared on logout');
    } catch (e) {
      AppLogger.error('📦 clearAll error', e);
    }
  }


  // ─── LISTINGS ───────────────────────────────────────────────

  /// Build a deterministic cache key from optional filter params.
  static String listingsCacheKey({
    String? country,
    String? city,
    String? categorySlug,
    String? search,
    double? priceMin,
    double? priceMax,
    String? sortBy,
  }) {
    final parts = [
      country ?? '_',
      city ?? '_',
      categorySlug ?? '_',
      search ?? '_',
      priceMin?.toString() ?? '_',
      priceMax?.toString() ?? '_',
      sortBy ?? '_',
    ];
    return 'listings_${parts.join('_')}';
  }

  Future<List<ListingModel>?> getCachedListings(String cacheKey) async {
    try {
      final box = Hive.box(_listingsBox);
      // Check TTL
      final ttl = box.get('$cacheKey$_ttlSuffix') as int?;
      if (ttl != null) {
        final savedAt = DateTime.fromMillisecondsSinceEpoch(ttl);
        if (DateTime.now().difference(savedAt) > _listingsTtl) {
          AppLogger.info('📦 Listings cache EXPIRED for $cacheKey');
          return null; // stale
        }
      }
      final raw = box.get(cacheKey) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final listings = decoded
          .map((e) => ListingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      AppLogger.info('📦 Listings cache HIT for $cacheKey (${listings.length} items)');
      return listings;
    } catch (e) {
      AppLogger.error('📦 getCachedListings error', e);
      return null;
    }
  }

  Future<void> saveListings(String cacheKey, List<ListingModel> listings) async {
    try {
      final box = Hive.box(_listingsBox);
      final encoded = jsonEncode(listings.map((l) => l.toJson()).toList());
      await box.put(cacheKey, encoded);
      await box.put('$cacheKey$_ttlSuffix', DateTime.now().millisecondsSinceEpoch);
      AppLogger.info('📦 Listings cache SAVED for $cacheKey (${listings.length} items)');
    } catch (e) {
      AppLogger.error('📦 saveListings error', e);
    }
  }

  Future<ListingModel?> getCachedListingDetail(String id) async {
    try {
      final box = Hive.box(_listingsBox);
      final raw = box.get('detail_$id') as String?;
      if (raw == null) return null;
      return ListingModel.fromJson(jsonDecode(raw));
    } catch (e) {
      AppLogger.error('📦 getCachedListingDetail error', e);
      return null;
    }
  }

  Future<void> saveListingDetail(ListingModel listing) async {
    try {
      final box = Hive.box(_listingsBox);
      await box.put('detail_${listing.id}', jsonEncode(listing.toJson()));
      AppLogger.info('📦 Listing detail SAVED for ${listing.id}');
    } catch (e) {
      AppLogger.error('📦 saveListingDetail error', e);
    }
  }

  // ─── CONVERSATIONS ──────────────────────────────────────────

  static const _convsKey = 'conversations';

  Future<List<ConversationModel>?> getCachedConversations() async {
    try {
      final box = Hive.box(_convsBox);
      final raw = box.get(_convsKey) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final convs = decoded
          .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      AppLogger.info('📦 Conversations cache HIT (${convs.length} items)');
      return convs;
    } catch (e) {
      AppLogger.error('📦 getCachedConversations error', e);
      return null;
    }
  }

  Future<void> saveConversations(List<ConversationModel> conversations) async {
    try {
      final box = Hive.box(_convsBox);
      final encoded = jsonEncode(conversations.map((c) => c.toJson()).toList());
      await box.put(_convsKey, encoded);
      AppLogger.info('📦 Conversations cache SAVED (${conversations.length} items)');
    } catch (e) {
      AppLogger.error('📦 saveConversations error', e);
    }
  }

  // ─── MESSAGES ───────────────────────────────────────────────

  Future<List<MessageModel>?> getCachedMessages(String chatId) async {
    try {
      final box = Hive.box(_messagesBox);
      final raw = box.get(chatId) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final messages = decoded
          .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      AppLogger.info('📦 Messages cache HIT for $chatId (${messages.length} messages)');
      return messages;
    } catch (e) {
      AppLogger.error('📦 getCachedMessages error', e);
      return null;
    }
  }

  Future<void> saveMessages(String chatId, List<MessageModel> messages) async {
    try {
      final box = Hive.box(_messagesBox);
      final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
      await box.put(chatId, encoded);
      AppLogger.info('📦 Messages cache SAVED for $chatId (${messages.length} messages)');
    } catch (e) {
      AppLogger.error('📦 saveMessages error', e);
    }
  }

  // ─── BOOKINGS ───────────────────────────────────────────────

  static const _myBookingsKey = 'my_bookings';
  static const _incomingBookingsKey = 'incoming_bookings';

  Future<List<BookingModel>?> getCachedMyBookings() async {
    try {
      final box = Hive.box(_bookingsBox);
      final raw = box.get(_myBookingsKey) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final bookings = decoded
          .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      AppLogger.info('📦 MyBookings cache HIT (${bookings.length} items)');
      return bookings;
    } catch (e) {
      AppLogger.error('📦 getCachedMyBookings error', e);
      return null;
    }
  }

  Future<void> saveMyBookings(List<BookingModel> bookings) async {
    try {
      final box = Hive.box(_bookingsBox);
      final encoded = jsonEncode(bookings.map((b) => b.toJson()).toList());
      await box.put(_myBookingsKey, encoded);
      AppLogger.info('📦 MyBookings cache SAVED (${bookings.length} items)');
    } catch (e) {
      AppLogger.error('📦 saveMyBookings error', e);
    }
  }

  Future<List<BookingModel>?> getCachedIncomingBookings() async {
    try {
      final box = Hive.box(_bookingsBox);
      final raw = box.get(_incomingBookingsKey) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final bookings = decoded
          .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      AppLogger.info('📦 IncomingBookings cache HIT (${bookings.length} items)');
      return bookings;
    } catch (e) {
      AppLogger.error('📦 getCachedIncomingBookings error', e);
      return null;
    }
  }

  Future<void> saveIncomingBookings(List<BookingModel> bookings) async {
    try {
      final box = Hive.box(_bookingsBox);
      final encoded = jsonEncode(bookings.map((b) => b.toJson()).toList());
      await box.put(_incomingBookingsKey, encoded);
      AppLogger.info('📦 IncomingBookings cache SAVED (${bookings.length} items)');
    } catch (e) {
      AppLogger.error('📦 saveIncomingBookings error', e);
    }
  }
  // ─── CATEGORIES ─────────────────────────────────────────────

  static const _categoriesKey = 'all_categories';

  Future<dynamic> getCachedCategories() async {
    try {
      final box = Hive.box(_categoriesBox);
      final raw = box.get(_categoriesKey) as String?;
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (e) {
      AppLogger.error('📦 getCachedCategories error', e);
      return null;
    }
  }

  Future<void> saveCategories(dynamic data) async {
    try {
      final box = Hive.box(_categoriesBox);
      await box.put(_categoriesKey, jsonEncode(data));
      AppLogger.info('📦 Categories cache SAVED');
    } catch (e) {
      AppLogger.error('📦 saveCategories error', e);
    }
  }

  // ─── GENERIC MISC CACHE ──────────────────────────────────────

  Future<dynamic> getFromMisc(String key) async {
    try {
      final box = Hive.box(_miscBox);
      final raw = box.get(key) as String?;
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (e) {
      AppLogger.error('📦 getFromMisc error', e);
      return null;
    }
  }

  Future<void> saveToMisc(String key, dynamic data) async {
    try {
      final box = Hive.box(_miscBox);
      await box.put(key, jsonEncode(data));
    } catch (e) {
      AppLogger.error('📦 saveToMisc error', e);
    }
  }
}
