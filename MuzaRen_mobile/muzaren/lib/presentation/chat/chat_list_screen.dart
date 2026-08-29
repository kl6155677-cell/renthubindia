import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../data/models/conversation_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadConversations());
  }

  Future<void> _onRefresh() async {
    context.read<ChatBloc>().add(LoadConversations());
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ───────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(Icons.search,
                            color: Color(0xFF9CA3AF), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── BODY ─────────────────────────────────────
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) => prev.conversations != curr.conversations || prev.status != curr.status,
                builder: (context, state) {
                  if (state.status == ChatStatus.loading && state.conversations.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  
                  if (state.status == ChatStatus.error && state.conversations.isEmpty) {
                    return _buildErrorState(state.error ?? 'Unknown error');
                  }

                  if (state.conversations.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          _buildEmptyState(),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.conversations.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 82,
                          color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, index) =>
                          _ChatTile(convo: state.conversations[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation from any\nlisting detail page.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                context.read<ChatBloc>().add(LoadConversations()),
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ConversationModel convo;

  const _ChatTile({required this.convo});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Conversation', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              subtitle: const Text('This will remove the chat from your list.'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletion(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Conversation?', 
            style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete your conversation with ${convo.otherUserName}? This action will hide the chat for you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(DeleteConversation(convo.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = convo.otherUserName;
    final lastMsg = convo.lastMessageText ??
        (convo.lastMessageImageUrl != null ? '📷 Photo' : '');
    final unreadCount = convo.unreadCount;
    final time = convo.lastMessageAt != null
        ? _formatTime(convo.lastMessageAt!)
        : '';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: convo.otherUserAvatarUrl != null
                  ? CachedNetworkImageProvider(
                      convo.otherUserAvatarUrl!,
                      maxWidth: 150,
                      maxHeight: 150,
                    )
                  : null,
              child: convo.otherUserAvatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    )
                  : null,
            ),
            if (convo.otherUserVerified)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 14,
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: unreadCount > 0
                    ? AppColors.primary
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg.isEmpty ? convo.listingTitle : lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  color: unreadCount > 0
                      ? const Color(0xFF374151)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          context.push('/chat/${convo.id}', extra: {
            'recipientName': convo.otherUserName,
            'recipientAvatar': convo.otherUserAvatarUrl,
            'listingId': convo.listingId,
            'listingTitle': convo.listingTitle,
            'listingPrice': convo.listingPrice,
            'listingImageUrl': convo.listingImageUrl,
          });
        },
        onLongPress: () => _showOptions(context),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.jm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}
