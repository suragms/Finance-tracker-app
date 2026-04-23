import 'package:intl/intl.dart';

final _inrCurrencyFmt = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Indian-grouped rupee display for UI (e.g. ₹1,24,500). Not for API payloads.
String formatAmount(dynamic raw) {
  final n = double.tryParse(raw?.toString() ?? '0') ?? 0;
  return _inrCurrencyFmt.format(n);
}
