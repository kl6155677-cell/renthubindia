import 'package:equatable/equatable.dart';
import '../../data/models/booking_model.dart';

class BookingState extends Equatable {
  final List<BookingModel> myBookings;
  final List<BookingModel> incomingBookings;
  final bool isLoadingMy;
  final bool isLoadingIncoming;
  final bool isSubmitting;
  final String? successMessage;
  final BookingModel? lastActionBooking;
  final String? error;

  const BookingState({
    this.myBookings = const [],
    this.incomingBookings = const [],
    this.isLoadingMy = false,
    this.isLoadingIncoming = false,
    this.isSubmitting = false,
    this.successMessage,
    this.lastActionBooking,
    this.error,
  });

  BookingState copyWith({
    List<BookingModel>? myBookings,
    List<BookingModel>? incomingBookings,
    bool? isLoadingMy,
    bool? isLoadingIncoming,
    bool? isSubmitting,
    String? successMessage,
    BookingModel? lastActionBooking,
    String? error,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return BookingState(
      myBookings: myBookings ?? this.myBookings,
      incomingBookings: incomingBookings ?? this.incomingBookings,
      isLoadingMy: isLoadingMy ?? this.isLoadingMy,
      isLoadingIncoming: isLoadingIncoming ?? this.isLoadingIncoming,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      lastActionBooking: clearSuccess ? null : (lastActionBooking ?? this.lastActionBooking),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        myBookings,
        incomingBookings,
        isLoadingMy,
        isLoadingIncoming,
        isSubmitting,
        successMessage,
        lastActionBooking,
        error,
      ];
}
