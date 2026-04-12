import 'dart:async' show unawaited;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api_config.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/no_api_dashboard.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../insights/application/insights_providers.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../whatsapp/application/whatsapp_status_provider.dart';
import '../../whatsapp/presentation/whatsapp_connect_screen.dart';
import '../application/dashboard_providers.dart';

final userEmailProvider = Provider<String?>((ref) {
  return ref.read(tokenStorageProvider).userEmail;
});

double _toDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

String _formatCurrency(dynamic raw) {
  final value = _toDouble(raw);
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: value == value.roundToDouble() ? 0 : 2,
  ).format(value);
}

String _formatCompact(dynamic raw) {
  final value = _toDouble(raw);
  return MfCurrency.formatCompact(value);
}

String _greetingFirstName(String? email) {
  if (email == null || email.isEmpty) return 'there';
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'there';
  return local[0].toUpperCase() + local.substring(1);
}

String _monthShortLabel(String key) {
  final parts = key.split('-');
  if (parts.length < 2) return key;
  final month = int.tryParse(parts[1]) ?? 1;
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[(month - 1).clamp(0, 11)];
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

class _TrendPoint {
  const _TrendPoint({
    required this.monthKey,
    required this.income,
    required this.expense,
  });

  final String monthKey;
  final double income;
  final double expense;
}

List<_TrendPoint> _parseTrend(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((entry) {
    final map = Map<String, dynamic>.from(entry as Map);
    return _TrendPoint(
      monthKey: map['month']?.toString() ?? '',
      income: _toDouble(map['income']),
      expense: _toDouble(map['expenses'] ?? map['expense']),
    );
  }).toList();
}

class _SpendingSignal {
  const _SpendingSignal({
    required this.title,
    required this.body,
    required this.currentAmount,
    required this.previousAmount,
    required this.accent,
    required this.icon,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final double currentAmount;
  final double previousAmount;
  final Color accent;
  final IconData icon;
  final String actionLabel;
}

_SpendingSignal _buildSpendingSignal(List<Map<String, dynamic>> expenses) {
  final now = DateTime.now();
  final currentStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final previousStart = currentStart.subtract(const Duration(days: 7));

  final current = <String, double>{};
  final previous = <String, double>{};
  var currentTotal = 0.0;

  for (final expense in expenses) {
    final date = _parseDate(expense['date']);
    if (date == null) continue;
    final amount = _toDouble(expense['amount']);
    final category = expense['category'] is Map
        ? (expense['category'] as Map)['name']?.toString() ?? 'Uncategorized'
        : 'Uncategorized';

    if (!date.isBefore(currentStart)) {
      current[category] = (current[category] ?? 0) + amount;
      currentTotal += amount;
      continue;
    }
    if (!date.isBefore(previousStart) && date.isBefore(currentStart)) {
      previous[category] = (previous[category] ?? 0) + amount;
    }
  }

  if (current.isEmpty) {
    return const _SpendingSignal(
      title: 'No spend recorded in the last 7 days',
      body:
          'Once fresh transactions land, this space will call out unusual patterns and notable category shifts.',
      currentAmount: 0,
      previousAmount: 0,
      accent: MfPalette.insightBlue,
      icon: Icons.timelapse_rounded,
      actionLabel: 'Record a transaction',
    );
  }

  String bestCategory = current.entries.first.key;
  double bestDelta = -double.infinity;
  double bestCurrent = current.entries.first.value;
  double bestPrevious = previous[bestCategory] ?? 0;

  for (final entry in current.entries) {
    final prior = previous[entry.key] ?? 0;
    final delta = entry.value - prior;
    if (delta > bestDelta) {
      bestDelta = delta;
      bestCategory = entry.key;
      bestCurrent = entry.value;
      bestPrevious = prior;
    }
  }

  if (bestPrevious > 0 && bestCurrent > bestPrevious) {
    final rise = ((bestCurrent - bestPrevious) / bestPrevious * 100).round();
    return _SpendingSignal(
      title: '$bestCategory is up $rise% this week',
      body:
          'You spent ${_formatCurrency(bestCurrent)} over the last 7 days versus ${_formatCurrency(bestPrevious)} in the prior week.',
      currentAmount: bestCurrent,
      previousAmount: bestPrevious,
      accent: MfPalette.warningAmber,
      icon: Icons.trending_up_rounded,
      actionLabel: 'Review the spike',
    );
  }

  if (bestPrevious == 0 && bestCurrent > 0) {
    return _SpendingSignal(
      title: '$bestCategory is newly active',
      body:
          'This category generated ${_formatCurrency(bestCurrent)} in the last 7 days and was quiet in the week before.',
      currentAmount: bestCurrent,
      previousAmount: bestPrevious,
      accent: MfPalette.insightBlue,
      icon: Icons.auto_graph_rounded,
      actionLabel: 'Explore the activity',
    );
  }

  final share = currentTotal <= 0
      ? 0
      : (bestCurrent / currentTotal * 100).round();
  return _SpendingSignal(
    title: '$bestCategory leads your week',
    body:
        'It accounts for about $share% of recent spending, with ${_formatCurrency(bestCurrent)} logged over the last 7 days.',
    currentAmount: bestCurrent,
    previousAmount: bestPrevious,
    accent: MfPalette.primaryLight,
    icon: Icons.pie_chart_rounded,
    actionLabel: 'See the full breakdown',
  );
}

class _QuickActionModel {
  const _QuickActionModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

List<_QuickActionModel> _buildQuickActions(
  BuildContext context, {
  required _SpendingSignal signal,
  required double netSavings,
}) {
  return [
    _QuickActionModel(
      title: 'Record spend',
      subtitle: 'Capture a card, UPI, or cash transaction fast.',
      icon: Icons.add_card_rounded,
      accent: MfPalette.expenseRed,
      onTap: () {
        Navigator.of(
          context,
        ).push(LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()));
      },
    ),
    _QuickActionModel(
      title: 'Log income',
      subtitle: 'Keep salary, refunds, and side income current.',
      icon: Icons.savings_rounded,
      accent: MfPalette.incomeGreen,
      onTap: () {
        Navigator.of(
          context,
        ).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
      },
    ),
    _QuickActionModel(
      title: netSavings < 0 ? 'Review reports' : 'Ask the AI desk',
      subtitle: netSavings < 0
          ? signal.actionLabel
          : 'Get a tailored read on trends, warnings, and next moves.',
      icon: netSavings < 0
          ? Icons.insert_chart_outlined_rounded
          : Icons.auto_awesome_rounded,
      accent: netSavings < 0 ? MfPalette.warningAmber : MfPalette.insightBlue,
      onTap: () {
        Navigator.of(context).push(
          LedgerPageRoutes.fadeSlide<void>(
            netSavings < 0
                ? const ReportsScreen()
                : const InsightsScreen(initialTab: InsightsEntryTab.chat),
          ),
        );
      },
    ),
  ];
}

/// Premium home: fast financial pulse, anomaly spotlight, actions, and recent activity.
class MoneyFlowHomeScreen extends ConsumerWidget {
  const MoneyFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final overview = ref.watch(dashboardOverviewProvider);
    final expenses = ref.watch(expensesProvider);
    final insights = ref.watch(aiInsightsProvider);
    final wa = ref.watch(whatsappLinkStatusProvider);
    final name = _greetingFirstName(ref.watch(userEmailProvider));

    Future<void> refresh() async {
      unawaited(ref.read(ledgerSyncServiceProvider).pullAndFlush());
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categoryBreakdownProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(aiInsightsProvider);
      ref.invalidate(whatsappLinkStatusProvider);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surface,
              cs.surfaceContainerLow.withValues(alpha: 0.75),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.16),
                        cs.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 220,
              left: -90,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MfPalette.insightBlue.withValues(alpha: 0.1),
                        MfPalette.insightBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              color: cs.primary,
              onRefresh: () async {
                await refresh();
                await ref.read(dashboardOverviewProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          MfSpace.lg,
                          MfSpace.xxl,
                          MfSpace.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kNoApiMode) ...[
                              const OfflineModeBanner(),
                              const SizedBox(height: MfSpace.lg),
                            ],
                            _HomeHeader(name: name),
                            const SizedBox(height: MfSpace.xl),
                            overview.when(
                              data: (dash) {
                                final netWorth = dash['netWorth'];
                                final netWorthMap = netWorth is Map
                                    ? Map<String, dynamic>.from(netWorth)
                                    : <String, dynamic>{};
                                final thisMonth = dash['thisMonth'];
                                final thisMonthMap = thisMonth is Map
                                    ? Map<String, dynamic>.from(thisMonth)
                                    : <String, dynamic>{};
                                final balance =
                                    netWorthMap['netWorth']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? _formatCurrency(netWorthMap['netWorth'])
                                    : '--';
                                final income = _toDouble(
                                  thisMonthMap['totalIncome'],
                                );
                                final expense = _toDouble(
                                  thisMonthMap['totalExpenses'],
                                );
                                final savingsRaw =
                                    thisMonthMap['netSavings'] ??
                                    thisMonthMap['netCashFlow'];
                                final savings = _toDouble(savingsRaw);
                                final trend = _parseTrend(dash['savingsTrend']);
                                final signal = expenses.maybeWhen(
                                  data: _buildSpendingSignal,
                                  orElse: () => const _SpendingSignal(
                                    title: 'Preparing your spending spotlight',
                                    body:
                                        'We are comparing the last 7 days with the prior week to surface unusual activity.',
                                    currentAmount: 0,
                                    previousAmount: 0,
                                    accent: MfPalette.insightBlue,
                                    icon: Icons.radar_rounded,
                                    actionLabel: 'Loading',
                                  ),
                                );

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FinancialPulseCard(
                                      balanceLabel:
                                          netWorthMap['label']?.toString() ??
                                          'Total balance',
                                      balance: balance,
                                      income: income,
                                      expense: expense,
                                      savings: savings,
                                      monthLabel:
                                          thisMonthMap['month']?.toString() ??
                                          DateFormat(
                                            'MMM yyyy',
                                          ).format(DateTime.now()),
                                    ),
                                    const SizedBox(height: MfSpace.lg),
                                    expenses.when(
                                      data: (list) => _SevenDaySignalCard(
                                        signal: _buildSpendingSignal(list),
                                      ),
                                      loading: () =>
                                          const _GlassLoadingCard(height: 158),
                                      error: (_, _) =>
                                          _SevenDaySignalCard(signal: signal),
                                    ),
                                    const SizedBox(height: MfSpace.lg),
                                    _QuickActionsGrid(
                                      actions: _buildQuickActions(
                                        context,
                                        signal: signal,
                                        netSavings: savings,
                                      ),
                                    ),
                                    const SizedBox(height: MfSpace.xxl),
                                    _SectionHeader(
                                      overline: 'Visual direction',
                                      title: 'Cash flow, clear in one glance',
                                      subtitle:
                                          'Income and expense lines stay visible without crowding the screen.',
                                    ),
                                    const SizedBox(height: MfSpace.md),
                                    _FlowPanel(
                                      trend: trend,
                                      income: income,
                                      expense: expense,
                                      savings: savings,
                                    ),
                                  ],
                                );
                              },
                              loading: () => Column(
                                children: const [
                                  _GlassLoadingCard(height: 246),
                                  SizedBox(height: MfSpace.lg),
                                  _GlassLoadingCard(height: 158),
                                  SizedBox(height: MfSpace.lg),
                                  _GlassLoadingCard(height: 198),
                                ],
                              ),
                              error: (error, _) => LedgerErrorState(
                                title: 'We could not build your snapshot',
                                message:
                                    'Sorry about that. Pull to refresh or retry while we fetch the latest balances and trends.',
                                onRetry: () {
                                  refresh();
                                },
                              ),
                            ),
                            const SizedBox(height: MfSpace.xxl),
                            insights.when(
                              data: (payload) => _AiConciergeCard(
                                summary: payload.monthlyFinancialSummary,
                                highlight: payload.spendingWarnings.isNotEmpty
                                    ? payload.spendingWarnings.first
                                    : payload.savingSuggestions.isNotEmpty
                                    ? payload.savingSuggestions.first
                                    : null,
                              ),
                              loading: () =>
                                  const _GlassLoadingCard(height: 150),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: MfSpace.xxl),
                            _SectionHeader(
                              overline: 'Flow mockup',
                              title: 'Recent activity',
                              subtitle:
                                  'A staggered ledger keeps transactions scannable without heavy dividers.',
                              actionLabel: 'Open all',
                              onAction: () {
                                Navigator.of(context).push(
                                  LedgerPageRoutes.fadeSlide<void>(
                                    const ExpenseListScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: MfSpace.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                  expenses.when(
                    data: (list) {
                      final recent = list.take(5).toList();
                      if (recent.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MfSpace.xxl,
                            ),
                            child: LedgerEmptyState(
                              title: 'No transactions yet',
                              subtitle:
                                  'Your dashboard is ready. Add a first expense or income and the weekly spotlight, search, and reports will come alive.',
                              icon: Icons.wallet_outlined,
                              actionLabel: 'Add expense',
                              onAction: () {
                                Navigator.of(context).push(
                                  LedgerPageRoutes.fadeSlide<void>(
                                    const AddExpenseScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          0,
                          MfSpace.xxl,
                          MfSpace.md,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final expense = recent[index];
                            final category = expense['category'] is Map
                                ? (expense['category'] as Map)['name']
                                          ?.toString() ??
                                      'Expense'
                                : 'Expense';
                            final note =
                                expense['note']?.toString().trim() ?? '';
                            final date = _parseDate(expense['date']);
                            final subtitle = note.isNotEmpty
                                ? note
                                : date != null
                                ? DateFormat('EEE, d MMM').format(date)
                                : 'Logged transaction';
                            final amount = _formatCurrency(expense['amount']);
                            final avatar = category.isNotEmpty
                                ? category.substring(0, 1)
                                : '?';

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: MfSpace.md,
                              ),
                              child: TransactionTile(
                                title: category,
                                subtitle: subtitle,
                                amount: amount,
                                isExpense: true,
                                avatarColor: MfPalette.expenseRed,
                                avatarLabel: avatar,
                                onTap: () {
                                  Navigator.of(context).push(
                                    LedgerPageRoutes.fadeSlide<void>(
                                      const ExpenseListScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          }, childCount: recent.length),
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                        child: TransactionListSkeleton(count: 4),
                      ),
                    ),
                    error: (_, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MfSpace.xxl,
                        ),
                        child: LedgerErrorState(
                          title: 'Recent activity is unavailable',
                          message:
                              'Sorry - we could not load transactions right now. Pull to refresh and we will try again.',
                          onRetry: () {
                            refresh();
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MfSpace.xxl,
                        MfSpace.sm,
                        MfSpace.xxl,
                        MfSpace.sm,
                      ),
                      child: wa.when(
                        data: (raw) {
                          if (raw == null) return const SizedBox.shrink();
                          final connected =
                              raw['verified'] == true ||
                              raw['connected'] == true;
                          return AppCard(
                            glass: true,
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WhatsappConnectScreen(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: MfPalette.incomeGreen.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      MfRadius.md,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.chat_rounded,
                                    color: MfPalette.incomeGreen,
                                  ),
                                ),
                                const SizedBox(width: MfSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp capture',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        connected
                                            ? 'Connected and ready for receipt capture.'
                                            : 'Connect to turn messages and images into expenses faster.',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.62,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: cs.onSurface.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hello, $name',
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your financial health snapshot is ready.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MfSpace.md,
            vertical: MfSpace.sm,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Secure session',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialPulseCard extends StatelessWidget {
  const _FinancialPulseCard({
    required this.balanceLabel,
    required this.balance,
    required this.income,
    required this.expense,
    required this.savings,
    required this.monthLabel,
  });

  final String balanceLabel;
  final String balance;
  final double income;
  final double expense;
  final double savings;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: heroCardDecoration(),
      padding: const EdgeInsets.all(MfSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood board / visual direction',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: MfPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      balanceLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: MfPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MfSpace.md,
                  vertical: MfSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monthLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            balance,
            style: GoogleFonts.manrope(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1.4,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'A premium, trusted snapshot of balances, cash flow, and confidence signals.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: MfPalette.textMuted,
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          Row(
            children: [
              Expanded(
                child: _PulseMetric(
                  label: 'Income',
                  value: _formatCompact(income),
                  accent: MfPalette.incomeGreen,
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: _PulseMetric(
                  label: 'Spent',
                  value: _formatCompact(expense),
                  accent: MfPalette.expenseRed,
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: _PulseMetric(
                  label: 'Net',
                  value: _formatCompact(savings),
                  accent: savings >= 0
                      ? MfPalette.primaryGlow
                      : MfPalette.warningAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  const _PulseMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.md,
        vertical: MfSpace.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MfRadius.md),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MfPalette.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SevenDaySignalCard extends StatelessWidget {
  const _SevenDaySignalCard({required this.signal});

  final _SpendingSignal signal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: signal.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MfRadius.md),
                ),
                child: Icon(signal.icon, color: signal.accent),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wireframe / flow mockup',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '7-day spotlight',
                      style: GoogleFonts.manrope(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            signal.title,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            signal.body,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Row(
            children: [
              Expanded(
                child: _SignalMetric(
                  label: 'Last 7 days',
                  value: _formatCurrency(signal.currentAmount),
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: _SignalMetric(
                  label: 'Prior week',
                  value: _formatCurrency(signal.previousAmount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalMetric extends StatelessWidget {
  const _SignalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(MfSpace.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(MfRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickActionModel> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - MfSpace.md * 2) / 3
            : (constraints.maxWidth - MfSpace.md) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              overline: 'Component library sketch',
              title: 'Most likely next actions',
              subtitle:
                  'High-confidence shortcuts stay visible as tactile cards instead of hiding behind menus.',
            ),
            const SizedBox(height: MfSpace.md),
            Wrap(
              spacing: MfSpace.md,
              runSpacing: MfSpace.md,
              children: actions.map((action) {
                final itemWidth =
                    actions.length == 3 && constraints.maxWidth < 720
                    ? width
                    : (constraints.maxWidth - MfSpace.md * 2) / 3;
                return SizedBox(
                  width: itemWidth,
                  child: AppCard(
                    glass: true,
                    onTap: action.onTap,
                    padding: const EdgeInsets.all(MfSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: action.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(MfRadius.md),
                          ),
                          child: Icon(action.icon, color: action.accent),
                        ),
                        const SizedBox(height: MfSpace.lg),
                        Text(
                          action.title,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.45,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _FlowPanel extends StatelessWidget {
  const _FlowPanel({
    required this.trend,
    required this.income,
    required this.expense,
    required this.savings,
  });

  final List<_TrendPoint> trend;
  final double income;
  final double expense;
  final double savings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (trend.isEmpty) {
      return const LedgerEmptyState(
        title: 'Not enough history yet',
        subtitle:
            'Add income and expenses across a few weeks and this chart will turn into your at-a-glance financial map.',
        icon: Icons.show_chart_rounded,
      );
    }

    final incomes = trend.map((entry) => entry.income).toList();
    final expenses = trend.map((entry) => entry.expense).toList();
    final maxY = [
      ...incomes,
      ...expenses,
    ].fold<double>(0, (best, value) => value > best ? value : best);
    final averageExpense =
        expenses.fold<double>(0, (a, b) => a + b) /
        (expenses.isEmpty ? 1 : expenses.length);

    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _LegendChip(label: 'Income', color: MfPalette.incomeGreen),
              SizedBox(width: MfSpace.sm),
              _LegendChip(label: 'Expenses', color: MfPalette.expenseRed),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 100 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 25 : maxY * 0.3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, _) => Text(
                        value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : value.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthShortLabel(trend[index].monthKey),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.52),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => cs.inverseSurface,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final label = spot.barIndex == 0 ? 'Income' : 'Expenses';
                      return LineTooltipItem(
                        '$label\n${_formatCurrency(spot.y)}',
                        GoogleFonts.inter(
                          color: cs.onInverseSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.34,
                    barWidth: 3.2,
                    color: MfPalette.incomeGreen,
                    isStrokeCapRound: true,
                    spots: List.generate(
                      trend.length,
                      (index) => FlSpot(index.toDouble(), trend[index].income),
                    ),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MfPalette.incomeGreen.withValues(alpha: 0.2),
                          MfPalette.incomeGreen.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.34,
                    barWidth: 3.2,
                    color: MfPalette.expenseRed,
                    isStrokeCapRound: true,
                    spots: List.generate(
                      trend.length,
                      (index) => FlSpot(index.toDouble(), trend[index].expense),
                    ),
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MfPalette.expenseRed.withValues(alpha: 0.16),
                          MfPalette.expenseRed.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Row(
            children: [
              Expanded(
                child: _SignalMetric(
                  label: 'This month income',
                  value: _formatCurrency(income),
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: _SignalMetric(
                  label: 'Avg monthly spend',
                  value: _formatCurrency(averageExpense),
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: _SignalMetric(
                  label: 'Net cash flow',
                  value: _formatCurrency(savings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.md,
        vertical: MfSpace.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiConciergeCard extends StatelessWidget {
  const _AiConciergeCard({required this.summary, this.highlight});

  final String summary;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.96),
            MfPalette.insightBlue.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.26),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MfRadius.xl),
          onTap: () {
            Navigator.of(context).push(
              LedgerPageRoutes.fadeSlide<void>(
                const InsightsScreen(initialTab: InsightsEntryTab.chat),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Design rationale',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MfPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(MfRadius.md),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: MfSpace.md),
                    Expanded(
                      child: Text(
                        'AI concierge',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MfSpace.lg),
                Text(
                  summary.isEmpty
                      ? 'Open the AI desk for a fresh monthly summary, category warnings, and targeted suggestions.'
                      : summary,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
                if (highlight != null && highlight!.isNotEmpty) ...[
                  const SizedBox(height: MfSpace.lg),
                  Container(
                    padding: const EdgeInsets.all(MfSpace.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(MfRadius.md),
                    ),
                    child: Text(
                      highlight!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.overline,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String overline;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: cs.onSurface.withValues(alpha: 0.48),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _GlassLoadingCard extends StatelessWidget {
  const _GlassLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      glass: true,
      child: SizedBox(
        height: height,
        child: AppSkeleton(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(MfRadius.lg),
            ),
          ),
        ),
      ),
    );
  }
}
