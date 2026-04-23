import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api_config.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/application/income_providers.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../shell/presentation/quick_create_sheet.dart';
import '../application/dashboard_providers.dart';
import '../../accounts/application/account_providers.dart';
import '../../accounts/presentation/account_setup_screen.dart';

final dashboardSelectedAccountProvider = StateProvider.autoDispose<String?>((ref) => null);

final userEmailProvider = Provider<String?>((ref) {
  return ref.read(tokenStorageProvider).userEmail;
});

abstract final class _DashboardColors {
  static const Color background = Color(0xFF0B0F1A);
  static const Color panel = Color(0xFF1F2937); // Subtle card colors
  static const Color panelSoft = Color(0xFF1F2937);
  static const Color border = Color(0xFF374151); // Minimal overlap
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color lime = Color(0xFF6366F1); // Accent color
  static const Color limeSoft = Color(0xFF818CF8);
  static const Color cyan = Color(0xFF3B82F6);
  static const Color positive = Color(0xFF10B981);
  static const Color negative = Color(0xFFEF4444);
}

double? _tryDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse((raw?.toString() ?? '0').replaceAll(',', ''));
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

class _InsightsStrip extends ConsumerWidget {
  const _InsightsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kNoApiMode) return const SizedBox.shrink();
    final async = ref.watch(insightsSnapshotProvider);
    return async.when(
      data: (d) {
        final alerts = d['alerts'] as List? ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart insights',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _DashboardColors.textSecondary,
              ),
            ),
            const SizedBox(height: MfSpace.sm),
            ...alerts.map((raw) {
              final a = Map<String, dynamic>.from(raw as Map);
              final sev = a['severity']?.toString() ?? 'info';
              final bg = sev == 'warn'
                  ? const Color(0x33FF6B7D)
                  : const Color(0x224ACBFF);
              return Padding(
                padding: const EdgeInsets.only(bottom: MfSpace.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(MfSpace.md),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _DashboardColors.border),
                  ),
                  child: Text(
                    a['message']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: _DashboardColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class MoneyFlowHomeScreen extends ConsumerWidget {
  const MoneyFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final selectedAccountId = ref.watch(dashboardSelectedAccountProvider);
    final name = _greetingFirstName(ref.watch(userEmailProvider));
    final bottomPadding = MediaQuery.of(context).padding.bottom + 108;

    final accounts = accountsAsync.valueOrNull?.accounts ?? [];
    
    // Check global Empty State for NO ACCOUNTS
    if (accountsAsync.hasValue && accounts.isEmpty && !kNoApiMode) {
      return _buildNoAccountsEmptyState(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _DashboardBackdrop(),
          RefreshIndicator(
            color: _DashboardColors.lime,
            backgroundColor: _DashboardColors.background,
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
                    child: Builder(
                      builder: (ctx) {
                        final eList = expensesAsync.valueOrNull ?? [];
                        final iList = incomesAsync.valueOrNull ?? [];
                        
                        var filteredExpenses = eList;
                        var filteredIncomes = iList;
                        String accountLabel = 'All Accounts';
                        double accountBalance = 0;

                        if (selectedAccountId == null) {
                           for (final a in accounts) {
                             accountBalance += _toDouble(a['balance']);
                           }
                        } else {
                           final acc = accounts.firstWhere((a) => a['id']?.toString() == selectedAccountId, orElse: () => <String, dynamic>{});
                           if (acc.isNotEmpty) {
                              accountLabel = acc['name']?.toString() ?? 'Account';
                              accountBalance = _toDouble(acc['balance']);
                           }
                           filteredExpenses = filteredExpenses.where((e) {
                              final aid = e['account'] is Map ? (e['account'] as Map)['id']?.toString() : e['accountId']?.toString();
                              return aid == selectedAccountId;
                           }).toList();
                           filteredIncomes = filteredIncomes.where((i) {
                              final aid = i['account'] is Map ? (i['account'] as Map)['id']?.toString() : i['accountId']?.toString();
                              return aid == selectedAccountId;
                           }).toList();
                        }

                        // Local month aggregation
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month);
                        final end = DateTime(now.year, now.month + 1);

                        final mExp = filteredExpenses.where((e) {
                          final d = _parseDate(e['date']);
                          return d != null && !d.isBefore(start) && d.isBefore(end);
                        });
                        final mInc = filteredIncomes.where((e) {
                          final d = _parseDate(e['date']);
                          return d != null && !d.isBefore(start) && d.isBefore(end);
                        });

                        final monthExpTotal = mExp.fold<double>(0, (s, e) => s + _toDouble(e['amount']));
                        final monthIncTotal = mInc.fold<double>(0, (s, e) => s + _toDouble(e['amount']));
                        final cashFlow = monthIncTotal - monthExpTotal;

                        final summary = _HomeSummary(
                          balanceLabel: 'Available balance',
                          balance: _formatCurrency(accountBalance),
                          monthLabel: _formatMonthLabel(DateFormat('yyyy-MM').format(now)),
                          income: monthIncTotal,
                          expense: monthExpTotal,
                          cashFlow: cashFlow,
                        );

                        final activity = _buildActivityItems(expenses: filteredExpenses, incomes: filteredIncomes);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileHeader(name: name),
                              if (kNoApiMode) ...[
                                const SizedBox(height: MfSpace.lg),
                                const _ModeChip(),
                              ],
                              const SizedBox(height: MfSpace.xl),

                              // Account Switcher / Header
                              _DashboardAccountHeader(
                                currentAccountName: accountLabel,
                                currentBalance: accountBalance,
                                accounts: accounts,
                                selectedAccountId: selectedAccountId,
                                onAccountSelected: (id) => ref.read(dashboardSelectedAccountProvider.notifier).state = id,
                              ),
                              const SizedBox(height: MfSpace.xl),

                              const _InsightsStrip(),
                              const SizedBox(height: MfSpace.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Income',
                                      amount: _formatCurrency(summary.income),
                                      icon: Icons.arrow_downward_rounded,
                                      color: _DashboardColors.positive,
                                    ),
                                  ),
                                  const SizedBox(width: MfSpace.sm),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Expense',
                                      amount: _formatCurrency(summary.expense),
                                      icon: Icons.arrow_upward_rounded,
                                      color: _DashboardColors.negative,
                                    ),
                                  ),
                                  const SizedBox(width: MfSpace.sm),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Cashflow',
                                      amount: _formatSignedCurrency(summary.cashFlow),
                                      icon: Icons.swap_vert_rounded,
                                      color: summary.cashFlow >= 0 ? _DashboardColors.textPrimary : _DashboardColors.negative,
                                    ),
                                  ),
                                ],
                              ),
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
                              else if (expensesAsync.isLoading || incomesAsync.isLoading)
                                const _TransactionsSkeleton()
                              else
                                _EmptyTransactionsCard(
                                  onRecordTap: () =>
                                      showMoneyFlowQuickCreateSheet(context),
                                ),
                            ],
                          );
                      },
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
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: _DashboardColors.background),
  );
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
          child: Text(
            'Hi, $name 👋',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: _DashboardColors.panelSoft,
          child: Text(
            initial,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
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
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _DashboardColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final _HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DashboardColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.balanceLabel,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _DashboardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.balance,
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: _DashboardColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '•••• •••• •••• 8924',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _DashboardColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.credit_card_rounded, color: _DashboardColors.textSecondary, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.amount, required this.icon, required this.color});

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DashboardColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _DashboardColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _DashboardColors.textPrimary,
              ),
            ),
          ),
        ],
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

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.accent),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _DashboardColors.textPrimary,
                ),
              ),
            ],
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

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.positive
        ? _DashboardColors.positive
        : _DashboardColors.negative;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _DashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatSignedCurrency(item.amount),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard({required this.onRecordTap});

  final VoidCallback onRecordTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _DashboardColors.panelSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white38, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            "NO TRANSACTIONS YET",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your financial insights will appear here once you record your first activity.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRecordTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _DashboardColors.textSecondary),
              foregroundColor: _DashboardColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text("Add Transaction", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

  Widget _buildNoAccountsEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 60, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 32),
              Text(
                "Start by creating your first account",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Track your cash, bank balances, and wallets accurately by establishing an account first.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountSetupScreen(isInitialSetup: false)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text("Create Account", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

class _DashboardAccountHeader extends StatelessWidget {
  const _DashboardAccountHeader({
    required this.currentAccountName,
    required this.currentBalance,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
  });

  final String currentAccountName;
  final double currentBalance;
  final List<dynamic> accounts;
  final String? selectedAccountId;
  final void Function(String?) onAccountSelected;

  void _showAccountPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _DashboardColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Switch Account', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: MfPalette.primaryIndigo),
              title: Text('All Accounts', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              trailing: selectedAccountId == null ? const Icon(Icons.check_circle, color: MfPalette.primaryIndigo) : null,
              onTap: () {
                onAccountSelected(null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(color: Colors.white10, indent: 64),
            ...accounts.map((a) {
              final isSelected = selectedAccountId == a['id']?.toString();
              return ListTile(
                leading: Icon(
                  Icons.account_balance_rounded,
                  color: isSelected ? MfPalette.incomeGreen : Colors.white70,
                ),
                title: Text(a['name']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
                subtitle: Text(
                  MfCurrency.formatInr(double.tryParse(a['balance']?.toString() ?? '0') ?? 0),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: MfPalette.incomeGreen) : null,
                onTap: () {
                  onAccountSelected(a['id']?.toString());
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showAccountPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selectedAccountId == null ? MfPalette.primaryIndigo.withValues(alpha: 0.2) : MfPalette.incomeGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedAccountId == null ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded,
                          color: selectedAccountId == null ? MfPalette.primaryIndigo : MfPalette.incomeGreen,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentAccountName,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(currentBalance),
            style: GoogleFonts.manrope(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Portfolio Balance',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
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
