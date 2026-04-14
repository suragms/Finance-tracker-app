import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/no_api_dashboard.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../data/reports_api.dart';

/// Year + month (1–12) for MVP expense report charts.
typedef ExpenseMvpMonth = ({int year, int month});

final monthlySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    if (kNoApiMode) {
      return buildOfflineMonthlySummary(ref.watch(ledgerDatabaseProvider));
    }
    return ref.watch(reportsApiProvider).monthlySummary();
  },
);

final dashboardOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      if (kNoApiMode) {
        return buildOfflineDashboardOverview(ref.watch(ledgerDatabaseProvider));
      }
      return ref.watch(reportsApiProvider).dashboard();
    });

final categoryBreakdownProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (kNoApiMode) {
        return buildOfflineCategoryBreakdown(ref.watch(ledgerDatabaseProvider));
      }
      return ref.watch(reportsApiProvider).categoryBreakdown();
    });

final taxSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  if (kNoApiMode) {
    return offlineTaxSummaryPlaceholder();
  }
  return ref.watch(reportsApiProvider).taxSummary(details: true);
});

final expenseMvpProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ExpenseMvpMonth>((ref, m) async {
      if (kNoApiMode) {
        return buildOfflineExpenseMvp(
          ref.watch(ledgerDatabaseProvider),
          m.year,
          m.month,
        );
      }
      return ref.watch(reportsApiProvider).expenseMvp(
            year: m.year,
            month: m.month,
            trendMonths: 12,
          );
    });
