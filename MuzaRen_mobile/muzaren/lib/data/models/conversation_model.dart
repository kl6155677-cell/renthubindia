class ConversationModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final double? listingPrice; // Added for Feature 7
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final bool otherUserVerified;
  final String? lastMessageText;
  final String? lastMessageImageUrl;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    this.listingPrice,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    required this.otherUserVerified,
    this.lastMessageText,
    this.lastMessageImageUrl,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      listingTitle: json['listingTitle'] as String? ?? '',
      listingImageUrl: json['listingImageUrl'] as String?,
      listingPrice: json['listingPrice'] != null 
          ? double.tryParse(json['listingPrice'].toString()) 
          : null,
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? '',
      otherUserAvatarUrl: json['otherUserAvatarUrl'] as String?,
      otherUserVerified: json['otherUserVerified'] as bool? ?? false,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageImageUrl: json['lastMessageImageUrl'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  ConversationModel copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatarUrl,
    bool? otherUserVerified,
    String? lastMessageText,
    String? lastMessageImageUrl,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      listingPrice: listingPrice ?? this.listingPrice,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      otherUserVerified: otherUserVerified ?? this.otherUserVerified,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageImageUrl: lastMessageImageUrl ?? this.lastMessageImageUrl,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'listingPrice': listingPrice,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatarUrl': otherUserAvatarUrl,
      'otherUserVerified': otherUserVerified,
      'lastMessageText': lastMessageText,
      'lastMessageImageUrl': lastMessageImageUrl,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}
