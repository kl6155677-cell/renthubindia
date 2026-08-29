import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';

class BookingScreen extends StatefulWidget {
  final ListingModel listing;

  const BookingScreen({super.key, required this.listing});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _notesController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  double get _serviceFee => 0.0;
  double get _totalPrice => (_totalDays * widget.listing.pricePerDay);

  bool _isDateAvailable(DateTime date) {
    if (widget.listing.bookings == null) return true;
    for (var booking in widget.listing.bookings!) {
      final start = DateTime.parse(booking['startDate']).toLocal();
      final end = DateTime.parse(booking['endDate']).toLocal();
      // Reset hours to compare dates only
      final d = DateTime(date.year, date.month, date.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      
      if (d.isAtSameMomentAs(s) || d.isAtSameMomentAs(e) || (d.isAfter(s) && d.isBefore(e))) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.listing.availableFrom.isAfter(DateTime.now())
          ? widget.listing.availableFrom
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: widget.listing.availableTo,
      selectableDayPredicate: _isDateAvailable,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && (_endDate!.isBefore(date) || !_isRangeAvailable(date, _endDate!))) {
          _endDate = null;
        }
      });
    }
  }

  bool _isRangeAvailable(DateTime start, DateTime end) {
    if (widget.listing.bookings == null) return true;
    for (var booking in widget.listing.bookings!) {
      final bStart = DateTime.parse(booking['startDate']).toLocal();
      final bEnd = DateTime.parse(booking['endDate']).toLocal();
      
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      final bs = DateTime(bStart.year, bStart.month, bStart.day);
      final be = DateTime(bEnd.year, bEnd.month, bEnd.day);

      // Check if any part of the requested range overlaps with an existing booking
      if (!(e.isBefore(bs) || s.isAfter(be))) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: widget.listing.availableTo,
      selectableDayPredicate: (date) => _isDateAvailable(date) && _isRangeAvailable(_startDate!, date),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _endDate = date);
  }

  void _submit() {
    if (_startDate == null || _endDate == null) return;
    context.read<BookingBloc>().add(CreateBookingRequested(
      listingId: widget.listing.id,
      startDate: _startDate!,
      endDate: _endDate!,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Request Sent!',
              style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'The owner will review your request and get back to you shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  context.pushReplacement('/my-bookings');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    // Use the user's detected currency symbol (not the listing's country currency)
    final locState = context.watch<LocationBloc>().state;
    final currencySymbol = locState is LocationDetected ? locState.currencySymbol : r'$';

    return BlocListener<BookingBloc, BookingState>(
      listenWhen: (previous, current) => 
          (previous.successMessage == null && current.successMessage != null) || 
          (previous.error == null && current.error != null),
      listener: (context, state) {
        if (state.successMessage != null) {
          _showSuccessDialog();
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
          elevation: 0,
          title: const Text(
            'Book Rental',
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Listing Summary Card ──
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 72,
                              height: 72,
                              color: const Color(0xFFF3F4F6),
                              child: const Icon(Icons.image_outlined, color: Color(0xFFD1D5DB)),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${listing.owner?.name ?? "Owner"}',
                            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$currencySymbol${listing.pricePerDay.toStringAsFixed(0)} /day',
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Date Pickers ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Dates',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateBox('Start Date', _startDate, _pickStartDate)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateBox('End Date', _endDate, _pickEndDate)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Notes to Owner ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes to Owner (Optional)',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Any special requests or info for the owner...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Price Breakdown ──
              if (_totalDays > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Price per day', '$currencySymbol${listing.pricePerDay.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),
                      _buildPriceRow('Duration', '$_totalDays day${_totalDays > 1 ? "s" : ""}'),
                      const SizedBox(height: 10),
                      // _buildPriceRow('Service fee', '${CurrencyUtils.symbolFromCode(CurrencyUtils.fromCountry(listing.country))}${_serviceFee.toStringAsFixed(0)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$currencySymbol${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Info Box ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No payment required — the owner will confirm your request first.',
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: AppColors.primary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        // ── Sticky Bottom ──
        bottomNavigationBar: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            final isSubmitting = state.isSubmitting;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_startDate != null && _endDate != null && !isSubmitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send Booking Request'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateBox(String label, DateTime? value, VoidCallback onTap) {
    final dateFormat = DateFormat.yMMMd();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value != null ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: value != null ? AppColors.primary : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Text(
                  value != null ? dateFormat.format(value) : 'Select',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
