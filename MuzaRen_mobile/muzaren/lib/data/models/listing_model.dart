import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'category_model.dart';

class ListingModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String description;
  final double pricePerDay;
  final String location;
  final double latitude;
  final double longitude;
  final String country;
  final String city;
  final String status;
  final bool isApproved;
  final DateTime availableFrom;
  final DateTime availableTo;
  final List<String> images;
  final UserModel? owner;
  final CategoryModel? category;
  final List<Map<String, dynamic>>? bookings;
  final double? rating;
  final int reviewCount;
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.country,
    required this.city,
    required this.status,
    required this.isApproved,
    required this.availableFrom,
    required this.availableTo,
    required this.images,
    this.owner,
    this.category,
    this.bookings,
    this.rating,
    this.reviewCount = 0,
    required this.createdAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pricePerDay: double.tryParse(json['pricePerDay']?.toString() ?? '') ?? 0.0,
      location: json['location'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      isApproved: json['isApproved'] as bool? ?? false,
      availableFrom: json['availableFrom'] != null ? DateTime.parse(json['availableFrom']) : DateTime.now(),
      availableTo: json['availableTo'] != null ? DateTime.parse(json['availableTo']) : DateTime.now(),
      images: (json['images'] as List<dynamic>?)?.map((e) {
        if (e is String) return e;
        if (e is Map) return e['imageUrl'] as String? ?? '';
        return '';
      }).where((s) => s.isNotEmpty).toList() ?? [],
      owner: (json['owner'] != null)
          ? UserModel.fromJson(json['owner'] as Map<String, dynamic>)
          : (json['user'] != null)
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      category: json['category'] != null ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      bookings: (json['bookings'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList(),
      rating: double.tryParse(json['rating']?.toString() ?? ''),
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'pricePerDay': pricePerDay,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'city': city,
      'status': status,
      'isApproved': isApproved,
      'availableFrom': availableFrom.toIso8601String(),
      'availableTo': availableTo.toIso8601String(),
      'images': images,
      if (owner != null) 'owner': owner!.toJson(),
      if (category != null) 'category': category!.toJson(),
      if (bookings != null) 'bookings': bookings,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id, userId, categoryId, title, description, pricePerDay, location,
        latitude, longitude, country, city, status, isApproved, availableFrom,
        availableTo, images, owner, category, rating, reviewCount, createdAt
      ];
}
