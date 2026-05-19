import 'package:flutter/material.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  // Globalkey to show snackbars without relying on standard context when needed
  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  void showWarningBanner({
    required String title,
    required String message,
    VoidCallback? onAction,
  }) {
    AppLogger.warn("NOTIFICATION TRIGGERED: $title - $message");
    
    final context = messengerKey.currentState;
    if (context == null) return;

    context.hideCurrentMaterialBanner();
    context.showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        leading: const Icon(Icons.error_outline, color: Colors.white, size: 28),
        backgroundColor: const Color(0xFFEF4444),
        actions: [
          TextButton(
            onPressed: () {
              context.hideCurrentMaterialBanner();
              if (onAction != null) onAction();
            },
            child: const Text(
              "VIEW",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => context.hideCurrentMaterialBanner(),
            child: const Text(
              "DISMISS",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void showSuccessSnackbar(String message) {
    final context = messengerKey.currentState;
    if (context == null) return;

    context.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showErrorSnackbar(String message) {
    final context = messengerKey.currentState;
    if (context == null) return;

    context.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
