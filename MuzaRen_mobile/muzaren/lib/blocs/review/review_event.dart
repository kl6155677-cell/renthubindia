import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReview extends ReviewEvent {
  final String bookingId;
  final double rating;
  final String comment;

  const SubmitReview({
    required this.bookingId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [bookingId, rating, comment];
}
