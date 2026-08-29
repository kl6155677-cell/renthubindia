import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  // Map category slugs to icons
  static final Map<String, IconData> _iconMap = {
    'electronics': Icons.devices_outlined,
    'vehicles': Icons.directions_car_outlined,
    'furniture': Icons.chair_outlined,
    'sports': Icons.sports_soccer_outlined,
    'cameras': Icons.camera_alt_outlined,
    'tools': Icons.build_outlined,
    'clothing': Icons.checkroom_outlined,
    'books': Icons.menu_book_outlined,
    'music': Icons.music_note_outlined,
    'gaming': Icons.sports_esports_outlined,
    'outdoor': Icons.terrain_outlined,
    'home': Icons.home_outlined,
    'office': Icons.business_center_outlined,
    'baby': Icons.child_care_outlined,
    'health': Icons.health_and_safety_outlined,
    'party': Icons.celebration_outlined,
  };

  // Map category slugs to gradient colors
  static final Map<String, List<Color>> _colorMap = {
    'electronics': [const Color(0xFF6366F1), const Color(0xFF818CF8)],
    'vehicles': [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
    'furniture': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
    'sports': [const Color(0xFF10B981), const Color(0xFF34D399)],
    'cameras': [const Color(0xFFEF4444), const Color(0xFFF87171)],
    'tools': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
    'clothing': [const Color(0xFFEC4899), const Color(0xFFF472B6)],
    'books': [const Color(0xFF14B8A6), const Color(0xFF2DD4BF)],
    'music': [const Color(0xFFF97316), const Color(0xFFFB923C)],
    'gaming': [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
    'outdoor': [const Color(0xFF059669), const Color(0xFF10B981)],
    'home': [const Color(0xFF0891B2), const Color(0xFF22D3EE)],
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.categories);
      final List<dynamic> data = response.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('Browse Categories', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadCategories,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.category_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No categories yet', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final slug = category.slug.toLowerCase();
    final icon = _iconMap[slug] ?? Icons.category_outlined;
    final colors = _colorMap[slug] ?? [AppColors.primary, const Color(0xFF1A7A7A)];

    return GestureDetector(
      onTap: () => context.go('/search', extra: {'categoryId': category.id, 'categoryName': category.name}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle with gradient
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
