import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/booking_model.dart';
import '../services/local_cache_service.dart';
import 'package:dio/dio.dart';

class BookingRepository {
  final Dio _dio = ApiService.dio;
  final LocalCacheService _cache = LocalCacheService();

  Future<List<BookingModel>> getMyBookings() async {
    // 1. Try Cache
    final cached = await _cache.getCachedMyBookings();
    if (cached != null) return cached;

    final response = await _dio.get(ApiConstants.myBookings);
    final List<dynamic> data = response.data['data'] ?? [];
    final bookings = data.map((json) => BookingModel.fromJson(json)).toList();

    // 2. Save Cache
    await _cache.saveMyBookings(bookings);

    return bookings;
  }

  Future<List<BookingModel>> getIncomingBookings() async {
    // 1. Try Cache
    final cached = await _cache.getCachedIncomingBookings();
    if (cached != null) return cached;

    final response = await _dio.get(ApiConstants.incomingBookings);
    final List<dynamic> data = response.data['data'] ?? [];
    final bookings = data.map((json) => BookingModel.fromJson(json)).toList();

    // 2. Save Cache
    await _cache.saveIncomingBookings(bookings);

    return bookings;
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.bookings, data: data);
    return BookingModel.fromJson(response.data['data']);
  }

  Future<BookingModel> acceptBooking(String id) async {
    final response = await _dio.patch(ApiConstants.acceptBooking(id));
    return BookingModel.fromJson(response.data['data']);
  }

  Future<BookingModel> cancelBooking(String id) async {
    final response = await _dio.patch(ApiConstants.cancelBooking(id));
    return BookingModel.fromJson(response.data['data']);
  }

  Future<BookingModel> completeBooking(String id) async {
    final response = await _dio.patch(ApiConstants.completeBooking(id));
    return BookingModel.fromJson(response.data['data']);
  }

  Future<void> submitReview(String bookingId, int rating, String? comment) async {
    await _dio.post(ApiConstants.reviews, data: {
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
    });
  }
}
