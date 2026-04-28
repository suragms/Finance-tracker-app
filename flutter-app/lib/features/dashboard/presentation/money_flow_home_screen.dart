import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api_config.dart';
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
import '../../accounts/application/account_providers.dart';
import '../../accounts/presentation/account_setup_screen.dart';

final dashboardSelectedAccountProvider = StateProvider.autoDispose<String?>((ref) => null);

abstract final class _DashboardColors {
  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color income = Color(0xFF10B981); // green-500
  static const Color expense = Color(0xFFF59E0B); // amber-500 (Never Red)
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color cardBg = Colors.white;
}

double _toDouble(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0;

String _formatInr(double value) {
  final digits = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: digits,
  ).format(value);
}

class MoneyFlowHomeScreen extends ConsumerWidget {
  const MoneyFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final selectedAccountId = ref.watch(dashboardSelectedAccountProvider);
    
    final accounts = accountsAsync.valueOrNull?.accounts ?? [];
    
    if (accountsAsync.hasValue && accounts.isEmpty && !kNoApiMode) {
      return _buildNoAccountsEmptyState(context);
    }

    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: RefreshIndicator(
        color: _DashboardColors.primary,
        onRefresh: () async {
          await ref.read(ledgerSyncServiceProvider).pullAndFlush();
          ref.invalidate(dashboardOverviewProvider);
          ref.invalidate(expensesProvider);
          ref.invalidate(incomesProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const _Header(),
                      const SizedBox(height: 24),
                      _HeroBalanceCard(
                        accounts: accounts,
                        expenses: expensesAsync.valueOrNull ?? [],
                        incomes: incomesAsync.valueOrNull ?? [],
                        selectedAccountId: selectedAccountId,
                      ),
                      const SizedBox(height: 32),
                      const _QuickActions(),
                      const SizedBox(height: 32),
                      _RecentTransactions(
                        expenses: expensesAsync.valueOrNull ?? [],
                        incomes: incomesAsync.valueOrNull ?? [],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountsEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_rounded, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _DashboardColors.textPrimary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSetupScreen())),
              child: const Text('Setup Account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MoneyFlow AI',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _DashboardColors.textPrimary,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMM').format(DateTime.now()),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _DashboardColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE5E7EB)),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: _DashboardColors.textPrimary),
        ),
      ],
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.accounts,
    required this.expenses,
    required this.incomes,
    this.selectedAccountId,
  });

  final List<dynamic> accounts;
  final List<dynamic> expenses;
  final List<dynamic> incomes;
  final String? selectedAccountId;

  @override
  Widget build(BuildContext context) {
    double totalBalance = 0;
    if (selectedAccountId == null) {
      for (final a in accounts) totalBalance += _toDouble(a['balance']);
    } else {
      final acc = accounts.firstWhere((a) => a['id']?.toString() == selectedAccountId, orElse: () => {});
      totalBalance = _toDouble(acc['balance']);
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final monthExp = expenses.where((e) {
      final d = DateTime.tryParse(e['date']?.toString() ?? '');
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold<double>(0, (s, e) => s + _toDouble(e['amount']).abs());

    final monthInc = incomes.where((e) {
      final d = DateTime.tryParse(e['date']?.toString() ?? '');
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).fold<double>(0, (s, e) => s + _toDouble(e['amount']).abs());

    final profit = monthInc - monthExp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _DashboardColors.primary,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        boxShadow: [
          BoxShadow(
            color: _DashboardColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            _formatInr(totalBalance),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Income', amount: monthInc, icon: Icons.arrow_downward, color: _DashboardColors.income)),
              const SizedBox(width: 16),
              Expanded(child: _HeroStat(label: 'Expense', amount: monthExp, icon: Icons.arrow_upward, color: _DashboardColors.expense)),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Profit', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              Text(
                _formatInr(profit),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.amount, required this.icon, required this.color});
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
              Text(
                _formatInr(amount),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(label: 'Income', icon: Icons.add_circle_outline, color: _DashboardColors.income, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomeScreen()))),
        _ActionItem(label: 'Expense', icon: Icons.remove_circle_outline, color: _DashboardColors.expense, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()))),
        _ActionItem(label: 'Reports', icon: Icons.analytics_outlined, color: _DashboardColors.primary, onTap: () {}),
        _ActionItem(label: 'History', icon: Icons.history, color: _DashboardColors.textSecondary, onTap: () {}),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _DashboardColors.textPrimary)),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.expenses, required this.incomes});
  final List<dynamic> expenses;
  final List<dynamic> incomes;

  @override
  Widget build(BuildContext context) {
    final all = <_TxItem>[];
    for (final e in expenses) {
      all.add(_TxItem(
        id: e['id']?.toString() ?? UniqueKey().toString(),
        title: e['note']?.toString() ?? (e['category'] is Map ? e['category']['name'] : 'Expense'),
        subtitle: e['category'] is Map ? e['category']['name'] : 'General',
        amount: -_toDouble(e['amount']).abs(),
        date: DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now(),
        color: _DashboardColors.expense,
        icon: Icons.upload_rounded,
      ));
    }
    for (final i in incomes) {
      all.add(_TxItem(
        id: i['id']?.toString() ?? UniqueKey().toString(),
        title: i['note']?.toString() ?? i['source']?.toString() ?? 'Income',
        subtitle: i['source']?.toString() ?? 'General',
        amount: _toDouble(i['amount']).abs(),
        date: DateTime.tryParse(i['date']?.toString() ?? '') ?? DateTime.now(),
        color: _DashboardColors.income,
        icon: Icons.download_rounded,
      ));
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    final display = all.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _DashboardColors.textPrimary)),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        if (display.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('No transactions yet', style: GoogleFonts.inter(color: _DashboardColors.textSecondary)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = display[index];
              return Container(
                key: ValueKey(item.id),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _DashboardColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(item.subtitle, style: GoogleFonts.inter(fontSize: 12, color: _DashboardColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _formatInr(item.amount),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: item.amount >= 0 ? _DashboardColors.income : _DashboardColors.expense),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TxItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final Color color;
  final IconData icon;
  _TxItem({required this.id, required this.title, required this.subtitle, required this.amount, required this.date, required this.color, required this.icon});
}
