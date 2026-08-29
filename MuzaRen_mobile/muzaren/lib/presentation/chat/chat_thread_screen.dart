import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';
import '../../data/models/message_model.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatThreadScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final String? recipientAvatar;
  final String? listingId;
  final String? listingTitle;
  final double? listingPrice;
  final String? listingImageUrl;

  const ChatThreadScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    this.recipientAvatar,
    this.listingId,
    this.listingTitle,
    this.listingPrice,
    this.listingImageUrl,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  late ChatBloc _chatBloc;
  String? _currentUserId;
  
  String? _hydratedName;
  String? _hydratedAvatar;
  String? _hydratedListingId;
  String? _hydratedListingTitle;
  double? _hydratedListingPrice;
  String? _hydratedListingImageUrl;

  bool _isTypingInternally = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatBloc = context.read<ChatBloc>();
    
    _hydratedName = widget.recipientName;
    _hydratedAvatar = widget.recipientAvatar;
    _hydratedListingId = widget.listingId;
    _hydratedListingTitle = widget.listingTitle;
    _hydratedListingPrice = widget.listingPrice;
    _hydratedListingImageUrl = widget.listingImageUrl;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
    }

    _chatBloc.add(JoinChat(widget.chatId));
    _chatBloc.add(MarkChatRead(widget.chatId));

    _scrollController.addListener(_onScroll);

    _attemptHydration(_chatBloc.state);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _chatBloc.add(LoadMoreMessages(widget.chatId));
    }
  }

  void _attemptHydration(ChatState state) {
    if ((_hydratedName == null || _hydratedName == 'User' || _hydratedName!.isEmpty) && state.conversations.isNotEmpty) {
      try {
        final conv = state.conversations.firstWhere((c) => c.id == widget.chatId);
        setState(() {
          _hydratedName = conv.otherUserName;
          _hydratedAvatar = conv.otherUserAvatarUrl;
          _hydratedListingId = conv.listingId;
          _hydratedListingTitle = conv.listingTitle;
          _hydratedListingPrice = conv.listingPrice;
          _hydratedListingImageUrl = conv.listingImageUrl;
        });
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatBloc.add(JoinChat(widget.chatId));
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _chatBloc.add(LeaveChat(widget.chatId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _scrollController.dispose();
    _chatBloc.add(LeaveChat(widget.chatId));
    super.dispose();
  }

  void _onSend(String text, {String? replyToId}) {
    if (_currentUserId == null) return;
    
    final editMsg = _chatBloc.state.editingMessage;
    if (editMsg != null) {
      _chatBloc.add(EditMessage(
        messageId: editMsg.id,
        newText: text,
      ));
    } else {
      _isTypingInternally = false;
      _chatBloc.add(SendTextMessage(
        chatId: widget.chatId,
        text: text,
        senderId: _currentUserId!,
        replyToId: replyToId,
      ));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    
    final ioFile = File(file.path);
    final sizeInBytes = await ioFile.length();
    const maxSizeInBytes = 8 * 1024 * 1024; // 8MB

    if (sizeInBytes > maxSizeInBytes) {
      if (mounted) {
        final fileSizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_size_select_large, color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Image Too Large',
                      style: TextStyle(fontFamily: 'Sora', fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your image is $fileSizeMB MB but the maximum allowed size is 8 MB.',
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
                const SizedBox(height: 14),
                const Text('Tips:', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildTipRow(Icons.crop, 'Crop or resize your photo'),
                _buildTipRow(Icons.photo_library_outlined, 'Pick a different photo'),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Got it, I'll pick another",
                      style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    _chatBloc.add(SendImageMessage(
      chatId: widget.chatId,
      imageFile: ioFile,
      replyToId: _chatBloc.state.replyingTo?.id,
    ));
  }

  void _onTextChanged(String value) {
    if (value.isNotEmpty && !_isTypingInternally && _chatBloc.state.editingMessage == null) {
      _isTypingInternally = true;
      _chatBloc.add(SendTypingEvent(widget.chatId));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTypingInternally) {
        _isTypingInternally = false;
        _chatBloc.add(SendStopTypingEvent(widget.chatId));
      }
    });
  }

  void _handleDeleteMessage(MessageModel msg, String deleteType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(deleteType == 'for_me' ? 'Delete for Me?' : 'Delete for Everyone?', style: const TextStyle(fontFamily: 'Sora')),
        content: Text(deleteType == 'for_me' 
            ? 'This message will be removed from your view only.' 
            : 'This message will be removed for all participants. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatBloc.add(DeleteMessage(messageId: msg.id, deleteType: deleteType));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Conversation?', 
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete your conversation with $_hydratedName? This history will be hidden for you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _chatBloc.add(DeleteConversation(widget.chatId));
              context.pop(); // Go back to list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessageInfo(MessageModel msg) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(msg.createdAt.toLocal());
    final timeStr = DateFormat('hh:mm:ss a').format(msg.createdAt.toLocal());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Message Details', style: TextStyle(fontFamily: 'Sora', fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem(Icons.calendar_today_outlined, 'Sent on', dateStr),
            const SizedBox(height: 12),
            _detailItem(Icons.access_time, 'Sent at', timeStr),
            const SizedBox(height: 12),
            _detailItem(
              msg.read ? Icons.done_all : Icons.done,
              'Status',
              msg.read ? 'Read' : 'Delivered',
              color: msg.read ? AppColors.primary : const Color(0xFF9CA3AF),
            ),
            if (msg.editedAt != null) ...[
              const SizedBox(height: 12),
              _detailItem(Icons.edit_outlined, 'Modified', 'Message has been edited'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final messages = state.messages;
                final typingUsers = state.typingUsers;

                if (state.status == ChatStatus.loading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (messages.isEmpty && state.status == ChatStatus.loaded) {
                  return Column(
                    children: [
                      if (_hydratedListingTitle != null) _buildListingPreviewCard(),
                      Expanded(child: _buildEmptyConversation()),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: messages.length + (typingUsers.isNotEmpty ? 1 : 0) + (state.isLoadingMore ? 1 : 0) + 1,
                  itemBuilder: (context, index) {
                    // 1. Listing Preview Card at the very top (last item in builder)
                    if (index == messages.length + (typingUsers.isNotEmpty ? 1 : 0) + (state.isLoadingMore ? 1 : 0)) {
                      return _hydratedListingTitle != null ? _buildListingPreviewCard() : const SizedBox.shrink();
                    }
                    
                    // 2. Loading More Indicator
                    if (state.isLoadingMore && index == messages.length + (typingUsers.isNotEmpty ? 1 : 0)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                      );
                    }

                    if (typingUsers.isNotEmpty && index == 0) return _buildTypingIndicator(typingUsers);
                    final messageIndex = typingUsers.isNotEmpty ? index - 1 : index;
                    final msg = messages[messages.length - 1 - messageIndex];
                    
                    return MessageBubble(
                      key: ValueKey(msg.id),
                      message: msg, 
                      isMe: msg.senderId == _currentUserId,
                      onEdit: () => _chatBloc.add(StartEditingMessage(msg)),
                      onReply: () => _chatBloc.add(StartReplyingToMessage(msg)),
                      onReact: (emoji) => _chatBloc.add(ReactToMessage(messageId: msg.id, emoji: emoji)),
                      onDelete: (type) => _handleDeleteMessage(msg, type),
                      onInfo: () => _showMessageInfo(msg),
                    );
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) => 
                prev.editingMessage != curr.editingMessage || 
                prev.replyingTo != curr.replyingTo,
            builder: (context, state) {
              return ChatInputBar(
                onSend: (text, {replyToId}) => _onSend(text, replyToId: replyToId),
                onPickImage: _pickAndSendImage,
                onTextChanged: _onTextChanged,
                initialText: state.editingMessage?.text,
                replyingTo: state.replyingTo,
                onCancelEdit: () => _chatBloc.add(CancelEditing()),
                onCancelReply: () => _chatBloc.add(CancelReplying()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListingPreviewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _hydratedListingImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _hydratedListingImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(width: 60, height: 60, color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_outlined, size: 24, color: Color(0xFF9CA3AF))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_hydratedListingTitle ?? 'Listing', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(
                    _hydratedListingPrice != null 
                        ? () {
                            final locState = context.read<LocationBloc>().state;
                            final symbol = locState is LocationDetected ? locState.currencySymbol : r'$';
                            return '$symbol${_hydratedListingPrice!.toStringAsFixed(0)} / day';
                          }()
                        : 'Contact for price',
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 24, indent: 8, endIndent: 8, color: Color(0xFFF3F4F6)),
            TextButton(
              onPressed: () {
                if (_hydratedListingId != null) {
                  context.push('/listing/$_hydratedListingId');
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View', style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _hydratedAvatar != null
                  ? CachedNetworkImageProvider(_hydratedAvatar!, maxWidth: 100, maxHeight: 100)
                  : null,
              child: _hydratedAvatar == null
                  ? Text((_hydratedName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_hydratedName ?? 'Loading...', style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600)),
                  if (_hydratedListingTitle != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(_hydratedListingTitle!.toUpperCase(),
                          style: const TextStyle(fontFamily: 'Sora', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteConversation();
              if (value == 'info') {}
            },
            icon: const Icon(Icons.more_vert, size: 22),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('View Profile')],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Delete Chat', style: TextStyle(color: Colors.redAccent))],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Set<String> users) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildDot(0), const SizedBox(width: 4), _buildDot(150), const SizedBox(width: 4), _buildDot(300)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.3 + (value * 0.7)), shape: BoxShape.circle),
        );
      },
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('Say hello to ${widget.recipientName}!', style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          const Text('Ask about the listing or make an offer.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF4B5563))),
          ),
        ],
      ),
    );
  }
}
