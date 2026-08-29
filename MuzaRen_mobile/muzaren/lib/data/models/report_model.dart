import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, reporterId, targetType, targetId, category, description, status, createdAt];
}
