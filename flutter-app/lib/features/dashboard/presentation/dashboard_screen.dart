import 'dart:async' show unawaited;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/format_amount.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/ledger_tokens.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/application/income_providers.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../accounts/application/account_providers.dart';
import '../../accounts/data/accounts_api.dart';
import '../application/dashboard_providers.dart';
import 'dashboard_quick_access.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final overview = ref.watch(dashboardOverviewProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    void refreshAll() {
      unawaited(ref.read(ledgerSyncServiceProvider).pullAndFlush());
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categoryBreakdownProvider);
      ref.invalidate(incomesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(accountsProvider);
    }

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          refreshAll();
          await ref.read(dashboardOverviewProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Top Balance Card
            overview.when(
              data: (dash) {
                // Real-time total balance linked to accounts system
                final ledger = accountsAsync.valueOrNull;
                final accounts = ledger?.accounts ?? [];
                double totalBalance = 0;
                if (ledger != null) {
                  totalBalance = ledger.totalNetWorth;
                } else {
                  totalBalance = double.tryParse(dash['netWorth']?['netWorth']?.toString() ?? '0') ?? 0;
                }

                final tm = dash['thisMonth'] ?? {};
                final income = tm['totalIncome'] ?? 0;
                final expense = tm['totalExpenses'] ?? 0;

                return _MainHeroCard(
                  balance: totalBalance,
                  income: income,
                  expense: expense,
                );
              },
              loading: () => const LedgerDashboardSkeleton(),
              error: (e, _) => LedgerErrorState(
                title: 'Offline',
                message: 'Check connection or sync manually.',
                onRetry: refreshAll,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Access
            const DashboardQuickAccess(),
            const SizedBox(height: 24),

            // Monthly Chart Section
            overview.when(
              data: (dash) {
                final trend = (dash['savingsTrend'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                if (trend.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Monthly Analytics', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    _MonthlyChart(trend: trend),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const LedgerChartSkeleton(height: 200),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Recent Transactions Section
            _SectionHeader(
              title: 'Recent Transactions',
              onSeeAll: () {
                // Navigate to all transactions
              },
            ),
            const SizedBox(height: 12),
            _RecentTransactionsList(
              expensesAsync: expensesAsync,
              incomesAsync: incomesAsync,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(LedgerPageRoutes.fadeSlide(const AddExpenseScreen()));
        },
        backgroundColor: cs.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MainHeroCard extends StatelessWidget {
  final dynamic balance;
  final dynamic income;
  final dynamic expense;

  const _MainHeroCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(MfRadius.xl),
        boxShadow: MfShadow.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            MfCurrency.formatInr(balance),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                  label: 'Income',
                  amount: income,
                  color: MfPalette.incomeGreen,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatMiniCard(
                  label: 'Expense',
                  amount: expense,
                  color: MfPalette.expenseAmber,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final dynamic amount;
  final Color color;
  final IconData icon;

  const _StatMiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MfRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                Text(
                  MfCurrency.formatCompact(double.tryParse(amount.toString()) ?? 0),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.5),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'SEE ALL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> trend;

  const _MonthlyChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final chartTrend = trend.reversed.take(6).toList().reversed.toList();
    
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(MfRadius.md),
        boxShadow: MfShadow.card,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(chartTrend),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartTrend.length) return const SizedBox();
                  final monthStr = chartTrend[index]['month']?.toString() ?? '';
                  final month = monthStr.split('-').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getMonthName(month),
                      style: const TextStyle(color: MfPalette.textMuted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: chartTrend.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final expense = double.tryParse(data['expenses']?.toString() ?? '0') ?? 0;
            final income = double.tryParse(data['income']?.toString() ?? '0') ?? 0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: MfPalette.incomeGreen,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: expense,
                  color: MfPalette.expenseAmber,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    double max = 0;
    for (var d in data) {
      final e = double.tryParse(d['expenses']?.toString() ?? '0') ?? 0;
      final i = double.tryParse(d['income']?.toString() ?? '0') ?? 0;
      if (e > max) max = e;
      if (i > max) max = i;
    }
    return max * 1.2;
  }

  String _getMonthName(String m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final idx = int.tryParse(m) ?? 1;
    return months[idx - 1];
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> expensesAsync;
  final AsyncValue<List<Map<String, dynamic>>> incomesAsync;

  const _RecentTransactionsList({
    required this.expensesAsync,
    required this.incomesAsync,
  });

  @override
  Widget build(BuildContext context) {
    return expensesAsync.when(
      data: (expenses) => incomesAsync.when(
        data: (incomes) {
          // Combine and sort
          final all = [
            ...expenses.map((e) => {...e, 'type': 'expense'}),
            ...incomes.map((i) => {...i, 'type': 'income'}),
          ];
          
          all.sort((a, b) {
            final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          final recent = all.take(10).toList();

          if (recent.isEmpty) {
            return const _EmptyTransactions();
          }

          return Column(
            children: recent.map((tx) => _TransactionTile(tx: tx)).toList(),
          );
        },
        loading: () => const LedgerExpenseListSkeleton(count: 5),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const LedgerExpenseListSkeleton(count: 5),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx['type'] == 'expense';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final date = DateTime.tryParse(tx['date']?.toString() ?? '') ?? DateTime.now();
    final category = isExpense 
        ? (tx['category'] is Map ? tx['category']['name'] : (tx['categoryName'] ?? 'Expense'))
        : (tx['source'] ?? 'Income');
         
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MfRadius.md),
        boxShadow: MfShadow.card,
        border: Border.all(color: MfPalette.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isExpense ? MfPalette.expenseAmber : MfPalette.incomeGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isExpense ? Icons.shopping_bag_rounded : Icons.payments_rounded,
              color: isExpense ? MfPalette.expenseAmber : MfPalette.incomeGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: MfPalette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM \u2022 hh:mm a').format(date),
                  style: GoogleFonts.inter(fontSize: 11, color: MfPalette.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${MfCurrency.formatInr(amount)}',
                style: GoogleFonts.inter(
                      color: isExpense ? MfPalette.expenseAmber : MfPalette.incomeGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              if (isExpense && tx['accountName'] != null)
                Text(
                  tx['accountName'].toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    color: MfPalette.textHint,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.auto_graph_rounded, size: 64, color: MfPalette.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: MfPalette.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding your first expense.',
            style: GoogleFonts.inter(
              color: MfPalette.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
