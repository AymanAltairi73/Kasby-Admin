/// Safe numeric parsing for Supabase responses
/// Handles cases where NUMERIC values come as Strings or num types
double safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
