import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/category_model.dart';
import '../services/local_cache_service.dart';
import 'package:dio/dio.dart';

class CategoryRepository {
  final Dio _dio = ApiService.dio;
  final LocalCacheService _cache = LocalCacheService();

  Future<List<CategoryModel>> getCategories() async {
    // 1. Fetch from API
    try {
      final response = await _dio.get(ApiConstants.categories);
      final List<dynamic> apiData = response.data['data'] ?? [];
      
      final List<Map<String, dynamic>> goldStandard = [
        {'id': 'cat_v', 'name': 'Vehicles', 'slug': 'vehicles', 'icon': '🚗'},
        {'id': 'cat_e', 'name': 'Electronics', 'slug': 'electronics', 'icon': '💻'},
        {'id': 'cat_1', 'name': 'Furniture', 'slug': 'furniture', 'icon': '🛋️'},
        {'id': 'cat_2', 'name': 'Lighting', 'slug': 'lighting', 'icon': '💡'},
        {'id': 'cat_3', 'name': 'Textiles', 'slug': 'textiles', 'icon': '🪟'},
        {'id': 'cat_4', 'name': 'Outdoor', 'slug': 'outdoor', 'icon': '🏖️'},
        {'id': 'cat_5', 'name': 'Kitchen', 'slug': 'kitchen', 'icon': '☕'},
        {'id': 'cat_6', 'name': 'Art', 'slug': 'art', 'icon': '🎨'},
        {'id': 'cat_7', 'name': 'Storage', 'slug': 'storage', 'icon': '📦'},
        {'id': 'cat_8', 'name': 'Bedroom', 'slug': 'bedroom', 'icon': '🛏️'},
        {'id': 'cat_9', 'name': 'Wellness', 'slug': 'wellness', 'icon': '🌿'},
        {'id': 'cat_10', 'name': 'Workspace', 'slug': 'workspace', 'icon': '💼'},
        {'id': 'cat_11', 'name': 'Kids', 'slug': 'kids', 'icon': '👶'},
        {'id': 'cat_12', 'name': 'Smart Home', 'slug': 'smart-home', 'icon': '📱'},
      ];

      final Map<String, dynamic> merged = {};
      for (var item in goldStandard) { merged[item['slug']] = item; }
      for (var item in apiData) { merged[item['slug']] = item; }

      final List<dynamic> finalData = merged.values.toList();
      
      // Strict Priority Sort
      finalData.sort((a, b) {
        if (a['slug'] == 'vehicles') return -1;
        if (b['slug'] == 'vehicles') return 1;
        if (a['slug'] == 'electronics') return -1;
        if (b['slug'] == 'electronics') return 1;
        return 0;
      });

      await _cache.saveCategories(finalData);
      
      return finalData.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      // 2. Fallback to Cache
      final cached = await _cache.getCachedCategories();
      if (cached != null && cached is List) {
        return cached.map((json) => CategoryModel.fromJson(json)).toList();
      }

      // 3. Fallback to Gold Standard
      return [
        {'id': 'cat_1', 'name': 'Furniture', 'slug': 'furniture', 'icon': '🛋️'},
        {'id': 'cat_2', 'name': 'Lighting', 'slug': 'lighting', 'icon': '💡'},
        {'id': 'cat_3', 'name': 'Textiles', 'slug': 'textiles', 'icon': '🪟'},
        {'id': 'cat_4', 'name': 'Outdoor', 'slug': 'outdoor', 'icon': '🏖️'},
        {'id': 'cat_5', 'name': 'Kitchen', 'slug': 'kitchen', 'icon': '☕'},
        {'id': 'cat_6', 'name': 'Art', 'slug': 'art', 'icon': '🎨'},
      ].map((json) => CategoryModel.fromJson(json)).toList();
    }
  }
}
