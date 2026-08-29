import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'listing_model.dart';
import 'review_model.dart';

class BookingModel extends Equatable {
  final String id;
  final String listingId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final String? notes;
  final ListingModel? listing;
  final UserModel? renter;
  final UserModel? owner;
  final ReviewModel? review;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.listing,
    this.renter,
    this.owner,
    this.review,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      renterId: json['renterId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      totalPrice: double.tryParse(json['totalPrice']?.toString() ?? '') ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      notes: json['notes'] as String?,
      listing: json['listing'] != null ? ListingModel.fromJson(json['listing'] as Map<String, dynamic>) : null,
      renter: json['renter'] != null ? UserModel.fromJson(json['renter'] as Map<String, dynamic>) : null,
      owner: json['owner'] != null ? UserModel.fromJson(json['owner'] as Map<String, dynamic>) : null,
      review: json['review'] != null ? ReviewModel.fromJson(json['review'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'renterId': renterId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      if (listing != null) 'listing': listing!.toJson(),
      if (renter != null) 'renter': renter!.toJson(),
      if (owner != null) 'owner': owner!.toJson(),
      if (review != null) 'review': review!.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id, listingId, renterId, ownerId, startDate, endDate, 
        totalPrice, status, listing, renter, owner, review, createdAt
      ];
}

