import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/no_api_seed_data.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../income/application/income_providers.dart';
import '../data/categories_api.dart';

/// Offline-first: Drift is the source of truth; [LedgerSyncService] keeps it fresh.
final expensesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) {
    ref.watch(ledgerSyncServiceProvider);
    return ref.watch(ledgerDatabaseProvider).watchExpensesForList();
  },
);

final recurringExpensesProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) {
    ref.watch(ledgerSyncServiceProvider);
    return ref.watch(ledgerDatabaseProvider).watchRecurringExpenses();
  },
);

final dashboardSelectedAccountProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Optimized data for Dashboard (pre-calculated metrics and spots).
final dashboardDataProvider = Provider.autoDispose<AsyncValue<DashboardData>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final incomes = ref.watch(incomesProvider);
  final selectedAccountId = ref.watch(dashboardSelectedAccountProvider);

  return expenses.when(
    data: (eList) => incomes.when(
      data: (iList) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1);

        double toDouble(dynamic r) => double.tryParse(r?.toString() ?? '') ?? 0;
        DateTime? toDate(dynamic r) => DateTime.tryParse(r?.toString() ?? '');

        var allExpenses = eList;
        var allIncomes = iList;

        if (selectedAccountId != null) {
          allExpenses = allExpenses.where((e) {
            final aid = e['account'] is Map ? (e['account'] as Map)['id']?.toString() : e['accountId']?.toString();
            return aid == selectedAccountId;
          }).toList();
          allIncomes = allIncomes.where((i) {
            final aid = i['account'] is Map ? (i['account'] as Map)['id']?.toString() : i['accountId']?.toString();
            return aid == selectedAccountId;
          }).toList();
        }

        final monthExpenses = allExpenses.where((e) {
          final d = toDate(e['date']);
          return d != null && !d.isBefore(start) && d.isBefore(end);
        }).toList();

        final monthIncomes = allIncomes.where((i) {
          final d = toDate(i['date']);
          return d != null && !d.isBefore(start) && d.isBefore(end);
        }).toList();

        final spent = monthExpenses.fold<double>(0, (s, e) => s + toDouble(e['amount']));
        final earned = monthIncomes.fold<double>(0, (s, i) => s + toDouble(i['amount']));

        final dayTotals = <int, double>{};
        for (final e in monthExpenses) {
          final d = toDate(e['date']);
          if (d == null) continue;
          dayTotals[d.day] = (dayTotals[d.day] ?? 0) + toDouble(e['amount']);
        }

        final lineSpots = List<FlSpot>.generate(
          DateUtils.getDaysInMonth(now.year, now.month),
          (i) => FlSpot((i + 1).toDouble(), dayTotals[i + 1] ?? 0),
        );

        final recent = [...monthExpenses, ...monthIncomes]
          ..sort((a, b) =>
              (toDate(b['date']) ?? now).compareTo(toDate(a['date']) ?? now));

        return AsyncValue.data(DashboardData(
          spent: spent,
          earned: earned,
          monthExpenses: monthExpenses,
          monthIncomes: monthIncomes,
          lineSpots: lineSpots,
          recent: recent,
          dayTotals: dayTotals,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

class DashboardData {
  DashboardData({
    required this.spent,
    required this.earned,
    required this.monthExpenses,
    required this.monthIncomes,
    required this.lineSpots,
    required this.recent,
    required this.dayTotals,
  });

  final double spent;
  final double earned;
  final List<Map<String, dynamic>> monthExpenses;
  final List<Map<String, dynamic>> monthIncomes;
  final List<FlSpot> lineSpots;
  final List<Map<String, dynamic>> recent;
  final Map<int, double> dayTotals;
}

/// Expenses for one account, derived from the same offline stream.
final expensesForAccountProvider = Provider.autoDispose
    .family<AsyncValue<List<Map<String, dynamic>>>, String>((ref, accountId) {
  return ref.watch(expensesProvider).whenData(
        (list) => list.where((e) {
          final aid = e['account'] is Map
              ? (e['account'] as Map)['id']?.toString()
              : e['accountId']?.toString();
          return aid == accountId;
        }).toList(),
      );
});

final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (kNoApiMode) {
    return List<Map<String, dynamic>>.from(noApiDemoCategories);
  }
  final rows = await ref.watch(categoriesApiProvider).list();
  return rows.where((row) {
    final type = row['type']?.toString();
    return type == null || type.isEmpty || type == 'expense';
  }).toList();
});
