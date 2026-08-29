import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final String? chatId;
  final List<MessageModel> messages;
  final List<ConversationModel> conversations;
  final Set<String> typingUsers;
  final MessageModel? editingMessage; // Added for Feature 2
  final MessageModel? replyingTo;    // Added for Feature 3
  final bool hasReachedMax;          // Added for Pagination
  final bool isLoadingMore;          // Added for Pagination
  final String? error;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chatId,
    this.messages = const [],
    this.conversations = const [],
    this.typingUsers = const {},
    this.editingMessage,
    this.replyingTo,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get isTyping => typingUsers.isNotEmpty;

  ChatState copyWith({
    ChatStatus? status,
    String? chatId,
    List<MessageModel>? messages,
    List<ConversationModel>? conversations,
    Set<String>? typingUsers,
    MessageModel? editingMessage,
    MessageModel? replyingTo,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool clearEditing = false,
    bool clearReplying = false,
    String? error,
  }) {
    return ChatState(
      status: status ?? this.status,
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      typingUsers: typingUsers ?? this.typingUsers,
      editingMessage: clearEditing ? null : (editingMessage ?? this.editingMessage),
      replyingTo: clearReplying ? null : (replyingTo ?? this.replyingTo),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    chatId, 
    messages, 
    conversations, 
    typingUsers, 
    editingMessage, 
    replyingTo, 
    hasReachedMax,
    isLoadingMore,
    error
  ];
}
