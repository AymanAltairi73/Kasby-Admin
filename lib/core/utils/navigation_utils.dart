import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pops the current route without triggering GetX snackbar teardown
/// (avoids LateInitializationError on SnackbarController._controller).
void safePop<T>([T? result, BuildContext? context]) {
  if (context != null) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
      return;
    }
  }

  if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
    Get.back(closeOverlays: false, result: result);
    return;
  }

  if (Get.key.currentState?.canPop() ?? false) {
    Get.back(closeOverlays: false, result: result);
  }
}
