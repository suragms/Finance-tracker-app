import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api_config.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/futuristic_balance_card.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/application/income_providers.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../shell/presentation/quick_create_sheet.dart';
import '../application/dashboard_providers.dart';

final userEmailProvider = Provider<String?>((ref) {
  return ref.read(tokenStorageProvider).userEmail;
});

abstract final class _DashboardColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color backgroundSecondary = Color(0xFF141414);
  static const Color panel = Color(0xCC171717);
  static const Color panelSoft = Color(0x881C1C1C);
  static const Color border = Color(0x22FFFFFF);
  static const Color textPrimary = Color(0xFFF7F8F3);
  static const Color textSecondary = Color(0xFF8D93A1);
  static const Color lime = Color(0xFFE6FF4D);
  static const Color limeSoft = Color(0xFFF3FD6F);
  static const Color cyan = Color(0xFF4ACBFF);
  static const Color positive = Color(0xFFE6FF4D);
  static const Color negative = Color(0xFFFF6B7D);
}

double? _tryDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw == null) return null;
  return double.tryParse(raw.toString().replaceAll(',', ''));
}

double _toDouble(dynamic raw) => _tryDouble(raw) ?? 0;

String _formatCurrency(dynamic raw, {bool placeholderOnInvalid = false}) {
  final value = _tryDouble(raw);
  if (value == null) {
    return placeholderOnInvalid ? '--' : '${MfCurrency.symbol}0';
  }

  final digits = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: digits,
  ).format(value);
}

String _formatSignedCurrency(double value) {
  final body = _formatCurrency(value.abs());
  return value >= 0 ? '+$body' : '-$body';
}

String _greetingFirstName(String? email) {
  if (email == null || email.isEmpty) return 'there';
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'there';
  return local[0].toUpperCase() + local.substring(1);
}

String _humanizeLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r'[_\-\s]+'));
  return parts
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _formatMonthLabel(String raw) {
  final parsed = DateTime.tryParse('$raw-01');
  if (parsed == null) return raw;
  return DateFormat('MMM yyyy').format(parsed);
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _formatActivityDate(DateTime? date) {
  if (date == null) return 'Pending';
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final difference = today.difference(target).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return DateFormat('dd MMM').format(local);
}

IconData _expenseIconFor(String label) {
  final text = label.toLowerCase();
  if (text.contains('food') || text.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (text.contains('grocery') || text.contains('shopping')) {
    return Icons.shopping_bag_rounded;
  }
  if (text.contains('transport') ||
      text.contains('travel') ||
      text.contains('fuel') ||
      text.contains('cab')) {
    return Icons.directions_car_rounded;
  }
  if (text.contains('bill') ||
      text.contains('utility') ||
      text.contains('electric')) {
    return Icons.bolt_rounded;
  }
  if (text.contains('health') || text.contains('medical')) {
    return Icons.favorite_rounded;
  }
  return Icons.arrow_upward_rounded;
}

IconData _incomeIconFor(String label) {
  final text = label.toLowerCase();
  if (text.contains('salary') || text.contains('payroll')) {
    return Icons.work_rounded;
  }
  if (text.contains('business')) {
    return Icons.storefront_rounded;
  }
  if (text.contains('refund')) {
    return Icons.rotate_left_rounded;
  }
  return Icons.arrow_downward_rounded;
}

Future<void> _refreshDashboard(WidgetRef ref) async {
  await ref.read(ledgerSyncServiceProvider).pullAndFlush();
  ref.invalidate(dashboardOverviewProvider);
  ref.invalidate(expensesProvider);
  ref.invalidate(incomesProvider);
}

void _openExpenseFlow(BuildContext context) {
  Navigator.of(
    context,
  ).push(LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()));
}

void _openIncomeFlow(BuildContext context) {
  if (kNoApiMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Income capture is available when the live API is connected.',
        ),
      ),
    );
    return;
  }

  Navigator.of(
    context,
  ).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
}

void _openInsights(BuildContext context) {
  Navigator.of(
    context,
  ).push(LedgerPageRoutes.fadeSlide<void>(const InsightsScreen()));
}

class _HomeSummary {
  const _HomeSummary({
    required this.balanceLabel,
    required this.balance,
    required this.monthLabel,
    required this.income,
    required this.expense,
    required this.cashFlow,
  });

  final String balanceLabel;
  final String balance;
  final String monthLabel;
  final double income;
  final double expense;
  final double cashFlow;

  factory _HomeSummary.fromDashboard(Map<String, dynamic> raw) {
    final netWorthRaw = raw['netWorth'];
    final netWorth = netWorthRaw is Map
        ? Map<String, dynamic>.from(netWorthRaw)
        : <String, dynamic>{};
    final thisMonthRaw = raw['thisMonth'];
    final thisMonth = thisMonthRaw is Map
        ? Map<String, dynamic>.from(thisMonthRaw)
        : <String, dynamic>{};
    final savings = thisMonth['netSavings'] ?? thisMonth['netCashFlow'];

    return _HomeSummary(
      balanceLabel: netWorth['label']?.toString().trim().isNotEmpty == true
          ? netWorth['label']!.toString()
          : 'Available balance',
      balance: _formatCurrency(
        netWorth['netWorth'],
        placeholderOnInvalid: true,
      ),
      monthLabel: _formatMonthLabel(
        thisMonth['month']?.toString() ??
            DateFormat('yyyy-MM').format(DateTime.now()),
      ),
      income: _toDouble(thisMonth['totalIncome']),
      expense: _toDouble(thisMonth['totalExpenses']),
      cashFlow: _toDouble(savings),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.positive,
    required this.timestamp,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final bool positive;
  final DateTime? timestamp;
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

List<_ActivityItem> _buildActivityItems({
  required List<Map<String, dynamic>> expenses,
  required List<Map<String, dynamic>> incomes,
}) {
  final items = <_ActivityItem>[
    ...expenses.map((expense) {
      final category = expense['category'] is Map
          ? Map<String, dynamic>.from(expense['category'] as Map)
          : <String, dynamic>{};
      final categoryName = category['name']?.toString().trim() ?? '';
      final note = expense['note']?.toString().trim() ?? '';
      final date = _parseDate(expense['date']);
      final title = note.isNotEmpty
          ? note
          : categoryName.isNotEmpty
          ? categoryName
          : 'Card payment';
      final label = categoryName.isNotEmpty && categoryName != title
          ? categoryName
          : 'Expense';

      return _ActivityItem(
        title: title,
        subtitle: '$label · ${_formatActivityDate(date)}',
        amount: -_toDouble(expense['amount']),
        icon: _expenseIconFor(categoryName.isNotEmpty ? categoryName : title),
        positive: false,
        timestamp: date,
      );
    }),
    ...incomes.map((income) {
      final source = _humanizeLabel(income['source']?.toString() ?? '');
      final note = income['note']?.toString().trim() ?? '';
      final date = _parseDate(income['date']);
      final title = note.isNotEmpty
          ? note
          : source.isNotEmpty
          ? source
          : 'Incoming transfer';
      final label = source.isNotEmpty && source != title ? source : 'Income';

      return _ActivityItem(
        title: title,
        subtitle: '$label · ${_formatActivityDate(date)}',
        amount: _toDouble(income['amount']),
        icon: _incomeIconFor(source.isNotEmpty ? source : title),
        positive: true,
        timestamp: date,
      );
    }),
  ];

  items.sort((a, b) {
    final aDate = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  return items.take(6).toList();
}

class MoneyFlowHomeScreen extends ConsumerWidget {
  const MoneyFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardOverviewProvider);
    final expenses = ref.watch(expensesProvider);
    final incomes = ref.watch(incomesProvider);
    final name = _greetingFirstName(ref.watch(userEmailProvider));
    final bottomPadding = MediaQuery.of(context).padding.bottom + 108;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _DashboardBackdrop(),
          RefreshIndicator(
            color: _DashboardColors.lime,
            backgroundColor: _DashboardColors.backgroundSecondary,
            onRefresh: () async {
              await _refreshDashboard(ref);
              await ref.read(dashboardOverviewProvider.future);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        MfSpace.lg,
                        MfSpace.lg,
                        MfSpace.lg,
                        bottomPadding,
                      ),
                      child: overview.when(
                        data: (raw) {
                          final summary = _HomeSummary.fromDashboard(raw);
                          final activity = _buildActivityItems(
                            expenses: expenses.maybeWhen(
                              data: (value) => value,
                              orElse: () => const <Map<String, dynamic>>[],
                            ),
                            incomes: incomes.maybeWhen(
                              data: (value) => value,
                              orElse: () => const <Map<String, dynamic>>[],
                            ),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileHeader(name: name),
                              if (kNoApiMode) ...[
                                const SizedBox(height: MfSpace.lg),
                                const _ModeChip(),
                              ],
                              const SizedBox(height: MfSpace.xxl),
                              _BalanceCard(summary: summary),
                              const SizedBox(height: MfSpace.xl),
                              _QuickActionsRow(
                                actions: [
                                  _QuickAction(
                                    label: 'Send',
                                    icon: Icons.north_east_rounded,
                                    accent: _DashboardColors.lime,
                                    onTap: () => _openExpenseFlow(context),
                                  ),
                                  _QuickAction(
                                    label: 'Receive',
                                    icon: Icons.south_west_rounded,
                                    accent: _DashboardColors.cyan,
                                    onTap: () => _openIncomeFlow(context),
                                  ),
                                  _QuickAction(
                                    label: 'Add',
                                    icon: Icons.add_rounded,
                                    accent: _DashboardColors.limeSoft,
                                    onTap: () =>
                                        showMoneyFlowQuickCreateSheet(context),
                                  ),
                                  _QuickAction(
                                    label: 'More',
                                    icon: Icons.more_horiz_rounded,
                                    accent: Colors.white,
                                    onTap: () => _openInsights(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              const _SectionHeader(
                                eyebrow: 'Recent activity',
                                title: 'Transactions',
                                subtitle:
                                    'A clean view of the latest money movement.',
                              ),
                              const SizedBox(height: MfSpace.md),
                              if (activity.isNotEmpty)
                                _TransactionsCard(items: activity)
                              else if (expenses.isLoading || incomes.isLoading)
                                const _TransactionsSkeleton()
                              else
                                const _EmptyTransactionsCard(),
                            ],
                          );
                        },
                        loading: () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _ProfileHeader(name: 'there'),
                            SizedBox(height: MfSpace.xxl),
                            _BalanceCardSkeleton(),
                            SizedBox(height: MfSpace.xl),
                            _QuickActionsSkeleton(),
                            SizedBox(height: 28),
                            _TransactionsSkeleton(),
                          ],
                        ),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileHeader(name: name),
                            const SizedBox(height: MfSpace.xxl),
                            _ErrorPanel(message: error.toString()),
                          ],
                        ),
                      ),
                    ),
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

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _DashboardColors.background,
                _DashboardColors.backgroundSecondary,
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _DashboardColors.lime.withValues(alpha: 0.18),
                    _DashboardColors.lime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _DashboardColors.cyan.withValues(alpha: 0.18),
                    _DashboardColors.cyan.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'Y' : name[0].toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _DashboardColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi, $name',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _DashboardColors.textPrimary,
                  letterSpacing: -0.9,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_DashboardColors.lime, _DashboardColors.cyan],
            ),
            boxShadow: [
              BoxShadow(
                color: _DashboardColors.lime.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D0D0D),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.md,
        vertical: MfSpace.sm,
      ),
      decoration: BoxDecoration(
        color: _DashboardColors.panelSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: _DashboardColors.limeSoft,
          ),
          const SizedBox(width: 8),
          Text(
            'Demo mode',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _DashboardColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(MfSpace.xl),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _DashboardColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _DashboardColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5C000000),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final _HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return FuturisticBalanceCard(
      balanceLabel: summary.balanceLabel,
      amountDisplay: summary.balance,
      monthBadge: summary.monthLabel,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.cashFlow >= 0
                ? 'You are tracking ahead this month.'
                : 'Spending is running higher than income this month.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  label: 'Income',
                  value: _formatCurrency(summary.income),
                ),
              ),
              const SizedBox(width: MfSpace.sm),
              Expanded(
                child: _BalanceMetric(
                  label: 'Spent',
                  value: _formatCurrency(summary.expense),
                ),
              ),
              const SizedBox(width: MfSpace.sm),
              Expanded(
                child: _BalanceMetric(
                  label: 'Cash flow',
                  value: _formatSignedCurrency(summary.cashFlow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(MfSpace.md),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(MfSpace.lg),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _QuickActionButton(action: action),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed
          ? 0.96
          : _hovered
          ? 1.01
          : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.action.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MfSpace.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: MfMotion.fast,
                  curve: MfMotion.curve,
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: widget.action.accent.withValues(
                      alpha: widget.action.accent == Colors.white ? 0.08 : 0.14,
                    ),
                    border: Border.all(
                      color: widget.action.accent.withValues(
                        alpha: widget.action.accent == Colors.white
                            ? 0.14
                            : 0.22,
                      ),
                    ),
                    boxShadow: _pressed
                        ? const []
                        : [
                            BoxShadow(
                              color: widget.action.accent.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                  ),
                  child: Icon(widget.action.icon, color: widget.action.accent),
                ),
                const SizedBox(height: MfSpace.sm),
                Text(
                  widget.action.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _DashboardColors.textPrimary,
                  ),
                ),
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
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _DashboardColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            color: _DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: _DashboardColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _TransactionRow(item: items[i]),
            if (i != items.length - 1)
              Divider(
                color: Colors.white.withValues(alpha: 0.06),
                height: MfSpace.xl,
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatefulWidget {
  const _TransactionRow({required this.item});

  final _ActivityItem item;

  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.item.positive
        ? _DashboardColors.positive
        : _DashboardColors.negative;

    return AnimatedScale(
      scale: _pressed
          ? 0.99
          : _hovered
          ? 1.005
          : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MfSpace.sm),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(widget.item.icon, color: accent),
                ),
                const SizedBox(width: MfSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _DashboardColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _DashboardColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MfSpace.md),
                Text(
                  _formatSignedCurrency(widget.item.amount),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _DashboardColors.limeSoft,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your latest payments and inflows will land here as soon as they are recorded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: _DashboardColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _DashboardColors.negative,
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            'Dashboard unavailable',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: _DashboardColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(MfSpace.lg),
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppSkeleton(
                child: Container(
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : MfSpace.md),
          child: _GlassPanel(
            padding: const EdgeInsets.all(MfSpace.lg),
            child: AppSkeleton(
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
