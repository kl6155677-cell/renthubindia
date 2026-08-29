import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/review_model.dart';
import 'package:dio/dio.dart';

class ReviewRepository {
  final Dio _dio = ApiService.dio;

  Future<List<ReviewModel>> getListingReviews(String listingId) async {
    final response = await _dio.get(ApiConstants.listingReviews(listingId));
    final data = response.data['data'];
    if (data is Map && data.containsKey('reviews')) {
      final List<dynamic> reviewsList = data['reviews'] ?? [];
      return reviewsList.map((json) => ReviewModel.fromJson(json)).toList();
    }
    final List<dynamic> list = data is List ? data : [];
    return list.map((json) => ReviewModel.fromJson(json)).toList();
  }

  Future<ReviewModel> createReview(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.reviews, data: data);
    return ReviewModel.fromJson(response.data['data']);
  }
}
