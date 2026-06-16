import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/kasby_colors.dart';
import '../utils/navigation_utils.dart';
import 'kasby_dialog.dart';

/// Kasby Confirmation Dialog
/// Specifically designed for sensitive actions with bold Gold/Error buttons
class KasbyConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final bool isDangerous;

  const KasbyConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
    this.confirmColor = KasbyColors.primaryGold,
    required this.onConfirm,
    this.isDangerous = false,
  });

  static void show({
    String title = 'تأكيد العملية',
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    KasbyDialog.show(
      title: title,
      content: Text(
        message,
        style: const TextStyle(
          color: KasbyColors.textBody,
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => safePop(),
          child: Text(
            cancelText,
            style: const TextStyle(color: KasbyColors.textSecondary),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            safePop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous
                ? KasbyColors.error
                : (confirmColor ?? KasbyColors.primaryGold),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Used via static show
  }
}
