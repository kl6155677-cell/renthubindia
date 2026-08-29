import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyBookings extends BookingEvent {}

class CreateBookingRequested extends BookingEvent {
  final String listingId;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  const CreateBookingRequested({
    required this.listingId,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  @override
  List<Object?> get props => [listingId, startDate, endDate, notes];
}

class AcceptBookingRequested extends BookingEvent {
  final String id;

  const AcceptBookingRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadIncomingBookings extends BookingEvent {}

class CancelBookingRequested extends BookingEvent {
  final String id;

  const CancelBookingRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CompleteBookingRequested extends BookingEvent {
  final String id;

  const CompleteBookingRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class SubmitReviewRequested extends BookingEvent {
  final String bookingId;
  final int rating;
  final String? comment;

  const SubmitReviewRequested({
    required this.bookingId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [bookingId, rating, comment];
}
