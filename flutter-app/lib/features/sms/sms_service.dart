import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import 'sms_expense_confirm_sheet.dart';
import 'sms_parser.dart';

class SmsService {
  SmsService._();

  static final Telephony _telephony = Telephony.instance;
  static bool _started = false;
  static bool _sheetOpen = false;

  static Future<void> initialize(BuildContext context, WidgetRef ref) async {
    if (_started) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final smsStatus = await Permission.sms.request();
    if (!smsStatus.isGranted) return;

    _started = true;
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _onMessage(context, ref, message);
      },
      listenInBackground: false,
    );
  }

  static void _onMessage(BuildContext context, WidgetRef ref, SmsMessage sms) {
    if (!context.mounted || _sheetOpen) return;
    final body = sms.body;
    if (body == null || body.trim().isEmpty) return;
    final txn = parseBankSms(body);
    if (txn == null) return;

    _sheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SmsExpenseConfirmSheet(txn: txn),
    ).whenComplete(() {
      _sheetOpen = false;
    });
  }
}
