import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

// ─── CONNECTION LIFECYCLE ────────────────────────────
class ConnectSocket extends ChatEvent {}

class DisconnectSocket extends ChatEvent {}

// ─── CONVERSATION LIST ───────────────────────────────
class LoadConversations extends ChatEvent {}

// ─── CHAT THREAD ─────────────────────────────────────
class JoinChat extends ChatEvent {
  final String chatId;
  const JoinChat(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class LeaveChat extends ChatEvent {
  final String chatId;
  const LeaveChat(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class SendTextMessage extends ChatEvent {
  final String chatId;
  final String text;
  final String senderId;
  final String? replyToId;
  const SendTextMessage({
    required this.chatId, 
    required this.text, 
    required this.senderId,
    this.replyToId,
  });
  @override
  List<Object?> get props => [chatId, text, senderId, replyToId];
}

class SendImageMessage extends ChatEvent {
  final String chatId;
  final File imageFile;
  final String? replyToId;
  const SendImageMessage({required this.chatId, required this.imageFile, this.replyToId});
  @override
  List<Object?> get props => [chatId, imageFile, replyToId];
}

// ─── MARK READ ───────────────────────────────────────
class MarkChatRead extends ChatEvent {
  final String chatId;
  const MarkChatRead(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

// ─── TYPING ──────────────────────────────────────────
class SendTypingEvent extends ChatEvent {
  final String chatId;
  const SendTypingEvent(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class SendStopTypingEvent extends ChatEvent {
  final String chatId;
  const SendStopTypingEvent(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

// ─── CRUD & REACTIONS (Features 1, 2, 4) ─────────────
class EditMessage extends ChatEvent {
  final String messageId;
  final String newText;
  const EditMessage({required this.messageId, required this.newText});
  @override
  List<Object?> get props => [messageId, newText];
}

class DeleteMessage extends ChatEvent {
  final String messageId;
  final String deleteType;
  const DeleteMessage({required this.messageId, required this.deleteType});
  @override
  List<Object?> get props => [messageId, deleteType];
}

class ReactToMessage extends ChatEvent {
  final String messageId;
  final String emoji;
  const ReactToMessage({required this.messageId, required this.emoji});
  @override
  List<Object?> get props => [messageId, emoji];
}

class DeleteConversation extends ChatEvent {
  final String chatId;
  const DeleteConversation(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

// ─── SOCKET PUSH EVENTS (internal) ───────────────────
class NewMessageReceived extends ChatEvent {
  final MessageModel message;
  const NewMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class MessageConfirmed extends ChatEvent {
  final MessageModel message;
  final String? tempId;
  const MessageConfirmed(this.message, {this.tempId});
  @override
  List<Object?> get props => [message, tempId];
}

class MessageEditedReceived extends ChatEvent {
  final String chatId;
  final String messageId;
  final String newText;
  final DateTime editedAt;
  const MessageEditedReceived({
    required this.chatId,
    required this.messageId, 
    required this.newText, 
    required this.editedAt
  });
  @override
  List<Object?> get props => [chatId, messageId, newText, editedAt];
}

class MessageDeletedReceived extends ChatEvent {
  final String chatId;
  final String messageId;
  final String deleteType;
  const MessageDeletedReceived({required this.chatId, required this.messageId, required this.deleteType});
  @override
  List<Object?> get props => [chatId, messageId, deleteType];
}

class MessageReactedReceived extends ChatEvent {
  final String chatId;
  final String messageId;
  final String userId;
  final String emoji;
  final Map<String, String> reactions;
  const MessageReactedReceived({
    required this.chatId,
    required this.messageId, 
    required this.userId, 
    required this.emoji,
    required this.reactions,
  });
  @override
  List<Object?> get props => [chatId, messageId, userId, emoji, reactions];
}

class ChatDeletedReceived extends ChatEvent {
  final String chatId;
  const ChatDeletedReceived(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class ChatHistoryLoaded extends ChatEvent {
  final String chatId;
  final List<MessageModel> messages;
  const ChatHistoryLoaded({required this.chatId, required this.messages});
  @override
  List<Object?> get props => [chatId, messages];
}

class LoadMoreMessages extends ChatEvent {
  final String chatId;
  const LoadMoreMessages(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class MoreMessagesReceived extends ChatEvent {
  final String chatId;
  final List<MessageModel> messages;
  const MoreMessagesReceived({required this.chatId, required this.messages});
  @override
  List<Object?> get props => [chatId, messages];
}

class MessagesReadReceived extends ChatEvent {
  final String chatId;
  final String readBy;
  const MessagesReadReceived({required this.chatId, required this.readBy});
  @override
  List<Object?> get props => [chatId, readBy];
}

class UserTypingReceived extends ChatEvent {
  final String userId;
  final String chatId;
  const UserTypingReceived({required this.userId, required this.chatId});
  @override
  List<Object?> get props => [userId, chatId];
}

class UserStopTypingReceived extends ChatEvent {
  final String userId;
  final String chatId;
  const UserStopTypingReceived({required this.userId, required this.chatId});
  @override
  List<Object?> get props => [userId, chatId];
}

class ConversationsDataLoaded extends ChatEvent {
  final List<ConversationModel> conversations;
  const ConversationsDataLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

// ─── UI STATE EVENTS ─────────────────────────────────
class StartEditingMessage extends ChatEvent {
  final MessageModel message;
  const StartEditingMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class CancelEditing extends ChatEvent {}

class StartReplyingToMessage extends ChatEvent {
  final MessageModel message;
  const StartReplyingToMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class CancelReplying extends ChatEvent {}
