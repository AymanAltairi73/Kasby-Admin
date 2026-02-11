import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import '../theme/kasby_colors.dart';

/// Kasby Dialog
/// A professional, high-end dialog/bottom sheet for Kasby Admin App
class KasbyDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool isBottomSheet;

  const KasbyDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.isBottomSheet = false,
  });

  static Future<T?> show<T>({
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool isBottomSheet = false,
  }) {
    if (isBottomSheet) {
      return Get.bottomSheet<T>(
        KasbyDialog(
          title: title,
          content: content,
          actions: actions,
          isBottomSheet: true,
        ),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        enterBottomSheetDuration: const Duration(milliseconds: 400),
        exitBottomSheetDuration: const Duration(milliseconds: 300),
      );
    }

    return Get.dialog<T>(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: KasbyDialog(title: title, content: content, actions: actions),
        ),
      ),
      transitionCurve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          width: isBottomSheet ? double.infinity : (Get.width * 0.9),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: isBottomSheet ? (Get.bottomBarHeight + 24) : 24,
          ),
          decoration: BoxDecoration(
            color: KasbyColors.surface,
            borderRadius: isBottomSheet
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBottomSheet)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.primaryGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                content,
                if (actions != null) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(
          begin: isBottomSheet ? 1.0 : 0.1,
          end: 0,
          curve: Curves.easeOutExpo,
          duration: const Duration(milliseconds: 600),
        );
  }
}
