import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../blocs/listing/listing_event.dart';
import '../../blocs/listing/listing_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/location_data.dart';
import '../../data/models/listing_model.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/empty_state.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_state.dart';
import '../../blocs/category/category_event.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import '../widgets/animate_entrance.dart';
import '../widgets/listing_card.dart';
import '../../core/utils/location_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategoryId;
  bool _hasInitialLoaded = false;

  @override
  void initState() {
    super.initState();
    final locState = context.read<LocationBloc>().state;
    if (locState is LocationDetected) {
      _initialLoad(country: locState.country, city: locState.city);
    } else {
      _initialLoad();
    }
  }

  void _initialLoad({String? country, String? city}) {
    if (_hasInitialLoaded && country == null && city == null) return;
    _hasInitialLoaded = true;

    // Trigger a fetch (global or localized)
    context.read<ListingBloc>().add(LoadListings(
      refresh: true,
      country: country,
      city: city,
    ));
    context.read<CategoryBloc>().add(LoadCategories());
  }

  Future<void> _onRefresh() async {
    String? categorySlug;
    final catState = context.read<CategoryBloc>().state;
    if (_selectedCategoryId != null && catState is CategoryLoaded) {
      try {
        categorySlug = catState.categories.firstWhere((c) => c.id == _selectedCategoryId).slug;
      } catch (_) {}
    }

    // Force a location refresh as well
    context.read<LocationBloc>().add(const DetectLocation(force: true));

    final locState = context.read<LocationBloc>().state;
    String? activeCountry;
    String? activeCity;
    if (locState is LocationDetected) {
      activeCountry = locState.country;
      activeCity = locState.city;
    }

    context.read<ListingBloc>().add(LoadListings(
      refresh: true, 
      categoryId: _selectedCategoryId,
      categorySlug: categorySlug,
      country: activeCountry,
      city: activeCity,
    ));
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationDetected) {
          // If location is detected, refresh listings for that specific country
          _initialLoad(country: state.country, city: state.city);
        } else if (state is LocationPermissionDenied || state is LocationError) {
          // Fallback to global if location fails
          _initialLoad();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  _buildSearchBar(),
                  _buildCategorySection(),
                  BlocBuilder<LocationBloc, LocationState>(
                    builder: (context, locState) {
                      return BlocBuilder<ListingBloc, ListingState>(
                        builder: (context, listingState) {
                          double? userLat;
                          double? userLng;
                          if (locState is LocationDetected) {
                            userLat = locState.latitude;
                            userLng = locState.longitude;
                          }

                          final allListings = listingState.listings;
                          final List<ListingModel> featured = [];
                          final List<ListingModel> nearby = [];

                          for (final listing in allListings) {
                            if (userLat != null && userLng != null) {
                              final dist = LocationUtils.calculateDistance(
                                startLat: userLat,
                                startLng: userLng,
                                endLat: listing.latitude,
                                endLng: listing.longitude,
                              );
                              if (dist >= 0 && dist <= 2000) {
                                featured.add(listing);
                              } else {
                                nearby.add(listing);
                              }
                            } else {
                              // If location not yet detected, put everything in nearby for now
                              // Or we could put the first 5 in featured as a fallback
                              if (featured.length < 5) {
                                featured.add(listing);
                              } else {
                                nearby.add(listing);
                              }
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (featured.isNotEmpty) _buildFeaturedSection(listingState, featured),
                              _buildNearbySection(listingState, nearby),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────── TOP BAR ───────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Location chip
          BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locState) {
              String label = 'Detecting...';
              if (locState is LocationDetected) {
                label = '${locState.city}, ${locState.countryCode}';
              } else if (locState is LocationPermissionDenied) {
                label = 'Set Location';
              }
              return GestureDetector(
                onTap: () => _showLocationSheet(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          // Notification bell with live badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationsLoaded) {
                unreadCount = state.unreadCount;
              }

              return GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF374151)),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────── SEARCH BAR ───────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
              SizedBox(width: 10),
              Text(
                'What do you want to rent today?',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
           return const SizedBox(height: 42, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (state is CategoryLoaded) {
          final categories = state.categories;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: Text(
                  'Browse by Category',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryId == cat.id;
                    return AnimateEntrance(
                      index: index,
                      offset: const Offset(20, 0),
                      child: GestureDetector(
                        onTap: () {
                          context.push('/search', extra: {'categoryId': cat.id});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF111827) : const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              if (cat.icon != null) ...[
                                Text(cat.icon!, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─────────── FEATURED NEAR YOU ───────────
  Widget _buildFeaturedSection(ListingState state, List<ListingModel> listings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Near You',
                style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              GestureDetector(
                onTap: () => context.go('/search'),
                child: const Text(
                  'See all →',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: _buildFeaturedContent(state, listings),
        ),
      ],
    );
  }

  Widget _buildFeaturedContent(ListingState state, List<ListingModel> listings) {
    if (state.status == ListingStatus.loading && !state.isPagination && listings.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => const SizedBox(width: 220, child: ShimmerCard()),
      );
    }

    if (listings.isEmpty) {
      return const Center(
        child: Text(
          'No featured listings yet',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: listings.length > 5 ? 5 : listings.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final listing = listings[index];
        return AnimateEntrance(
          index: index,
          offset: const Offset(40, 0),
          child: SizedBox(
            width: 220,
            child: ListingCard(
              listing: listing,
              heroSuffix: '_featured',
              onTap: () => context.push('/listing/${listing.id}', extra: {'heroSuffix': '_featured'}),

            ),
          ),
        );
      },
    );
  }

  // Featured card removed in favor of ListingCard


  // ─────────── NEARBY LISTINGS ───────────
  Widget _buildNearbySection(ListingState state, List<ListingModel> listings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Text(
            'Nearby Listings',
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
        _buildNearbyContent(state, listings),
      ],
    );
  }

  Widget _buildNearbyContent(ListingState state, List<ListingModel> listings) {
    if (state.status == ListingStatus.loading && !state.isPagination && listings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerCard(),
        ),
      );
    }

    if (listings.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No listings yet',
        subtitle: 'Be the first to post a rental listing in your area!',
        actionLabel: 'Post a Listing',
        onAction: () {
          context.push('/listing/post');
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return AnimateEntrance(
            index: index,
            child: ListingCard(
              listing: listing,
              heroSuffix: '_nearby',
              onTap: () => context.push('/listing/${listing.id}', extra: {'heroSuffix': '_nearby'}),
            ),
          );
        },
      ),
    );
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LocationSelectorSheet(),
    );
  }
}

class _LocationSelectorSheet extends StatefulWidget {
  const _LocationSelectorSheet();

  @override
  State<_LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<_LocationSelectorSheet> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        String currentCountry = 'United States';
        String currentCity = '';
        if (state is LocationDetected) {
          currentCountry = state.country;
          currentCity = state.city;
        }

        final cities = LocationData.countriesAndCities[currentCountry] ?? [];
        final filteredCities = cities
            .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 22, color: Color(0xFF374151)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Select Location',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827)),
                            decoration: InputDecoration(
                              hintText: 'Search city, state or area...',
                              hintStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF), fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF1A7A7A), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Current Location Button
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            context.read<LocationBloc>().add(const DetectLocation(force: true));
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCCF2F2).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFF1A7A7A), shape: BoxShape.circle),
                                  child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                                ),
                                SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use my current location',
                                      style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A7A7A)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Detection is fast and accurate',
                                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF5BA4A4)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Label
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CHOOSE FROM LIST',
                              style: TextStyle(fontFamily: 'Sora', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.0),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Text(
                                '${filteredCities.length} found',
                                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A7A7A)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // All in Country
                    if (_searchQuery.isEmpty)
                      SliverToBoxAdapter(
                        child: ListTile(
                          onTap: () {
                            final countryCode = LocationData.countryCodeToName.entries
                                .firstWhere((e) => e.value == currentCountry, 
                                    orElse: () => MapEntry('US', currentCountry))
                                .key;

                            context.read<LocationBloc>().add(ManualLocationChanged(
                              city: '',
                              country: currentCountry,
                              countryCode: countryCode,
                            ));

                            // Re-fetch listings with new location
                            context.read<ListingBloc>().add(LoadListings(
                              refresh: true,
                              country: currentCountry,
                              city: '',
                            ));

                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                          title: Text(
                            'All in $currentCountry',
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A7A7A)),
                          ),
                          trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF1A7A7A), size: 20),
                        ),
                      ),

                    // City List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final city = filteredCities[index];
                          final isSelected = city == currentCity;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  final countryCode = LocationData.countryCodeToName.entries
                                      .firstWhere((e) => e.value == currentCountry, 
                                          orElse: () => MapEntry('US', currentCountry))
                                      .key;

                                  context.read<LocationBloc>().add(ManualLocationChanged(
                                    city: city,
                                    country: currentCountry,
                                    countryCode: countryCode,
                                  ));

                                  // Re-fetch listings with new location
                                  context.read<ListingBloc>().add(LoadListings(
                                    refresh: true,
                                    country: currentCountry,
                                    city: city,
                                  ));

                                  Navigator.pop(context);
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                title: Text(
                                  city,
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1A7A7A) : const Color(0xFF374151),
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected ? Icons.check_rounded : Icons.chevron_right_rounded,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF1A7A7A) : const Color(0xFFD1D5DB),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Divider(height: 1, color: Color(0xFFF9FAFB)),
                              ),
                            ],
                          );
                        },
                        childCount: filteredCities.length,
                      ),
                    ),
                    
                    if (filteredCities.isEmpty && _searchQuery.isNotEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No cities found for "$_searchQuery"',
                                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Searchable picker dialog used by the location sheet ───────────────────
class _SearchPickerDialog extends StatefulWidget {
  final String title;
  final List<String> items;

  const _SearchPickerDialog({required this.title, required this.items});

  @override
  State<_SearchPickerDialog> createState() => _SearchPickerDialogState();
}

class _SearchPickerDialogState extends State<_SearchPickerDialog> {
  late List<String> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.items
            .where((item) => item.toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                widget.title,
                style: const TextStyle(fontFamily: 'Sora', fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  return ListTile(
                    title: Text(item, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827))),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
