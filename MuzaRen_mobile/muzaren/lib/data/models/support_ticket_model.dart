import 'package:equatable/equatable.dart';

class SupportTicketModel extends Equatable {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    this.adminReply,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      adminReply: json['adminReply'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'message': message,
      'status': status,
      'adminReply': adminReply,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, subject, message, status, adminReply, createdAt, updatedAt];
}
