import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<BookingBloc>().add(LoadMyBookings());
    context.read<BookingBloc>().add(LoadIncomingBookings());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listenWhen: (previous, current) => 
          previous.successMessage != current.successMessage || 
          previous.error != current.error,
      listener: (context, state) {
        if (state.successMessage != null && state.successMessage != context.read<BookingBloc>().state.successMessage) {
           // We only want to trigger on actual change, handled by listenWhen.
        }
        
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          title: const Text('My Bookings', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              height: 48,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'As Renter'),
                  Tab(text: 'As Owner'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRenterList(),
            _buildOwnerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRenterList() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state.isLoadingMy && state.myBookings.isEmpty) {
          return _buildSkeletonList();
        }
        
        return Stack(
          children: [
            _buildList(state.myBookings, isOwner: false, isSubmitting: state.isSubmitting),
            if (state.isLoadingMy && state.myBookings.isNotEmpty)
              const Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOwnerList() {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        if (state.isLoadingIncoming && state.incomingBookings.isEmpty) {
          return _buildSkeletonList();
        }

        return Stack(
          children: [
            _buildList(state.incomingBookings, isOwner: true, isSubmitting: state.isSubmitting),
            if (state.isLoadingIncoming && state.incomingBookings.isNotEmpty)
              const Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Opacity(
          opacity: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 140, height: 12, color: const Color(0xFFF3F4F6)),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 10, color: const Color(0xFFF3F4F6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, {required bool isOwner, required bool isSubmitting}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(isOwner ? 'No incoming requests' : 'No bookings yet', style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 6),
            Text(isOwner ? 'Booking requests from renters will appear here' : 'Browse listings and make your first booking', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFFD1D5DB))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildBookingCard(bookings[i], isOwner: isOwner, isSubmitting: isSubmitting),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isOwner, required bool isSubmitting}) {
    final locState = context.read<LocationBloc>().state;
    final currencySymbol = locState is LocationDetected ? locState.currencySymbol : r'$';
    final dateFormat = DateFormat.yMMMd();
    final statusColor = _statusColor(booking.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56, height: 56,
                  child: booking.listing?.images.isNotEmpty == true
                      ? CachedNetworkImage(imageUrl: booking.listing!.images.first, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_outlined, color: Color(0xFFD1D5DB))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.listing?.title ?? 'Booking',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(booking.startDate)} – ${dateFormat.format(booking.endDate)}',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(booking.status, style: TextStyle(fontFamily: 'Sora', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primary),
                onPressed: () => _startChat(booking, isOwner),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currencySymbol${booking.totalPrice.toStringAsFixed(0)} total', style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Text('${booking.endDate.difference(booking.startDate).inDays} days', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ),
          if (_showActions(booking, isOwner)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            _buildActions(booking, isOwner: isOwner, isSubmitting: isSubmitting),
          ],
        ],
      ),
    );
  }

  bool _showActions(BookingModel booking, bool isOwner) {
    final status = booking.status;
    if (isOwner && status == 'PENDING') return true;
    if (isOwner && status == 'ACCEPTED') return true;
    if (!isOwner && (status == 'PENDING' || status == 'ACCEPTED')) return true;
    if (!isOwner && status == 'COMPLETED' && booking.review == null) return true;
    return false;
  }

  Widget _buildActions(BookingModel booking, {required bool isOwner, required bool isSubmitting}) {
    if (isOwner) {
      if (booking.status == 'PENDING') {
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _startChat(booking, isOwner),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : () => _confirmAction(
                  title: 'Decline Booking?',
                  message: 'Are you sure you want to decline this booking request?',
                  onConfirm: () => context.read<BookingBloc>().add(CancelBookingRequested(booking.id)),
                  isDestructive: true,
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Decline', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : () => _confirmAction(
                  title: 'Accept Booking?',
                  message: 'Do you want to accept this rental request?',
                  onConfirm: () => context.read<BookingBloc>().add(AcceptBookingRequested(booking.id)),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Accept', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      } else if (booking.status == 'ACCEPTED') {
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _startChat(booking, isOwner),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : () => _confirmAction(
                  title: 'Cancel Rental?',
                  message: 'Are you sure you want to cancel this accepted rental?',
                  onConfirm: () => context.read<BookingBloc>().add(CancelBookingRequested(booking.id)),
                  isDestructive: true,
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : () => _confirmAction(
                  title: 'Complete Rental?',
                  message: 'Confirm that the item has been returned and the rental is finished.',
                  onConfirm: () => context.read<BookingBloc>().add(CompleteBookingRequested(booking.id)),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Mark Complete', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      }
    } else {
      if (booking.status == 'PENDING' || booking.status == 'ACCEPTED') {
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _startChat(booking, isOwner),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : () => _confirmAction(
                  title: 'Cancel Booking?',
                  message: 'Are you sure you want to cancel your booking request?',
                  onConfirm: () => context.read<BookingBloc>().add(CancelBookingRequested(booking.id)),
                  isDestructive: true,
                ),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Cancel Booking', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      } else if (booking.status == 'COMPLETED') {
        return Row(
          children: [
            OutlinedButton(
              onPressed: () => _startChat(booking, isOwner),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : () => _showReviewBottomSheet(context, booking),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Leave Review'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _confirmAction({required String title, required String message, required VoidCallback onConfirm, bool isDestructive = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: isDestructive ? AppColors.error : AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return AppColors.accent;
      case 'ACCEPTED': return AppColors.primary;
      case 'COMPLETED': return const Color(0xFF6B7280);
      case 'CANCELLED': return AppColors.error;
      default: return const Color(0xFF9CA3AF);
    }
  }

  void _showReviewBottomSheet(BuildContext context, BookingModel booking) {
    int rating = 0;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bContext) => StatefulBuilder(
        builder: (bContext, setState) {
          return BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              final bool isSubmitting = state.isSubmitting;

              return Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(bContext).viewInsets.bottom),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Leave a Review', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            IconButton(icon: const Icon(Icons.close, color: Color(0xFF6B7280)), onPressed: isSubmitting ? null : () => Navigator.pop(bContext)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('How was your experience with ${booking.listing?.title ?? 'this listing'}?', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280))),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              iconSize: 40,
                              icon: Icon(index < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: index < rating ? AppColors.accent : const Color(0xFFD1D5DB)),
                              onPressed: isSubmitting ? null : () => setState(() => rating = index + 1),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
                          child: TextField(
                            controller: commentController,
                            maxLines: 4,
                            enabled: !isSubmitting,
                            decoration: const InputDecoration(hintText: 'Share your thoughts...', hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (rating > 0 && !isSubmitting)
                                ? () {
                                    context.read<BookingBloc>().add(SubmitReviewRequested(bookingId: booking.id, rating: rating, comment: commentController.text.trim()));
                                    Navigator.pop(bContext);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: const Color(0xFFE5E7EB), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: isSubmitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Review', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _startChat(BookingModel booking, bool isOwner) async {
    final otherUser = isOwner ? booking.renter : booking.owner;
    if (otherUser == null) return;
    
    final messenger = ScaffoldMessenger.of(context);
    try {
      // In this case, the 'ownerId' for the API is simply the other user's ID
      final chat = await context.read<ChatRepository>().createOrGetChat(booking.listingId, otherUser.id);
      if (!mounted) return;
      
      context.push('/chat/${chat['id']}', extra: {
        'recipientName': otherUser.name,
        'recipientAvatar': otherUser.avatarUrl,
        'listingTitle': booking.listing?.title,
      });
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open chat. Please try again.')),
      );
    }
  }
}
