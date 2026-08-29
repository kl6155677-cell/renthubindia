import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../core/constants/api_constants.dart';
import '../../data/services/api_service.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';
import '../widgets/muza_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<BookingModel> _myBookings = [];
  List<ListingModel> _myListings = [];
  bool _listingsLoading = true;
  int _listingTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final bookings = await BookingRepository().getMyBookings();
      if (mounted) setState(() => _myBookings = bookings);
    } catch (_) {}
    try {
      final response = await ApiService.dio.get(ApiConstants.myListings);
      final List<dynamic> data = response.data['data'] is List
          ? response.data['data']
          : response.data['data']?['listings'] ?? [];
      if (mounted) {
        setState(() {
          _myListings = data.map((j) => ListingModel.fromJson(j)).toList();
          _listingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _listingsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildGradientHeader(user),
                  _buildStatsRow(user),
                  _buildQuickActions(),
                  _buildMyListings(),
                  _buildAccountSettings(user),
                  _buildLogoutButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── GRADIENT HEADER ──
  Widget _buildGradientHeader(UserModel? user) {
    final name = user?.name ?? 'Guest';
    final isVerified = user?.verificationStatus == 'VERIFIED';
    final location = [user?.city, user?.country].where((s) => s != null).join(', ');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient bg
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D4F4F), Color(0xFF1A7A7A), Color(0xFF2EAAA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/home'),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'RentHubIndia',
                        style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Avatar + info below gradient
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 20, color: AppColors.primary),
                    ],
                  ],
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // Avatar
        Positioned(
          top: 100,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: user?.avatarUrl != null
                    ? CachedNetworkImage(imageUrl: user!.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STATS ROW ──
  Widget _buildStatsRow(UserModel? user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          _buildStat('${_myListings.length}', 'LISTINGS', onTap: () => context.push('/my-listings')),
          _verticalDivider(),
          _buildStat('${_myBookings.length}', 'RENTALS', onTap: () => context.push('/my-bookings')),
          _verticalDivider(),
          _buildStat(
            user?.rating.toStringAsFixed(1) ?? "0.0",
            'RATING',
            showStar: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, {bool showStar = false, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (showStar) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'Sora', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFF3F4F6));
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.calendar_today_outlined,
              title: 'My Bookings',
              subtitle: 'Status & History',
              color: AppColors.primary,
              onTap: () => context.push('/my-bookings'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.inventory_2_outlined,
              title: 'My Listings',
              subtitle: 'Manage Items',
              color: const Color(0xFF111827),
              onTap: () => context.push('/my-listings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
  Widget _buildMyListings() {
    final tabs = ['Active', 'Paused', 'Expired'];
    final filteredListings = _myListings.where((l) {
      if (_listingTabIndex == 0) return l.status == 'ACTIVE';
      if (_listingTabIndex == 1) return l.status == 'PAUSED';
      return l.status == 'EXPIRED';
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Listings', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              GestureDetector(
                onTap: () => context.push('/my-listings'),
                child: const Text('View All', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A7A7A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final isSelected = _listingTabIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _listingTabIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF004D4D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          // Listing cards
          if (_listingsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else if (filteredListings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text('No ${tabs[_listingTabIndex].toLowerCase()} listings', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF9CA3AF))),
              ),
            )
          else
            ...filteredListings.map((l) => _buildMyListingCard(l)),
        ],
      ),
    );
  }

  Widget _buildMyListingCard(ListingModel listing) {
    final locState = context.read<LocationBloc>().state;
    final currencySymbol = locState is LocationDetected ? locState.currencySymbol : r'$';
    final hasImage = listing.images.isNotEmpty;
    final isPaused = listing.status == 'PAUSED';
    final isExpired = listing.status == 'EXPIRED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 90,
              height: 90,
              child: hasImage
                  ? CachedNetworkImage(imageUrl: listing.images.first, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_outlined, size: 28, color: Color(0xFFD1D5DB))),
            ),
          ),
          const SizedBox(width: 14),
          // Info Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaused 
                            ? const Color(0xFFFEF3C7) 
                            : isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.status,
                        style: TextStyle(
                          fontFamily: 'Sora', 
                          fontSize: 10, 
                          fontWeight: FontWeight.w700, 
                          color: isPaused 
                              ? const Color(0xFF92400E) 
                              : isExpired ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                    // Action Icons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/listing/edit', extra: listing),
                          child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _toggleListingStatus(listing),
                          child: Icon(
                            isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
                            size: 18,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        if (isPaused || isExpired) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _confirmDeleteListing(listing),
                            child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.3),
                ),
                const SizedBox(height: 6),
                // Real pending requests count
                if (listing.status == 'ACTIVE') () {
                  final pendingCount = listing.bookings?.where((b) => b['status'] == 'PENDING').length ?? 0;
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF854D0E)),
                        const SizedBox(width: 6),
                        Text('$pendingCount pending request${pendingCount > 1 ? "s" : ""}', 
                          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF854D0E))),
                      ],
                    ),
                  );
                }(),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol${listing.pricePerDay.toStringAsFixed(0)}/day',
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF854D0E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListingStatus(ListingModel listing) async {
    final newStatus = listing.status == 'PAUSED' ? 'ACTIVE' : 'PAUSED';
    try {
      await ListingRepository().updateListingStatus(listing.id, newStatus);
      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Listing ${newStatus == 'PAUSED' ? 'paused' : 'activated'}',
          type: MuzaSnackbarType.success,
        );
        _loadData(); // Re-fetch all data to refresh UI
      }
    } catch (e) {
      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Failed to update listing status',
          type: MuzaSnackbarType.error,
        );
      }
    }
  }

  void _confirmDeleteListing(ListingModel listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteListing(listing.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteListing(String id) async {
    try {
      await ListingRepository().deleteListing(id);
      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Listing deleted successfully',
          type: MuzaSnackbarType.success,
        );
        _loadData(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        MuzaSnackbar.show(
          context,
          message: 'Error deleting listing',
          type: MuzaSnackbarType.error,
        );
      }
    }
  }

  // ── ACCOUNT SETTINGS ──
  Widget _buildAccountSettings(UserModel? user) {
    final isVerified = user?.verificationStatus == 'VERIFIED';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Account Settings', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ),
          _buildSettingsItem(Icons.person_outline, 'Edit Profile', null, () => context.push('/profile/edit')),
          const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
          _buildSettingsItem(
            Icons.verified_outlined,
            'Identity Verification',
            isVerified ? 'Verified ✓' : null,
            () => context.push('/verification'),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
          _buildSettingsItem(Icons.help_outline, 'Support Center', null, () => context.push('/support')),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, String? subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label, style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: AppColors.success))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ── LOGOUT ──
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () {
          context.read<AuthBloc>().add(LogoutRequested());
          context.go('/auth');
        },
        child: const Row(
          children: [
            SizedBox(width: 4),
            Icon(Icons.logout, size: 18, color: AppColors.error),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
          ],
        ),
      ),
    );
  }
}
