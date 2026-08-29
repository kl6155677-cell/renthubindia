import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../widgets/muza_snackbar.dart';
import '../../../data/repositories/listing_repository.dart';
import '../../../blocs/category/category_bloc.dart';
import '../../../blocs/category/category_event.dart';
import '../../../blocs/category/category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/location_data.dart';
import '../../../blocs/location/location_bloc.dart';
import '../../../blocs/location/location_state.dart';

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  static const int _totalSteps = 6;

  // Categories are fetched via CategoryBloc
  int _selectedCategoryIndex = -1;
  bool _isDetectingLocation = false;
  double? _latitude;
  double? _longitude;

  static const Map<String, IconData> _categoryIcons = {
    'furniture': Icons.chair_outlined,
    'lighting': Icons.lightbulb_outlined,
    'textiles': Icons.window_outlined,
    'outdoor': Icons.umbrella_outlined,
    'kitchen': Icons.coffee_outlined,
    'art': Icons.palette_outlined,
    'storage': Icons.inventory_2_outlined,
    'bedroom': Icons.bed_outlined,
    'wellness': Icons.spa_outlined,
    'workspace': Icons.work_outline,
    'kids': Icons.face_outlined,
    'smart-home': Icons.smart_screen_outlined,
    'electronics': Icons.devices_outlined,
    'vehicles': Icons.directions_car_outlined,
    'sports-outdoors': Icons.sports_soccer_outlined,
    'tools': Icons.build_outlined,
    'apparel': Icons.checkroom_outlined,
  };

  // ── Step 2: Details ──
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ── Step 3: Pricing ──
  final _priceController = TextEditingController();

  // ── Step 4: Location ──
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _locationController = TextEditingController();

  // ── Step 5: Availability ──
  DateTime? _availableFrom;
  DateTime? _availableTo;

  // ── Step 6: Photos ──
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _detectCurrentLocation(); // Auto-detect location for correct currency on start
  }

  void _loadCategories() {
    context.read<CategoryBloc>().add(LoadCategories());
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedCategoryIndex >= 0;
      case 1:
        final city = _cityController.text.trim();
        final country = _countryController.text.trim();
        return city.isNotEmpty && country.isNotEmpty;
      case 2:
        final title = _titleController.text.trim();
        final desc = _descriptionController.text.trim();
        return title.length >= 5 && desc.length >= 20;
      case 3:
        return _priceController.text.trim().isNotEmpty &&
            (double.tryParse(_priceController.text.trim()) ?? 0) > 0;
      case 4:
        return _availableFrom != null && _availableTo != null;
      case 5:
        return _selectedImages.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final listingRepo = context.read<ListingRepository>();
      final catState = context.read<CategoryBloc>().state;
      if (catState is! CategoryLoaded) return;
      final cat = catState.categories[_selectedCategoryIndex];

      final listing = await listingRepo.createListing({
        'categoryId': cat.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricePerDay': double.parse(_priceController.text.trim()),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : '${_cityController.text.trim()}, ${_countryController.text.trim()}',
        // Trim fractional seconds from ISO string: "2024-...T00:00:00.000Z" -> "2024-...T00:00:00Z"
        'availableFrom': '${_availableFrom!.toIso8601String().split('.').first}Z',
        'availableTo': '${_availableTo!.toIso8601String().split('.').first}Z',
        'latitude': _latitude ?? 0.0,
        'longitude': _longitude ?? 0.0,
      });

      // Upload images
      if (_selectedImages.isNotEmpty) {
        await listingRepo.uploadImages(
          listing.id,
          _selectedImages.map((img) => img.path).toList(),
        );
      }

      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Listing created successfully!',
          type: MuzaSnackbarType.success,
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        String message;
        if (e.response?.statusCode == 429) {
          message = 'You\'ve reached the listing limit. Please verify your account to post more listings.';
        } else if (e.response?.statusCode == 400) {
          final data = e.response?.data;
          if (data is Map && data['errors'] != null) {
            // Handle specialized validation object from Prisma/Zod
            final List errs = data['errors'] is List ? data['errors'] : [data['errors']];
            message = errs.first.toString();
          } else {
            message = data?['message'] ?? 'Invalid formatting. Please check all fields.';
          }
        } else {
          message = 'Something went wrong. Please try again.';
        }
        MuzaSnackbar.show(
          context,
          message: message,
          type: MuzaSnackbarType.error,
        );
      }
    } catch (e, stack) {
      AppLogger.error('Unexpected error during listing submission', e, stack);
      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Oops! Something went wrong on our end. Please try again.',
          type: MuzaSnackbarType.error,
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(),

          // Steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCategoryStep(),
                _buildLocationStep(),
                _buildDetailsStep(),
                _buildPricingStep(),
                _buildAvailabilityStep(),
                _buildPhotosStep(),
              ],
            ),
          ),

          // Navigation buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ─────────── PROGRESS BAR ───────────
  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────── STEP 1: CATEGORY ───────────
  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you renting out?',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose the category that fits your item best.',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (state is CategoryLoaded) {
                final categories = state.categories;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 32,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryIndex == index;
                    final icon = _categoryIcons[cat.slug] ?? Icons.category_outlined;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                size: 32,
                                color: isSelected ? Colors.white : const Color(0xFF0D6E75),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text('Failed to load categories'));
            },
          ),
        ],
      ),
    );
  }

  // ─────────── STEP 2: DETAILS ───────────
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your item',
            style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'A clear title and description helps renters find you. (Min 5 chars for title, 20 for description)',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          _buildInputLabel('TITLE'),
          const SizedBox(height: 8),
          _buildTextField(_titleController, 'e.g. Professional Sony A7IV Kit', maxLines: 1),
          const SizedBox(height: 24),
          _buildInputLabel('DESCRIPTION'),
          const SizedBox(height: 8),
          _buildTextField(_descriptionController, 'Describe condition, what\'s included, any rules...', maxLines: 5),
        ],
      ),
    );
  }

  // ─────────── STEP 3: PRICING ───────────
  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your price',
            style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a competitive daily rate for your item.',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          _buildInputLabel('PRICE PER DAY'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w700),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: '${() { final ls = context.read<LocationBloc>().state; return ls is LocationDetected ? ls.currencySymbol : r'$'; }()}  ',
                prefixStyle: const TextStyle(fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                hintText: '0',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Check similar items in your area to set a competitive price.',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── STEP 4: LOCATION ───────────
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where is your item?',
            style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help renters find items near them.',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          _buildInputLabel('COUNTRY'),
          const SizedBox(height: 8),
          _buildLocationPicker(
            controller: _countryController,
            hint: 'Select Country',
            onTap: () => _showSearchPicker(isCountry: true),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('CITY'),
          const SizedBox(height: 8),
          _buildLocationPicker(
            controller: _cityController,
            hint: _countryController.text.isEmpty ? 'Select Country First' : 'Select City',
            enabled: _countryController.text.isNotEmpty,
            onTap: () => _showSearchPicker(isCountry: false),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('ADDRESS (OPTIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(_locationController, 'Street address or landmark', maxLines: 1),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isDetectingLocation 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : OutlinedButton.icon(
                  onPressed: _detectCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use my current location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 15,
                  color: controller.text.isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF111827),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showSearchPicker({required bool isCountry}) {
    final List<String> items = isCountry 
        ? LocationData.countriesAndCities.keys.toList()
        : (LocationData.countriesAndCities[_countryController.text] ?? []);

    if (items.isEmpty && !isCountry) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchPickerSheet(
        title: isCountry ? 'Select Country' : 'Select City',
        items: items,
        onSelected: (val) {
          setState(() {
            if (isCountry) {
              _countryController.text = val;
              _cityController.clear(); // Reset city when country changes
            } else {
              _cityController.text = val;
            }
          });
        },
      ),
    );
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      final position = await Geolocator.getCurrentPosition();
      final List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
          _countryController.text = place.country ?? '';
          _locationController.text = '${place.street ?? ''}, ${place.postalCode ?? ''}';
        });
      }
    } catch (e) {
      // Silence raw errors in production, especially for background checks.
      // We only show a friendly message if the user manually triggered this.
      if (mounted && _isDetectingLocation) {
        MuzaSnackbar.show(
          context,
          message: 'Could not detect location automatically. Please select your city manually.',
          type: MuzaSnackbarType.info,
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  // ─────────── STEP 5: AVAILABILITY ───────────
  Widget _buildAvailabilityStep() {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When is it available?',
            style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set the dates your item is available for rent.',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          // From Date
          _buildInputLabel('AVAILABLE FROM'),
          const SizedBox(height: 8),
          _buildDatePicker(
            value: _availableFrom,
            hint: 'Select start date',
            onPick: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) setState(() => _availableFrom = date);
            },
          ),
          const SizedBox(height: 20),
          // To Date
          _buildInputLabel('AVAILABLE TO'),
          const SizedBox(height: 8),
          _buildDatePicker(
            value: _availableTo,
            hint: 'Select end date',
            onPick: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _availableFrom ?? DateTime.now(),
                firstDate: _availableFrom ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.primary),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) setState(() => _availableTo = date);
            },
          ),
          if (_availableFrom != null && _availableTo != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  Text(
                    '${_availableTo!.difference(_availableFrom!).inDays} days available',
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker({DateTime? value, required String hint, required VoidCallback onPick}) {
    final dateFormat = DateFormat.yMMMd();
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: value != null ? AppColors.primary : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Text(
              value != null ? dateFormat.format(value) : hint,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                color: value != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── STEP 6: PHOTOS ───────────
  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add photos',
            style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Up to 5 photos. The first one will be your cover image.',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          if (_selectedImages.isEmpty)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               decoration: BoxDecoration(
                 color: AppColors.error.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: const Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(Icons.error_outline, size: 14, color: AppColors.error),
                   SizedBox(width: 6),
                   Text(
                     'At least 1 photo is required to post',
                     style: TextStyle(
                       fontFamily: 'Sora',
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                       color: AppColors.error,
                     ),
                   ),
                 ],
               ),
             ),
          const SizedBox(height: 16),

          // Add photo button
          if (_selectedImages.length < 5)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap to add photo',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedImages.length}/5 photos',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),

          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Cover badge
                      if (index == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Cover',
                              style: TextStyle(fontFamily: 'Sora', fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      // Remove button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(index)),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final file = File(image.path);
      final sizeInBytes = await file.length();
      const maxSizeInBytes = 8 * 1024 * 1024; // 8MB

      if (sizeInBytes > maxSizeInBytes) {
        if (mounted) {
          final sizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_size_select_large, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Image Too Large',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The photo you selected exceeds the maximum file size allowed.',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your image', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF9CA3AF))),
                              const SizedBox(height: 2),
                              Text('$sizeMB MB', style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text('Max allowed', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF9CA3AF))),
                              SizedBox(height: 2),
                              Text('8.0 MB', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tips to reduce image size:',
                    style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(Icons.crop, 'Crop the photo to remove unused areas'),
                  const SizedBox(height: 6),
                  _buildTipRow(Icons.photo_library_outlined, 'Choose a different, smaller photo'),
                  const SizedBox(height: 6),
                  _buildTipRow(Icons.compress, 'Use a photo compression app'),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Got it, I\'ll pick another'),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (_selectedImages.length < 5) {
        setState(() => _selectedImages.add(image));
      }
    }
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  // ─────────── SHARED WIDGETS ───────────
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, int? maxLength}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          counterText: '', // Hide the counter
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─────────── BOTTOM BUTTONS ───────────
  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
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
                  textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed()
                  ? (isLastStep ? _submit : _nextStep)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLastStep ? 'Submit Listing' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelected;

  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  late List<String> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 16, color: Color(0xFF111827)),
                  ),
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

