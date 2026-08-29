import 'package:intl/intl.dart';

enum MessageStatus { sending, sent, error }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final bool read;
  final bool deletedForAll;
  final List<String> deletedForSelf;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? updatedAt;
  final SenderInfo? sender;
  final MessageModel? replyTo;
  final String? replyToId;
  final Map<String, String> reactions; // Added for Feature 4: userId -> emoji
  final MessageStatus status;
  final String formattedTime;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.read,
    this.deletedForAll = false,
    this.deletedForSelf = const [],
    required this.createdAt,
    this.editedAt,
    this.updatedAt,
    this.sender,
    this.replyTo,
    this.replyToId,
    this.reactions = const {},
    this.status = MessageStatus.sent,
    String? formattedTime,
  }) : formattedTime = formattedTime ?? DateFormat.jm().format(createdAt.toLocal());

  bool get isEdited => editedAt != null;

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is int) return DateTime.fromMillisecondsSinceEpoch(dateVal);
    if (dateVal is String) {
      return DateTime.tryParse(dateVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final dt = _parseDate(json['createdAt']);
    final edt = json['editedAt'] != null ? _parseDate(json['editedAt']) : null;
    final udt = json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null;
    
    return MessageModel(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      read: json['read'] as bool? ?? false,
      deletedForAll: json['deletedForAll'] as bool? ?? false,
      deletedForSelf: (json['deletedForSelf'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: dt,
      editedAt: edt,
      updatedAt: udt,
      sender: json['sender'] != null
          ? SenderInfo.fromJson(Map<String, dynamic>.from(json['sender'] as Map))
          : null,
      replyTo: json['replyTo'] != null
          ? MessageModel.fromJson({
              ...Map<String, dynamic>.from(json['replyTo'] as Map),
              'chatId': json['chatId'] ?? '',
              'senderId': (json['replyTo'] as Map)['senderId'] ?? (json['replyTo'] as Map)['sender']?['id'] ?? '',
              'createdAt': (json['replyTo'] as Map)['createdAt'] ?? json['createdAt'],
              'read': true,
            })
          : null,
      replyToId: json['replyToId'] as String?,
      reactions: (json['reactions'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ?? {},
      status: MessageStatus.sent,
      formattedTime: DateFormat.jm().format(dt.toLocal()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'read': read,
      'deletedForAll': deletedForAll,
      'deletedForSelf': deletedForSelf,
      'createdAt': createdAt.toIso8601String(),
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (sender != null) 'sender': sender!.toJson(),
      if (replyTo != null) 'replyTo': replyTo!.toJson(),
      if (replyToId != null) 'replyToId': replyToId,
      'reactions': reactions,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? imageUrl,
    bool? read,
    bool? deletedForAll,
    List<String>? deletedForSelf,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? updatedAt,
    SenderInfo? sender,
    MessageModel? replyTo,
    String? replyToId,
    Map<String, String>? reactions,
    MessageStatus? status,
    String? formattedTime,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      read: read ?? this.read,
      deletedForAll: deletedForAll ?? this.deletedForAll,
      deletedForSelf: deletedForSelf ?? this.deletedForSelf,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      replyTo: replyTo ?? this.replyTo,
      replyToId: replyToId ?? this.replyToId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      formattedTime: formattedTime ?? this.formattedTime,
    );
  }
}

class SenderInfo {
  final String id;
  final String name;
  final String? avatarUrl;

  SenderInfo({required this.id, required this.name, this.avatarUrl});

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }
}
