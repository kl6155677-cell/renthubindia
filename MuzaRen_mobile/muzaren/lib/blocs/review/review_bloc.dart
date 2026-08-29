import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository reviewRepository;

  ReviewBloc({required this.reviewRepository}) : super(ReviewInitial()) {
    on<SubmitReview>(_onSubmitReview);
  }

  Future<void> _onSubmitReview(SubmitReview event, Emitter<ReviewState> emit) async {
    emit(ReviewSubmitting());
    try {
      await reviewRepository.createReview({
        'bookingId': event.bookingId,
        'rating': event.rating.toInt(),
        'comment': event.comment,
      });
      emit(const ReviewSuccess("Your review has been submitted successfully!"));
    } catch (e) {
      String errorMessage = "Failed to submit review. Please try again.";
      if (e.toString().contains('already been submitted')) {
        errorMessage = "A review has already been submitted for this booking.";
      }
      emit(ReviewError(errorMessage));
    }
  }
}
