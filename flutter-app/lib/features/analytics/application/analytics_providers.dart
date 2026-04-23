import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../expenses/application/expense_providers.dart';
import '../../income/application/income_providers.dart';

/// Mon–Sun totals for the current calendar week (Monday start).
class WeeklyAnalyticsSnapshot {
  const WeeklyAnalyticsSnapshot({
    required this.weekStartMonday,
    required this.expenseByDay,
    required this.incomeByDay,
  });

  final DateTime weekStartMonday;
  final List<double> expenseByDay;
  final List<double> incomeByDay;
}

double _parseAmount(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '0') ?? 0;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

WeeklyAnalyticsSnapshot _computeWeek(
  List<Map<String, dynamic>> expenses,
  List<Map<String, dynamic>> incomes,
) {
  final now = DateTime.now();
  final today = _dateOnly(now);
  final monday =
      today.subtract(Duration(days: today.weekday - DateTime.monday));
  final expenseByDay = List<double>.filled(7, 0);
  final incomeByDay = List<double>.filled(7, 0);

  for (final e in expenses) {
    final parsed = DateTime.tryParse(e['date']?.toString() ?? '');
    if (parsed == null) continue;
    final day = _dateOnly(parsed.toLocal());
    if (day.isBefore(monday)) continue;
    final idx = day.difference(monday).inDays;
    if (idx < 0 || idx > 6) continue;
    expenseByDay[idx] += _parseAmount(e['amount']);
  }

  for (final i in incomes) {
    final parsed = DateTime.tryParse(i['date']?.toString() ?? '');
    if (parsed == null) continue;
    final day = _dateOnly(parsed.toLocal());
    if (day.isBefore(monday)) continue;
    final idx = day.difference(monday).inDays;
    if (idx < 0 || idx > 6) continue;
    incomeByDay[idx] += _parseAmount(i['amount']);
  }

  return WeeklyAnalyticsSnapshot(
    weekStartMonday: monday,
    expenseByDay: expenseByDay,
    incomeByDay: incomeByDay,
  );
}

final weeklyAnalyticsProvider =
    Provider.autoDispose<AsyncValue<WeeklyAnalyticsSnapshot>>((ref) {
  final ex = ref.watch(expensesProvider);
  final inc = ref.watch(incomesProvider);
  return ex.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) => inc.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (incomes) => AsyncValue.data(_computeWeek(expenses, incomes)),
    ),
  );
});

String _categoryIdFromExpense(Map<String, dynamic> e) {
  final cat = e['category'];
  if (cat is Map) {
    return cat['id']?.toString() ?? 'unknown';
  }
  return e['categoryId']?.toString() ?? 'unknown';
}

/// Expense totals by category for the **current calendar month** (local).
final analyticsCategoryMonthProvider =
    Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final ex = ref.watch(expensesProvider);
  return ex.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) {
      final now = DateTime.now();
      final byCat = <String, double>{};
      for (final e in expenses) {
        final parsed = DateTime.tryParse(e['date']?.toString() ?? '');
        if (parsed == null) continue;
        final d = parsed.toLocal();
        if (d.year != now.year || d.month != now.month) continue;
        final id = _categoryIdFromExpense(e);
        byCat[id] = (byCat[id] ?? 0) + _parseAmount(e['amount']);
      }
      final rows = byCat.entries
          .map(
            (e) => <String, dynamic>{
              'categoryId': e.key,
              'total': e.value.toStringAsFixed(2),
            },
          )
          .toList();
      return AsyncValue.data(rows);
    },
  );
});
