import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_logger_service.dart';

class ThemeController extends GetxController {
  final isDarkMode = true.obs;
  static const String _storageKey = 'is_dark_mode';

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'ThemeController',
      method: 'onInit',
      feature: 'Core',
      status: 'INFO',
    );
    super.onInit();
    _loadThemeFromPrefs();
  }

  @override
  void onReady() {
    AppLoggerService.debugTrace(
      className: 'ThemeController',
      method: 'onReady',
      feature: 'Core',
      status: 'INFO',
      params: {'isDarkMode': isDarkMode.value},
    );
    super.onReady();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'ThemeController',
      method: 'onClose',
      feature: 'Core',
      status: 'INFO',
    );
    super.onClose();
  }

  void toggleTheme() async {
    AppLoggerService.debugTrace(
      className: 'ThemeController',
      method: 'toggleTheme',
      feature: 'Core',
      status: 'INFO',
      params: {'toDarkMode': !isDarkMode.value},
    );
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, isDarkMode.value);
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_storageKey) ?? true;

    // Apply theme on load
    Future.delayed(Duration.zero, () {
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    });
  }
}
