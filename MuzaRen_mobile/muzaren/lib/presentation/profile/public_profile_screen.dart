import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../widgets/listing_card.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  String? _error;
  UserModel? _user;
  List<ListingModel> _listings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthRepository().getPublicProfile(widget.userId);
      final listings = await ListingRepository().getListings(userId: widget.userId, limit: 100);
      
      if (mounted) {
        setState(() {
          _user = user;
          _listings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text(_error ?? 'User not found.')),
      );
    }

    final user = _user!;
    final joinDate = DateFormat.yMMMd().format(user.createdAt);
    final isVerified = user.verificationStatus == 'VERIFIED';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              user.rating > 0 ? user.rating.toStringAsFixed(1) : 'New',
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Joined $joinDate',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Active Listings (${_listings.length})',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
          if (_listings.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = _listings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ListingCard(
                        listing: listing,
                        onTap: () {
                          context.push('/listing/${listing.id}');
                        },
                      ),
                    );
                  },
                  childCount: _listings.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active listings',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_user?.name} hasn\'t listed anything for rent yet.',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
