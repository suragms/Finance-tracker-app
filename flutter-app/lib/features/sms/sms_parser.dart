class SmsTransaction {
  final double amount;
  final String type; // 'debit' | 'credit'
  final String merchant;
  final String bank;

  SmsTransaction({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.bank,
  });
}

SmsTransaction? parseBankSms(String body) {
  final cleanBody = body.replaceAll('\n', ' ').replaceAll('\r', ' ');
  
  // Debit messages
  final debitRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:debited|spent|paid|withdrawn|tran)',
    caseSensitive: false,
  );
  // Credit messages
  final creditRegex = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:credited|received|deposited|added)',
    caseSensitive: false,
  );

  final debitMatch = debitRegex.firstMatch(cleanBody);
  if (debitMatch != null) {
    final amountStr = debitMatch.group(1)!.replaceAll(',', '');
    return SmsTransaction(
      amount: double.tryParse(amountStr) ?? 0,
      type: 'debit',
      merchant: _extractMerchant(cleanBody),
      bank: _extractBank(cleanBody),
    );
  }
  
  final creditMatch = creditRegex.firstMatch(cleanBody);
  if (creditMatch != null) {
    final amountStr = creditMatch.group(1)!.replaceAll(',', '');
    return SmsTransaction(
      amount: double.tryParse(amountStr) ?? 0,
      type: 'credit',
      merchant: _extractMerchant(cleanBody),
      bank: _extractBank(cleanBody),
    );
  }
  return null;
}

String _extractMerchant(String body) {
  final patterns = [
    RegExp(r'(?:at|to|spent on)\s+([A-Z0-9][A-Za-z0-9\s&*]{2,20}?)(\s+on|\s+via|\s+Ref|\.|\s+using)', caseSensitive: false),
    RegExp(r'VPA\s+([A-Za-z0-9.]+@[a-z]+)', caseSensitive: false), // UPI VPA
  ];

  for (final p in patterns) {
    final match = p.firstMatch(body);
    if (match != null) return match.group(1)!.trim();
  }
  return 'Merchant';
}

String _extractBank(String body) {
  final text = body.toUpperCase();
  if (text.contains('HDFC')) return 'HDFC';
  if (text.contains('SBI') || body.contains('State Bank')) return 'SBI';
  if (text.contains('ICICI')) return 'ICICI';
  if (text.contains('AXIS')) return 'Axis';
  if (text.contains('KOTAK')) return 'Kotak';
  return 'Bank';
}
