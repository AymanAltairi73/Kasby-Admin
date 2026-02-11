/// Validation Utilities
class ValidationUtils {
  ValidationUtils._();

  /// Validate Phone Number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف إلزامي';
    }
    // Basic international phone regex
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  /// Validate WhatsApp Number
  static String? validateWhatsApp(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'رقم الواتساب غير صحيح';
    }
    return null;
  }

  /// Validate Telegram Username or Link
  static String? validateTelegram(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    // Accepts @username, username, or t.me/username
    final telegramRegex = RegExp(
      r'^(@)?[a-zA-Z0-9_]{5,32}$|^https?://t\.me/[a-zA-Z0-9_]{5,32}$',
    );
    if (!telegramRegex.hasMatch(value)) {
      return 'معرف تيليجرام غير صحيح';
    }
    return null;
  }

  /// Validate Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  /// Validate Required Field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName إلزامي';
    }
    return null;
  }
}
