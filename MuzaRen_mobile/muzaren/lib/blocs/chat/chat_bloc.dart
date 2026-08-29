import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/websocket_chat_service.dart';
import '../../data/services/local_cache_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepo;
  final WebSocketChatService _chatService = WebSocketChatService();
  final LocalCacheService _cache = LocalCacheService();

  // In-memory message cache per chatId (survives within session)
  final Map<String, List<MessageModel>> _messagesCache = {};
  String? _activeChatId;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepo = chatRepository,
        super(const ChatState()) {
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<LoadConversations>(_onLoadConversations);
    on<JoinChat>(_onJoinChat);
    on<LeaveChat>(_onLeaveChat);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MarkChatRead>(_onMarkChatRead);
    on<SendTypingEvent>(_onSendTyping);
    on<SendStopTypingEvent>(_onSendStopTyping);
    
    // CRUD & Features (1, 2, 3, 4)
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<ReactToMessage>(_onReactToMessage);
    on<DeleteConversation>(_onDeleteConversation);
    on<StartEditingMessage>(_onStartEditingMessage);
    on<CancelEditing>(_onCancelEditing);
    on<StartReplyingToMessage>(_onStartReplyingToMessage);
    on<CancelReplying>(_onCancelReplying);

    // Internal socket-driven events
    on<ChatHistoryLoaded>(_onChatHistoryLoaded);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageConfirmed>(_onMessageConfirmed);
    on<MessageEditedReceived>(_onMessageEditedReceived);
    on<MessageDeletedReceived>(_onMessageDeletedReceived);
    on<MessageReactedReceived>(_onMessageReactedReceived);
    on<ChatDeletedReceived>(_onChatDeletedReceived);
    on<MessagesReadReceived>(_onMessagesReadReceived);
    on<UserTypingReceived>(_onUserTypingReceived);
    on<UserStopTypingReceived>(_onUserStopTypingReceived);
    on<ConversationsDataLoaded>(_onConversationsDataLoaded);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<MoreMessagesReceived>(_onMoreMessagesReceived);
  }

  // ─── CONNECT ─────────────────────────────────────────
  Future<void> _onConnectSocket(
      ConnectSocket event, Emitter<ChatState> emit) async {
    await _chatService.connect();
    _registerSocketListeners();
  }

  void _registerSocketListeners() {
    _chatService.removeListeners();
    
    _chatService.onChatHistory((data) {
      final messages = (data['messages'] as List)
          .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      add(ChatHistoryLoaded(chatId: data['chatId'] as String, messages: messages));
    });

    _chatService.onMoreMessagesLoaded((data) {
      final messages = (data['messages'] as List)
          .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      add(MoreMessagesReceived(chatId: data['chatId'] as String, messages: messages));
    });

    _socketListenerHelper();
  }

  void _socketListenerHelper() {
    _chatService.onNewMessage((data) {
      try {
        add(NewMessageReceived(
            MessageModel.fromJson(Map<String, dynamic>.from(data['message'] as Map))));
      } catch (e) {
        // Handle parsing error quietly or send to crashlytics
      }
    });

    _chatService.onMessageSent((data) {
      try {
        add(MessageConfirmed(
            MessageModel.fromJson(Map<String, dynamic>.from(data['message'] as Map)),
            tempId: data['tempId'] as String?,
        ));
      } catch (e) {
        // Handle parsing error quietly or send to crashlytics
      }
    });

    _chatService.onMessageEdited((data) {
      add(MessageEditedReceived(
          chatId: data['chatId'] as String,
          messageId: data['messageId'] as String,
          newText: data['newText'] as String,
          editedAt: DateTime.parse(data['editedAt'] as String)));
    });

    _chatService.onMessageDeleted((data) {
      add(MessageDeletedReceived(
          chatId: data['chatId'] as String,
          messageId: data['messageId'] as String,
          deleteType: data['deleteType'] as String));
    });

    _chatService.onMessageReacted((data) {
      add(MessageReactedReceived(
        chatId: data['chatId'] as String,
        messageId: data['messageId'] as String,
        userId: data['userId'] as String,
        emoji: data['emoji'] as String,
        reactions: Map<String, String>.from(data['reactions'] as Map),
      ));
    });

    _chatService.onChatDeleted((data) {
      add(ChatDeletedReceived(data['chatId'] as String));
    });

    _chatService.onMessagesRead((data) {
      add(MessagesReadReceived(
          chatId: data['chatId'] as String, readBy: data['readBy'] as String));
    });

    _chatService.onUserTyping((data) {
      add(UserTypingReceived(
          userId: data['userId'] as String, chatId: data['chatId'] as String));
    });

    _chatService.onStopTyping((data) {
      add(UserStopTypingReceived(
          userId: data['userId'] as String, chatId: data['chatId'] as String));
    });
  }

  // ─── DISCONNECT ──────────────────────────────────────
  void _onDisconnectSocket(
      DisconnectSocket event, Emitter<ChatState> emit) {
    _chatService.disconnect();
    _messagesCache.clear();
    emit(const ChatState());
  }

  // ─── ACTIONS (CRUD & Features) ────────────────────────
  
  void _onStartEditingMessage(StartEditingMessage event, Emitter<ChatState> emit) {
    emit(state.copyWith(editingMessage: event.message, clearReplying: true));
  }

  void _onCancelEditing(CancelEditing event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearEditing: true));
  }

  void _onStartReplyingToMessage(StartReplyingToMessage event, Emitter<ChatState> emit) {
    emit(state.copyWith(replyingTo: event.message, clearEditing: true));
  }

  void _onCancelReplying(CancelReplying event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearReplying: true));
  }

  Future<void> _onEditMessage(EditMessage event, Emitter<ChatState> emit) async {
    if (_activeChatId == null) return;
    final chatId = _activeChatId!;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      existing[index] = existing[index].copyWith(
        text: event.newText, 
        editedAt: DateTime.now()
      );
      _messagesCache[chatId] = existing;
      emit(state.copyWith(messages: existing, clearEditing: true));
    }
    _chatService.editMessage(event.messageId, event.newText);
  }

  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    if (_activeChatId == null) return;
    final chatId = _activeChatId!;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    
    if (index != -1) {
      if (event.deleteType == 'for_me') {
        existing.removeAt(index);
      } else {
        existing[index] = existing[index].copyWith(
          deletedForAll: true,
          text: null,
          imageUrl: null,
        );
      }
      _messagesCache[chatId] = existing;
      emit(state.copyWith(messages: existing));
    }
    _chatService.deleteMessage(event.messageId, event.deleteType);
    // Wait, check WebSocketChatService signature. pos 1: messageId, pos 2: deleteType. Correct.
  }

  void _onReactToMessage(ReactToMessage event, Emitter<ChatState> emit) {
    if (_activeChatId == null) return;
    final chatId = _activeChatId!;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      // Trigger the socket emission; the updated state will be handled 
      // when the server broadcasts the confirm/update event.
      _chatService.reactToMessage(event.messageId, event.emoji);
    }
  }

  Future<void> _onDeleteConversation(DeleteConversation event, Emitter<ChatState> emit) async {
    final convos = List<ConversationModel>.from(state.conversations);
    convos.removeWhere((c) => c.id == event.chatId);
    emit(state.copyWith(conversations: convos));
    _chatService.deleteChat(event.chatId);
    _messagesCache.remove(event.chatId);
    await _cache.saveConversations(convos);
  }

  // ─── SOCKET UPDATES (Received) ──────────────────────
  
  void _onMessageEditedReceived(MessageEditedReceived event, Emitter<ChatState> emit) {
    final chatId = event.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      existing[index] = existing[index].copyWith(
        text: event.newText,
        editedAt: event.editedAt
      );
      _messagesCache[chatId] = existing;
      if (_activeChatId == chatId) {
        emit(state.copyWith(messages: existing));
      }
    }
  }

  void _onMessageReactedReceived(MessageReactedReceived event, Emitter<ChatState> emit) {
    final chatId = event.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      existing[index] = existing[index].copyWith(reactions: event.reactions);
      _messagesCache[chatId] = existing;
      if (_activeChatId == chatId) {
        emit(state.copyWith(messages: existing));
      }
    }
  }

  void _onMessageDeletedReceived(MessageDeletedReceived event, Emitter<ChatState> emit) {
    final chatId = event.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    final index = existing.indexWhere((m) => m.id == event.messageId);
    
    if (index != -1) {
      if (event.deleteType == 'for_me') {
        existing.removeAt(index);
      } else {
        existing[index] = existing[index].copyWith(
          deletedForAll: true,
          text: null,
          imageUrl: null,
        );
      }
      _messagesCache[chatId] = existing;
      if (_activeChatId == chatId) {
        emit(state.copyWith(messages: existing));
      }
    }
  }

  void _onChatDeletedReceived(ChatDeletedReceived event, Emitter<ChatState> emit) {
    final convos = List<ConversationModel>.from(state.conversations);
    convos.removeWhere((c) => c.id == event.chatId);
    emit(state.copyWith(conversations: convos));
    _messagesCache.remove(event.chatId);
  }

  // ─── PAGINATION ─────────────────────────────────────
  
  void _onLoadMoreMessages(LoadMoreMessages event, Emitter<ChatState> emit) {
    if (state.hasReachedMax || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    _chatService.loadMoreMessages(event.chatId, _messagesCache[event.chatId]?.length ?? 0);
  }

  Future<void> _onMoreMessagesReceived(MoreMessagesReceived event, Emitter<ChatState> emit) async {
    final chatId = event.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    
    if (event.messages.isEmpty) {
      emit(state.copyWith(isLoadingMore: false, hasReachedMax: true));
      return;
    }

    // Prepend new messages (older) to the list
    final updated = [...event.messages, ...existing];
    _messagesCache[chatId] = updated;

    if (_activeChatId == chatId) {
      emit(state.copyWith(
        messages: updated, 
        isLoadingMore: false, 
        hasReachedMax: event.messages.length < 50
      ));
    }
    await _saveMessagesTruncated(chatId, updated);
  }

  Future<void> _saveMessagesTruncated(String chatId, List<MessageModel> messages) async {
    // Only keep the most recent 50 messages in local storage as requested
    final toSave = messages.length > 50 
        ? messages.sublist(messages.length - 50) 
        : messages;
    await _cache.saveMessages(chatId, toSave);
  }

  // ─── REST OF THE BLOC LOGIC ─────────────────────────

  Future<void> _onLoadConversations(LoadConversations event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    final cached = await _cache.getCachedConversations();
    if (cached != null && cached.isNotEmpty) {
      emit(state.copyWith(status: ChatStatus.loaded, conversations: cached));
    }
    try {
      final conversations = await _chatRepo.getConversations();
      emit(state.copyWith(status: ChatStatus.loaded, conversations: conversations));
      await _cache.saveConversations(conversations);
    } catch (e) {
      if (state.conversations.isEmpty) {
        emit(state.copyWith(status: ChatStatus.error, error: e.toString()));
      }
    }
  }

  void _onConversationsDataLoaded(ConversationsDataLoaded event, Emitter<ChatState> emit) {
    emit(state.copyWith(conversations: event.conversations));
  }

  Future<void> _onJoinChat(JoinChat event, Emitter<ChatState> emit) async {
    _activeChatId = event.chatId;
    
    // 1. Try to show messages instantly from in-memory or Hive cache
    final inMemory = _messagesCache[event.chatId];
    if (inMemory != null && inMemory.isNotEmpty) {
      // Instant — already in RAM
      emit(state.copyWith(
        chatId: event.chatId, 
        status: ChatStatus.loaded, 
        messages: inMemory,
        hasReachedMax: false,
        isLoadingMore: false,
      ));
    } else {
      // Try Hive (disk) cache
      final persisted = await _cache.getCachedMessages(event.chatId);
      if (persisted != null && persisted.isNotEmpty) {
        _messagesCache[event.chatId] = persisted;
        emit(state.copyWith(
          chatId: event.chatId, 
          status: ChatStatus.loaded, 
          messages: persisted,
          hasReachedMax: false,
          isLoadingMore: false,
        ));
      } else {
        // No cache at all — show loading spinner
        emit(state.copyWith(
          status: ChatStatus.loading, 
          chatId: event.chatId, 
          messages: [],
          hasReachedMax: false,
          isLoadingMore: false,
        ));
      }
    }

    // 2. Always join the server room to get fresh data in the background
    _chatService.joinChat(event.chatId);
    add(MarkChatRead(event.chatId));
  }

  void _onLeaveChat(LeaveChat event, Emitter<ChatState> emit) {
    _chatService.leaveChat(event.chatId);
    _activeChatId = null;
    emit(state.copyWith(chatId: null, messages: [], typingUsers: {}, clearEditing: true, clearReplying: true));
  }

  void _onSendTextMessage(SendTextMessage event, Emitter<ChatState> emit) {
    final text = event.text.trim();
    if (text.isEmpty) return;
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      chatId: event.chatId,
      senderId: event.senderId,
      text: text,
      read: false,
      replyToId: event.replyToId,
      replyTo: state.replyingTo,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    final existing = List<MessageModel>.from(_messagesCache[event.chatId] ?? []);
    existing.add(optimisticMessage);
    _messagesCache[event.chatId] = existing;
    if (_activeChatId == event.chatId) {
      emit(state.copyWith(messages: existing, clearReplying: true));
    }
    _updateConversationPreview(event.chatId, event.text, optimisticMessage.createdAt, 0);
    _chatService.sendMessage(event.chatId, event.text, tempId, replyToId: event.replyToId);
  }

  void _updateConversationPreview(String chatId, String? text, DateTime at, int unreadDelta) {
    final convos = List<ConversationModel>.from(state.conversations);
    final index = convos.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final updated = convos[index].copyWith(
        lastMessageText: text,
        lastMessageAt: at,
        unreadCount: unreadDelta < -500 ? 0 : (convos[index].unreadCount + unreadDelta),
      );
      convos[index] = updated;
      convos.sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));
      add(ConversationsDataLoaded(convos));
    }
  }

  Future<void> _onSendImageMessage(SendImageMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatRepo.uploadImage(event.chatId, event.imageFile, replyToId: event.replyToId);
      emit(state.copyWith(clearReplying: true));
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.error, error: 'Failed to upload image: $e'));
    }
  }

  void _onMarkChatRead(MarkChatRead event, Emitter<ChatState> emit) {
    _chatService.markRead(event.chatId);
    final convos = List<ConversationModel>.from(state.conversations);
    final index = convos.indexWhere((c) => c.id == event.chatId);
    if (index != -1 && convos[index].unreadCount > 0) {
      convos[index] = convos[index].copyWith(unreadCount: 0);
      add(ConversationsDataLoaded(convos));
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) {
    _chatService.sendTyping(event.chatId);
  }

  void _onSendStopTyping(SendStopTypingEvent event, Emitter<ChatState> emit) {
    _chatService.sendStopTyping(event.chatId);
  }

  Future<void> _onChatHistoryLoaded(ChatHistoryLoaded event, Emitter<ChatState> emit) async {
    _messagesCache[event.chatId] = event.messages;
    if (_activeChatId == event.chatId) {
      emit(state.copyWith(
        status: ChatStatus.loaded, 
        messages: event.messages,
        hasReachedMax: event.messages.length < 50,
      ));
    }
    await _saveMessagesTruncated(event.chatId, event.messages);
  }

  Future<void> _onNewMessageReceived(NewMessageReceived event, Emitter<ChatState> emit) async {
    final chatId = event.message.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    if (!existing.any((m) => m.id == event.message.id)) {
      existing.add(event.message);
    }
    _messagesCache[chatId] = existing;
    if (_activeChatId == chatId) {
      emit(state.copyWith(messages: existing));
      _chatService.markRead(chatId);
      _updateConversationPreview(chatId, event.message.text, event.message.createdAt, -999);
    } else {
      _updateConversationPreview(chatId, event.message.text, event.message.createdAt, 1);
    }
    await _saveMessagesTruncated(chatId, existing);
  }

  Future<void> _onMessageConfirmed(MessageConfirmed event, Emitter<ChatState> emit) async {
    print('✅ _onMessageConfirmed called — tempId: ${event.tempId}, msgId: ${event.message.id}, chatId: ${event.message.chatId}');
    final chatId = event.message.chatId;
    final existing = List<MessageModel>.from(_messagesCache[chatId] ?? []);
    
    print('   Cache has ${existing.length} messages for chatId=$chatId');
    print('   Temp messages: ${existing.where((m) => m.id.startsWith("temp_")).map((m) => m.id).toList()}');
    
    // Feature: Reliable matching using tempId, fallback to strict matching
    final tempIndex = existing.indexWhere((m) {
      if (event.tempId != null && m.id == event.tempId) return true;
      return m.id.startsWith('temp_') && m.text == event.message.text;
    });

    print('   tempIndex found: $tempIndex');

    if (tempIndex != -1) {
      existing[tempIndex] = event.message;
    } else if (!existing.any((m) => m.id == event.message.id)) {
      existing.add(event.message);
    }
    _messagesCache[chatId] = existing;
    if (_activeChatId == chatId) {
      emit(state.copyWith(messages: existing));
    }
    _updateConversationPreview(chatId, event.message.text, event.message.createdAt, 0);
    await _saveMessagesTruncated(chatId, existing);
  }

  void _onMessagesReadReceived(MessagesReadReceived event, Emitter<ChatState> emit) {
    final existing = _messagesCache[event.chatId];
    if (existing == null) return;
    final updated = existing.map((m) {
      if (m.senderId != event.readBy) return m.copyWith(read: true);
      return m;
    }).toList();
    _messagesCache[event.chatId] = updated;
    if (_activeChatId == event.chatId) {
      emit(state.copyWith(messages: updated));
    }
  }

  void _onUserTypingReceived(UserTypingReceived event, Emitter<ChatState> emit) {
    if (_activeChatId == event.chatId) {
      final newTypingUsers = Set<String>.from(state.typingUsers)..add(event.userId);
      emit(state.copyWith(typingUsers: newTypingUsers));
    }
  }

  void _onUserStopTypingReceived(UserStopTypingReceived event, Emitter<ChatState> emit) {
    if (_activeChatId == event.chatId) {
      final newTypingUsers = Set<String>.from(state.typingUsers)..remove(event.userId);
      emit(state.copyWith(typingUsers: newTypingUsers));
    }
  }

  @override
  Future<void> close() {
    _chatService.removeListeners();
    return super.close();
  }
}
