// lib/core/format.dart
String fmt(num? v, [int decimals = 2]) {
  if (v == null || (v is double && (v.isNaN || v.isInfinite))) return '—';
  return v.toStringAsFixed(decimals);
}
