import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/location/location_bloc.dart';
import '../../../blocs/location/location_state.dart';

/// Edit Listing Screen — pre-fills the post listing wizard with existing data
class EditListingScreen extends StatefulWidget {
  final ListingModel listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  static const int _totalSteps = 4;

  // Categories
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;
  String? _selectedCategoryId;

  static const Map<String, IconData> _categoryIcons = {
    'electronics': Icons.devices_outlined,
    'vehicles': Icons.directions_car_outlined,
    'furniture': Icons.chair_outlined,
    'sports-outdoors': Icons.sports_soccer_outlined,
    'tools': Icons.build_outlined,
    'apparel': Icons.checkroom_outlined,
  };

  // Details
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Pricing
  final _priceController = TextEditingController();

  // Location
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _locationController = TextEditingController();

  // Availability
  DateTime? _availableFrom;
  DateTime? _availableTo;

  @override
  void initState() {
    super.initState();
    _prefillData();
    _loadCategories();
  }

  void _prefillData() {
    final l = widget.listing;
    _selectedCategoryId = l.categoryId;
    _titleController.text = l.title;
    _descriptionController.text = l.description;
    _priceController.text = l.pricePerDay.toStringAsFixed(0);
    _cityController.text = l.city;
    _countryController.text = l.country;
    _locationController.text = l.location;
    _availableFrom = l.availableFrom;
    _availableTo = l.availableTo;
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.categories);
      final List<dynamic> data = response.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitUpdate() async {
    setState(() => _isSubmitting = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricePerDay': double.tryParse(_priceController.text) ?? 0,
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'location': _locationController.text.trim(),
        if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
        if (_availableFrom != null) 'availableFrom': _availableFrom!.toIso8601String(),
        if (_availableTo != null) 'availableTo': _availableTo!.toIso8601String(),
      };
      await ApiService.dio.put(ApiConstants.listingDetail(widget.listing.id), data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        context.pop(true); // return true to signal refresh needed
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Update failed'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: const Text('Edit Listing', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCategoryStep(),
                _buildDetailsStep(),
                _buildPricingLocationStep(),
                _buildAvailabilityStep(),
              ],
            ),
          ),
          // Bottom buttons
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── PROGRESS BAR ──
  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of $_totalSteps', style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              Text(['Category', 'Details', 'Price & Location', 'Availability'][_currentStep], style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: CATEGORY ──
  Widget _buildCategoryStep() {
    if (_categoriesLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Category', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text('Choose the category that best fits your item', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategoryId == cat.id;
              final icon = _categoryIcons[cat.slug] ?? Icons.category_outlined;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: isSelected ? Colors.white : const Color(0xFF374151)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cat.name, style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF374151)))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── STEP 2: DETAILS ──
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Details', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 20),
          _buildLabel('Title'),
          _buildInput(_titleController, 'e.g. Sony A7III Camera'),
          const SizedBox(height: 16),
          _buildLabel('Description'),
          _buildInput(_descriptionController, 'Describe your item, condition, what\'s included...', maxLines: 5),
        ],
      ),
    );
  }

  // ── STEP 3: PRICING + LOCATION ──
  Widget _buildPricingLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price & Location', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 20),
          _buildLabel('Price per Day'),
          _buildInput(_priceController, '0', keyboardType: TextInputType.number, prefix: '${() { final ls = context.read<LocationBloc>().state; return ls is LocationDetected ? ls.currencySymbol : r'$'; }()} '),
          const SizedBox(height: 16),
          _buildLabel('Location'),
          _buildInput(_locationController, 'Street or area name'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('City'), _buildInput(_cityController, 'City')])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Country'), _buildInput(_countryController, 'Country')])),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 4: AVAILABILITY ──
  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Availability', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text('Set when your item is available for rent', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          _buildDatePicker('Available From', _availableFrom, (d) => setState(() => _availableFrom = d)),
          const SizedBox(height: 16),
          _buildDatePicker('Available To', _availableTo, (d) => setState(() => _availableTo = d)),
          if (_availableFrom != null && _availableTo != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Available for ${_availableTo!.difference(_availableFrom!).inDays} days',
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, ValueChanged<DateTime> onPicked) {
    final dateFormat = DateFormat.yMMMd();
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
              child: child!,
            );
          },
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Text(
              date != null ? dateFormat.format(date) : label,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: date != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM BAR ──
  Widget _buildBottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (isLast ? _submitUpdate : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isLast ? 'Save Changes' : 'Next', style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType, String? prefix}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixText: prefix,
          prefixStyle: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
