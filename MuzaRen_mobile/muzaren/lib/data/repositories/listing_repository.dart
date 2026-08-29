import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/listing_model.dart';
import '../services/local_cache_service.dart';
import 'package:dio/dio.dart';

class ListingRepository {
  final Dio _dio = ApiService.dio;
  final LocalCacheService _cache = LocalCacheService();

  Future<List<ListingModel>> getListings({
    int page = 1,
    int limit = 10,
    String? categorySlug,
    String? search,
    String? country,
    String? city,
    String? userId,
    double? priceMin,
    double? priceMax,
    String? sortBy,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (categorySlug != null) queryParams['category'] = categorySlug;
    if (search != null) queryParams['search'] = search;
    if (country != null && country.isNotEmpty) queryParams['country'] = country;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (priceMin != null) queryParams['priceMin'] = priceMin;
    if (priceMax != null) queryParams['priceMax'] = priceMax;
    if (sortBy != null) queryParams['sortBy'] = sortBy;

    // ─── CACHE LOGIC ───
    final cacheKey = LocalCacheService.listingsCacheKey(
      country: country,
      city: city,
      categorySlug: categorySlug,
      search: search,
      priceMin: priceMin,
      priceMax: priceMax,
      sortBy: sortBy,
    );
    
    // Only use cache for first page (to avoid complex pagination caching)
    if (page == 1) {
      final cached = await _cache.getCachedListings(cacheKey);
      if (cached != null) return cached;
    }

    final response = await _dio.get(ApiConstants.listings, queryParameters: queryParams);
    final rawData = response.data['data'];
    final List<dynamic> listingsJson = rawData is List 
        ? rawData 
        : (rawData is Map ? rawData['listings'] : []) ?? [];
    
    final listings = listingsJson.map((json) => ListingModel.fromJson(json)).toList();

    // Save to cache if first page
    if (page == 1 && listings.isNotEmpty) {
      await _cache.saveListings(cacheKey, listings);
    }

    return listings;
  }

  Future<ListingModel> getListing(String id) async {
    // Stale-while-revalidate: always fetch fresh data, but use cache as fallback
    try {
      final response = await _dio.get(ApiConstants.listingDetail(id));
      final listing = ListingModel.fromJson(response.data['data']);

      // Update cache with fresh data
      await _cache.saveListingDetail(listing);

      return listing;
    } catch (e) {
      // If network fails, try cache as fallback
      final cached = await _cache.getCachedListingDetail(id);
      if (cached != null) return cached;
      rethrow;
    }
  }
  
  Future<ListingModel> createListing(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.listings, data: data);
    final rawData = response.data['data'];
    return ListingModel.fromJson(rawData is Map ? rawData : response.data);
  }

  Future<void> uploadImages(String listingId, List<String> imagePaths) async {
    final formData = FormData();
    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(path),
      ));
    }
    await _dio.post(ApiConstants.listingImages(listingId), data: formData);
  }

  Future<ListingModel> updateListing(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.listingDetail(id), data: data);
    return ListingModel.fromJson(response.data['data']);
  }

  Future<void> updateListingStatus(String id, String status) async {
    await _dio.patch(ApiConstants.listingStatus(id), data: {'status': status});
  }

  Future<List<ListingModel>> getMyListings() async {
    // 1. Check Cache
    final cached = await _cache.getCachedListings('my_listings_private');
    if (cached != null) return cached;

    final response = await _dio.get(ApiConstants.myListings);
    final rawData = response.data['data'];
    final List<dynamic> listingsJson = rawData is List 
        ? rawData 
        : (rawData is Map ? rawData['listings'] : []) ?? [];

    final listings = listingsJson.map((json) => ListingModel.fromJson(json)).toList();

    // 2. Save Cache
    await _cache.saveListings('my_listings_private', listings);

    return listings;
  }

  Future<void> deleteListing(String id) async {
    await _dio.delete(ApiConstants.listingDetail(id));
    // Clear relevant caches after deletion
    await LocalCacheService.clearAll(); // Simplified clearing for safety
  }
}
