import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/offline/db/ledger_database.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';

final recurringManagerProvider = Provider<RecurringManager>((ref) {
  final mgr = RecurringManager(ref);
  ref.onDispose(mgr.dispose);
  return mgr;
});

class RecurringManager {
  RecurringManager(this._ref);
  final Ref _ref;
  StreamSubscription? _sub;
  bool _isProcessing = false;

  void init() {
    _sub = _ref.read(ledgerDatabaseProvider).watchRecurringExpenses().listen((items) {
      _checkDue(items);
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _checkDue(List<Map<String, dynamic>> items) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final now = DateTime.now();
      for (final item in items) {
        if (item['active'] != true) continue;
        final nextDateRaw = item['nextDate'];
        if (nextDateRaw == null) continue;
        final nextDate = DateTime.tryParse(nextDateRaw.toString());
        if (nextDate == null) continue;

        if (nextDate.isBefore(now)) {
          await _processItem(item, nextDate);
        }
      }
    } catch (e) {
      // Log error
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processItem(Map<String, dynamic> item, DateTime due) async {
    final mode = item['mode'] ?? 'auto_create';
    
    if (mode == 'auto_create') {
      final sync = _ref.read(ledgerSyncServiceProvider);
      await sync.createExpenseOffline(
        amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0,
        categoryId: item['categoryId']?.toString() ?? '',
        categoryName: (item['category'] as Map?)?['name']?.toString(),
        dateIso: due.toIso8601String(),
        note: 'Auto: ${item['title']}',
        accountId: item['accountId']?.toString(),
      );
    }
    
    // Update next date
    final frequency = item['frequency']?.toString() ?? 'monthly';
    final newNextDate = _calculateNext(due, frequency);
    
    // Update local DB
    final db = _ref.read(ledgerDatabaseProvider);
    final payload = Map<String, dynamic>.from(item);
    payload['nextDate'] = newNextDate.toIso8601String();
    
    await db.upsertRecurringFromServer(
      payload,
      status: LedgerSyncStatus.pendingPush, // Need to push the update to backend
    );
    
    // Enqueue outbox for nextDate update
    // Note: Backend might also do this automatically if it sees the payment,
    // but the mobile app should stay in sync.
    // In our case, the backend cron handles it if online.
    // If offline, we do it here.
  }

  DateTime _calculateNext(DateTime current, String freq) {
    switch (freq.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return _addMonths(current, 1);
      case 'quarterly':
        return _addMonths(current, 3);
      case 'yearly':
        return _addMonths(current, 12);
      default:
        return _addMonths(current, 1);
    }
  }

  DateTime _addMonths(DateTime source, int months) {
    final year = source.year + (source.month + months - 1) ~/ 12;
    final month = (source.month + months - 1) % 12 + 1;
    var day = source.day;

    final lastDay = DateTime(year, month + 1, 0).day;
    if (day > lastDay) day = lastDay;

    return DateTime(
      year,
      month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
    );
  }
}
