import 'package:equatable/equatable.dart';
import 'user_model.dart';

class ReviewModel extends Equatable {
  final String id;
  final String bookingId;
  final String listingId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String comment;
  final UserModel? reviewer;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.listingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    this.reviewer,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      reviewerId: json['reviewerId'] as String? ?? '',
      revieweeId: json['revieweeId'] as String? ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      comment: json['comment'] as String? ?? '',
      reviewer: json['reviewer'] != null ? UserModel.fromJson(json['reviewer'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'listingId': listingId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      if (reviewer != null) 'reviewer': reviewer!.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, bookingId, listingId, reviewerId, revieweeId, rating, comment, reviewer, createdAt];
}
