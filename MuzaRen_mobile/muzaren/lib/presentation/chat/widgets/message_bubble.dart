import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/message_model.dart';
import '../../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onEdit;
  final Function(String deleteType)? onDelete;
  final VoidCallback? onReply;
  final Function(String emoji)? onReact;
  final VoidCallback? onInfo;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onEdit,
    this.onDelete,
    this.onReply,
    this.onReact,
    this.onInfo,
  });

  static const List<String> _reactionEmojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  void _copyToClipboard(BuildContext context) {
    if (message.text == null) return;
    Clipboard.setData(ClipboardData(text: message.text!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    if (message.deletedForAll) return;

    final hoursDiff = DateTime.now().difference(message.createdAt).inHours;
    final minutesDiff = DateTime.now().difference(message.createdAt).inMinutes;
    final canDeleteForEveryone = isMe && hoursDiff < 24;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
            const SizedBox(height: 16),
            // Reactions (Feature 4 & 5 refinement)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _reactionEmojis.map((emoji) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReact?.call(emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.reactions.values.contains(emoji) 
                          ? AppColors.primary.withValues(alpha: 0.1) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
            ),
            const Divider(height: 32),
            _actionItem(Icons.reply_outlined, 'Reply', onTap: () {
              Navigator.pop(context);
              onReply?.call();
            }),
            if (message.text != null)
              _actionItem(Icons.copy_outlined, 'Copy', onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context);
              }),
            _actionItem(Icons.info_outline, 'Message Info', onTap: () {
              Navigator.pop(context);
              onInfo?.call();
            }),
            if (isMe && message.text != null && !message.deletedForAll && minutesDiff < 15)
              _actionItem(Icons.edit_outlined, 'Edit Message', onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              }),
            if (canDeleteForEveryone)
              _actionItem(Icons.delete_forever, 'Delete for Everyone', 
                color: Colors.redAccent, 
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call('for_everyone');
                }),
            _actionItem(Icons.delete_outline, 'Delete for Me', 
              color: const Color(0xFF6B7280),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call('for_me');
              }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String title, {required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF374151), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          color: color ?? const Color(0xFF111827),
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.deletedForAll) {
      return _buildDeletedPlaceholder();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onLongPress: () => _showContextMenu(context),
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
                      onReply?.call();
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyTo != null) _buildReplyPreview(),
                        if (message.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              memCacheWidth: 400,
                              width: 200,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[200],
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Text(
                            message.text ?? '',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              color: isMe ? Colors.white : const Color(0xFF111827),
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (message.reactions.isNotEmpty) _buildReactionChips(),
              ],
            ),
            const SizedBox(height: 4),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionChips() {
    final uniqueReactions = message.reactions.values.toSet().toList();
    
    return Positioned(
      bottom: -10,
      right: isMe ? null : 0,
      left: isMe ? 0 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...uniqueReactions.take(3).map((e) => Text(e, style: const TextStyle(fontSize: 12))),
            if (message.reactions.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '${message.reactions.length}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          const Text(
            'Edited',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          message.formattedTime,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            color: isMe ? AppColors.primary.withValues(alpha: 0.6) : const Color(0xFF9CA3AF),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: isMe ? Colors.white : AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo?.sender?.name ?? 'Message',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isMe ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo?.text ?? (message.replyTo?.imageUrl != null ? '📷 Image' : 'Message'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: isMe ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'This message was deleted',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (message.status == MessageStatus.sending) {
      return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary));
    }
    return Icon(
      message.read ? Icons.done_all : Icons.done,
      size: 14,
      color: message.read ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
    );
  }
}
