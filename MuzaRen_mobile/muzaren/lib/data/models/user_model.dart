import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String verificationStatus;
  final bool isBlocked;
  final String? country;
  final String? city;
  final String? currency;
  final double rating;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.verificationStatus,
    required this.isBlocked,
    this.country,
    this.city,
    this.currency,
    required this.rating,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'USER',
      verificationStatus: json['verificationStatus'] as String? ?? 'UNVERIFIED',
      isBlocked: json['isBlocked'] as bool? ?? false,
      country: json['country'] as String?,
      city: json['city'] as String?,
      currency: json['currency'] as String?,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'verificationStatus': verificationStatus,
      'isBlocked': isBlocked,
      'country': country,
      'city': city,
      'currency': currency,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, avatarUrl, role, verificationStatus, 
        isBlocked, country, city, currency, rating, createdAt
      ];
}
