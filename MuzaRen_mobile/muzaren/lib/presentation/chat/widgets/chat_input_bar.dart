import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/message_model.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text, {String? replyToId}) onSend;
  final Function() onPickImage;
  final Function(String) onTextChanged;
  final String? initialText;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelEdit;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onPickImage,
    required this.onTextChanged,
    this.initialText,
    this.replyingTo,
    this.onCancelEdit,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      if (widget.initialText != null) {
        _controller.text = widget.initialText!;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      } else {
        _controller.clear();
      }
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact(); // Feature 9: Haptic feedback
    _controller.clear();
    widget.onSend(text, replyToId: widget.replyingTo?.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.initialText != null;
    bool isReplying = widget.replyingTo != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing) _buildEditingBanner(),
          if (isReplying) _buildReplyingBanner(),
          _buildInputArea(isEditing),
        ],
      ),
    );
  }

  Widget _buildEditingBanner() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'Editing message',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onCancelEdit,
            child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyingBanner() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.replyingTo?.sender?.name ?? 'Message',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.replyingTo?.text ?? (widget.replyingTo?.imageUrl != null ? '📷 Image' : 'Message'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onCancelReply,
              child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isEditing) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 12, 12, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Aligns button to bottom of expanded text
        children: [
          if (!isEditing)
            GestureDetector(
              onTap: widget.onPickImage,
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined,
                    size: 22, color: Color(0xFF374151)),
              ),
            ),
          if (!isEditing) const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 150),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _controller,
                autofocus: isEditing || widget.replyingTo != null,
                maxLines: null, // Multi-line support
                textInputAction: TextInputAction.newline,
                onChanged: widget.onTextChanged,
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: isEditing ? 'Edit your message...' : 'Type your message...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child:
                  Icon(isEditing ? Icons.check : Icons.send, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
