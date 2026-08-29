import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../blocs/listing/listing_event.dart';
import '../../blocs/listing/listing_state.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/animate_entrance.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';
class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final String? heroSuffix;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.heroSuffix,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = true;
  bool _descriptionExpanded = false;
  bool _isBookmarked = false;
  DateTime _currentCalendarMonth = DateTime.now();
  bool _calendarInitialized = false;

  @override
  void initState() {
    super.initState();
    context.read<ListingBloc>().add(LoadListingDetail(widget.listingId));
    _loadReviews();
  }

  void _initializeCalendar(ListingModel listing) {
    _currentCalendarMonth = DateTime(listing.availableFrom.year, listing.availableFrom.month);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewRepository().getListingReviews(widget.listingId);
      debugPrint('DEBUG: Loaded ${reviews.length} reviews for listing ${widget.listingId}');
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _reviewsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading reviews: $e');
      if (mounted) {
        setState(() => _reviewsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListingBloc, ListingState>(
      builder: (context, state) {
        if (state.status == ListingStatus.loading && state.detailListing == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state.status == ListingStatus.error && state.detailListing == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: Center(child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(state.errorMessage ?? "An error occurred", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF6B7280))),
            )),
          );
        }

        if (state.detailListing != null) {
          if (!_calendarInitialized) {
            _initializeCalendar(state.detailListing!);
            _calendarInitialized = true;
          }
          return _buildDetailView(context, state.detailListing!);
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _buildDetailView(BuildContext context, ListingModel listing) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Image Header ──
              SliverToBoxAdapter(child: _buildImageCarousel(listing)),

              // ── Content Card (Overlays image slightly) ──
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Main Info ──
                        AnimateEntrance(index: 1, child: _buildMainInfo(listing)),
                        
                        // ── Owner Card ──
                        AnimateEntrance(index: 2, child: _buildOwnerCard(listing)),

                        const SizedBox(height: 24),
                        
                        // ── Description ──
                        AnimateEntrance(index: 3, child: _buildDescription(listing)),

                        const SizedBox(height: 24),

                        // ── Availability ──
                        AnimateEntrance(index: 4, child: _buildAvailability(listing)),

                        const SizedBox(height: 24),

                        // ── Reviews Section ──
                        AnimateEntrance(index: 5, child: _buildReviewsSection(listing)),

                        // Padding for sticky bottom bar
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Floating Action Buttons (Top) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFloatingButton(Icons.arrow_back_rounded, () => context.pop()),
                Row(
                  children: [
                    _buildFloatingButton(Icons.share_outlined, () {
                      Clipboard.setData(ClipboardData(text: 'https://renthubindia.com/listing/${listing.id}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!'), behavior: SnackBarBehavior.floating),
                      );
                    }),
                    const SizedBox(width: 12),
                    _buildFloatingButton(
                      _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      () {
                        setState(() => _isBookmarked = !_isBookmarked);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isBookmarked ? 'Listing saved!' : 'Listing removed from saves'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      iconColor: _isBookmarked ? AppColors.primary : const Color(0xFF374151),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(listing),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(ListingModel listing) {
    final images = listing.images;
    final hasImages = images.isNotEmpty;

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          if (hasImages)
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                final imageWidget = CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFFD1D5DB)),
                  ),
                );

                final content = index == 0
                    ? Hero(
                        tag: 'listing_image_${listing.id}${widget.heroSuffix ?? ''}',
                        child: imageWidget,
                      )
                    : imageWidget;

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        images: images,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  child: content,
                );
              },
            )
          else
            Hero(
              tag: 'listing_image_${listing.id}${widget.heroSuffix ?? ''}',
              child: Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFD1D5DB)),
                ),
              ),
            ),

          // Dot indicators
          if (hasImages && images.length > 1)
            Positioned(
              bottom: 46, // Adjusted for content overlap
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImageIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────── MAIN INFO ───────────
  Widget _buildMainInfo(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (listing.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.category!.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Sora', 
                            fontSize: 10, 
                            fontWeight: FontWeight.w800, 
                            color: AppColors.primary, 
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontFamily: 'Sora', 
                        fontSize: 24, 
                        fontWeight: FontWeight.w800, 
                        color: Color(0xFF111827), 
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 14), // Offset for category badge
                  Builder(
                    builder: (ctx) {
                      final locState = ctx.read<LocationBloc>().state;
                      final symbol = locState is LocationDetected ? locState.currencySymbol : r'$';
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$symbol${listing.pricePerDay.toInt()}',
                            style: const TextStyle(
                              fontFamily: 'Sora', 
                              fontSize: 26, 
                              fontWeight: FontWeight.w800, 
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '/day',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans', 
                              fontSize: 12, 
                              fontWeight: FontWeight.w600, 
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${listing.city}, ${listing.country}',
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Available: ${DateFormat('MMM d').format(listing.availableFrom)} - ${DateFormat('d').format(listing.availableTo)}',
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────── OWNER CARD ───────────
  Widget _buildOwnerCard(ListingModel listing) {
    final owner = listing.owner;
    if (owner == null) return const SizedBox.shrink();

    final isVerified = owner.verificationStatus == 'VERIFIED';

    return GestureDetector(
      onTap: () => context.push('/user/${owner.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: owner.avatarUrl != null ? CachedNetworkImageProvider(owner.avatarUrl!) : null,
                  child: owner.avatarUrl == null ? Text(owner.name[0].toUpperCase(), style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)) : null,
                ),
                if (isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle, size: 18, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner.name,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${owner.rating.toStringAsFixed(1)} (${listing.reviewCount} reviews)',
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isVerified)
                  const Text('VERIFIED', style: TextStyle(fontFamily: 'Sora', fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 0.5)),
                Text(
                  'View\nProfile',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, decoration: TextDecoration.underline, height: 1.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── DESCRIPTION ───────────
  Widget _buildDescription(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          Text(
            listing.description,
            maxLines: _descriptionExpanded ? null : 4,
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF4B5563), height: 1.6),
          ),
          if (listing.description.length > 150) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Text(
                _descriptionExpanded ? 'Read less' : 'Read more',
                style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────── AVAILABILITY ───────────
  Widget _buildAvailability(ListingModel listing) {
    final monthStart = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, 1);
    final daysInMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0).day;
    final firstWeekday = monthStart.weekday; // 1 = Monday, 7 = Sunday
    
    // Adjust for Monday start (1=Mon ... 7=Sun)
    final paddingDays = firstWeekday - 1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability',
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMMM yyyy').format(_currentCalendarMonth), style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _currentCalendarMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month - 1)),
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF9CA3AF)),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _currentCalendarMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1)),
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => SizedBox(width: 32, child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))))).toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: (MediaQuery.of(context).size.width - 48 - 40 - (38 * 7)) / 6,
                  runSpacing: 8,
                  children: List.generate(paddingDays + daysInMonth, (index) {
                    if (index < paddingDays) {
                      return const SizedBox(width: 38, height: 38);
                    }
                    final day = index - paddingDays + 1;
                    final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, day);
                    
                    final isAvailable = (date.isAfter(listing.availableFrom.subtract(const Duration(days: 1))) && 
                                       date.isBefore(listing.availableTo.add(const Duration(days: 1))));
                    
                    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

                    return _buildCalendarDay(day.toString(), isSelected: isAvailable, isToday: isToday);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(String day, {bool isSelected = false, bool isToday = false}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: AppColors.primary, width: 1) : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF374151),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────── REVIEWS SECTION ───────────
  Widget _buildReviewsSection(ListingModel listing) {
    final distribution = _calculateRatingDistribution();
    final averageRating = listing.rating ?? 0.0;
    final totalReviews = listing.reviewCount;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRatingBar(5, distribution[5]!),
          const SizedBox(height: 8),
          _buildRatingBar(4, distribution[4]!),
          const SizedBox(height: 8),
          _buildRatingBar(3, distribution[3]!),
          const SizedBox(height: 8),
          _buildRatingBar(2, distribution[2]!),
          const SizedBox(height: 8),
          _buildRatingBar(1, distribution[1]!),
          const SizedBox(height: 24),

          if (_reviewsLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else if (_reviews.isEmpty)
            const Text('No reviews yet.', style: TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF)))
          else
            ..._reviews.take(2).map((review) => _buildReviewCard(review)),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                debugPrint('DEBUG: Show all reviews button pressed');
                _showAllReviewsModal(listing);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Show all $totalReviews reviews',
                style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. We will review this listing.'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  const Text('Report this listing', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF9CA3AF), decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _calculateRatingDistribution() {
    if (_reviews.isEmpty) return {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      int rating = r.rating.round();
      if (rating >= 1 && rating <= 5) {
        counts[rating] = counts[rating]! + 1;
      }
    }
    return counts.map((k, v) => MapEntry(k, v / _reviews.length));
  }

  Widget _buildRatingBar(int stars, double percent) {
    return Row(
      children: [
        SizedBox(width: 12, child: Text(stars.toString(), style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: percent.isNaN ? 0 : percent,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  void _showAllReviewsModal(ListingModel listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Reviews (${listing.reviewCount})', style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _reviewsLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _reviews.isEmpty
                      ? const Center(child: Text('No review details available.', style: TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF))))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final reviewer = review.reviewer;
    final date = DateFormat.yMMMd().format(review.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  reviewer?.name.isNotEmpty == true ? reviewer!.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewer?.name ?? 'Anonymous', style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    Text(date, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: AppColors.accent);
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
          ],
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }


  // ─────────── FLOATING BUTTON ───────────
  Widget _buildFloatingButton(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF374151)),
      ),
    );
  }

  // ─────────── BOTTOM BAR ───────────
  Widget _buildBottomBar(ListingModel listing) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
    
    if (currentUserId != null && currentUserId == listing.userId) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Builder(
                    builder: (ctx) {
                      final locState = ctx.read<LocationBloc>().state;
                      final symbol = locState is LocationDetected ? locState.currencySymbol : r'$';
                      return Text(
                        '$symbol${listing.pricePerDay.toInt()}',
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                      );
                    },
                  ),
                ],
              ),
              const Text('per day total', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final owner = listing.owner;
                if (owner == null) return;
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final chat = await ChatRepository().createOrGetChat(listing.id, owner.id);
                  if (!context.mounted) return;
                  context.push('/chat/${chat['id']}', extra: {
                    'recipientName': owner.name,
                    'recipientAvatar': owner.avatarUrl,
                    'listingId': listing.id,
                    'listingTitle': listing.title,
                    'listingPrice': listing.pricePerDay,
                    'listingImageUrl': listing.images.isNotEmpty ? listing.images.first : null,
                  });
                } catch (e) {
                  messenger.showSnackBar(const SnackBar(content: Text('Could not open chat.')));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Color(0xFF111827), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Chat', style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => context.push('/booking', extra: listing),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Book Now', style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
              );
            },
          ),

          // Header with Close Button and Counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  // Image Counter
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Sora',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  
                  // Spacer for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
