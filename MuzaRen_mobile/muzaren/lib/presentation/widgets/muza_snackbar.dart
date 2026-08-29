import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum MuzaSnackbarType { success, error, info }

class MuzaSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required MuzaSnackbarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      _buildSnackBar(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  static void showGlobal({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required String message,
    required MuzaSnackbarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final state = messengerKey.currentState;
    if (state == null) return;
    state.hideCurrentSnackBar();
    state.showSnackBar(
      _buildSnackBar(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  static SnackBar _buildSnackBar({
    required String message,
    required MuzaSnackbarType type,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Color accentColor;
    IconData icon;
    
    switch (type) {
      case MuzaSnackbarType.success:
        accentColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case MuzaSnackbarType.error:
        accentColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case MuzaSnackbarType.info:
        accentColor = AppColors.primary;
        icon = Icons.chat_bubble_outline;
        break;
    }

    return SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Border
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Message
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              // Action Button
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              if (actionLabel == null) const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
