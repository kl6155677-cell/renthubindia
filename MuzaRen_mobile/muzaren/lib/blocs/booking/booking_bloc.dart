import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/local_cache_service.dart';
import '../../data/models/booking_model.dart';
import '../../core/utils/error_utils.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository bookingRepository;
  final LocalCacheService _cache = LocalCacheService();

  BookingBloc({required this.bookingRepository}) : super(const BookingState()) {
    on<LoadMyBookings>(_onLoadMyBookings);
    on<LoadIncomingBookings>(_onLoadIncomingBookings);
    on<CreateBookingRequested>(_onCreateBookingRequested);
    on<AcceptBookingRequested>(_onAcceptBookingRequested);
    on<CancelBookingRequested>(_onCancelBookingRequested);
    on<CompleteBookingRequested>(_onCompleteBookingRequested);
    on<SubmitReviewRequested>(_onSubmitReviewRequested);
  }

  Future<void> _onLoadMyBookings(LoadMyBookings event, Emitter<BookingState> emit) async {
    // Show cached data instantly, then refresh from server
    if (state.myBookings.isEmpty) {
      final cached = await _cache.getCachedMyBookings();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(myBookings: cached, isLoadingMy: true, clearError: true));
      } else {
        emit(state.copyWith(isLoadingMy: true, clearError: true));
      }
    } else {
      emit(state.copyWith(isLoadingMy: true, clearError: true));
    }

    try {
      final bookings = await bookingRepository.getMyBookings();
      emit(state.copyWith(myBookings: bookings, isLoadingMy: false));
      await _cache.saveMyBookings(bookings);
    } catch (e) {
      emit(state.copyWith(isLoadingMy: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onLoadIncomingBookings(LoadIncomingBookings event, Emitter<BookingState> emit) async {
    // Show cached data instantly, then refresh from server
    if (state.incomingBookings.isEmpty) {
      final cached = await _cache.getCachedIncomingBookings();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(incomingBookings: cached, isLoadingIncoming: true, clearError: true));
      } else {
        emit(state.copyWith(isLoadingIncoming: true, clearError: true));
      }
    } else {
      emit(state.copyWith(isLoadingIncoming: true, clearError: true));
    }

    try {
      final bookings = await bookingRepository.getIncomingBookings();
      emit(state.copyWith(incomingBookings: bookings, isLoadingIncoming: false));
      await _cache.saveIncomingBookings(bookings);
    } catch (e) {
      emit(state.copyWith(isLoadingIncoming: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onCreateBookingRequested(CreateBookingRequested event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSuccess: true, clearError: true));
    try {
      final booking = await bookingRepository.createBooking({
        'listingId': event.listingId,
        'startDate': "${event.startDate.year}-${event.startDate.month.toString().padLeft(2, '0')}-${event.startDate.day.toString().padLeft(2, '0')}T00:00:00Z",
        'endDate': "${event.endDate.year}-${event.endDate.month.toString().padLeft(2, '0')}-${event.endDate.day.toString().padLeft(2, '0')}T00:00:00Z",
        if (event.notes != null) 'notes': event.notes,
      });
      final updatedList = [booking, ...state.myBookings];
      emit(state.copyWith(
        isSubmitting: false,
        myBookings: updatedList,
        successMessage: "Booking request sent!",
        lastActionBooking: booking,
      ));
      await _cache.saveMyBookings(updatedList);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onAcceptBookingRequested(AcceptBookingRequested event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSuccess: true, clearError: true));
    try {
      final booking = await bookingRepository.acceptBooking(event.id);

      final updatedList = List<BookingModel>.from(state.incomingBookings);
      final index = updatedList.indexWhere((b) => b.id == event.id);
      if (index != -1) updatedList[index] = booking;

      emit(state.copyWith(
        isSubmitting: false,
        incomingBookings: updatedList,
        successMessage: "Booking accepted!",
        lastActionBooking: booking,
      ));
      await _cache.saveIncomingBookings(updatedList);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onCancelBookingRequested(CancelBookingRequested event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSuccess: true, clearError: true));
    try {
      final booking = await bookingRepository.cancelBooking(event.id);

      // Update both lists
      final updatedMy = List<BookingModel>.from(state.myBookings);
      final mIndex = updatedMy.indexWhere((b) => b.id == event.id);
      if (mIndex != -1) updatedMy[mIndex] = booking;

      final updatedIncoming = List<BookingModel>.from(state.incomingBookings);
      final iIndex = updatedIncoming.indexWhere((b) => b.id == event.id);
      if (iIndex != -1) updatedIncoming[iIndex] = booking;

      emit(state.copyWith(
        isSubmitting: false,
        myBookings: updatedMy,
        incomingBookings: updatedIncoming,
        successMessage: "Booking cancelled.",
        lastActionBooking: booking,
      ));
      await _cache.saveMyBookings(updatedMy);
      await _cache.saveIncomingBookings(updatedIncoming);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onCompleteBookingRequested(CompleteBookingRequested event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSuccess: true, clearError: true));
    try {
      final booking = await bookingRepository.completeBooking(event.id);

      final updatedList = List<BookingModel>.from(state.incomingBookings);
      final index = updatedList.indexWhere((b) => b.id == event.id);
      if (index != -1) updatedList[index] = booking;

      emit(state.copyWith(
        isSubmitting: false,
        incomingBookings: updatedList,
        successMessage: "Rental completed!",
        lastActionBooking: booking,
      ));
      await _cache.saveIncomingBookings(updatedList);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: ErrorUtils.formatError(e)));
    }
  }

  Future<void> _onSubmitReviewRequested(SubmitReviewRequested event, Emitter<BookingState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSuccess: true, clearError: true));
    try {
      await bookingRepository.submitReview(event.bookingId, event.rating, event.comment);

      // Refresh my bookings to update the local state (hide review button)
      final bookings = await bookingRepository.getMyBookings();

      emit(state.copyWith(
        isSubmitting: false,
        myBookings: bookings,
        successMessage: "Review submitted!",
      ));
      await _cache.saveMyBookings(bookings);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: ErrorUtils.formatError(e)));
    }
  }
}
