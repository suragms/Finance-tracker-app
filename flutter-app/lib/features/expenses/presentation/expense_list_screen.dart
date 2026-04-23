import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/transaction_tile.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../application/expense_providers.dart';

enum _ListFilter { all, expense, income, recurring }

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key, this.accountId, this.accountName});

  final String? accountId;
  final String? accountName;

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  _ListFilter _filter = _ListFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = widget.accountId != null
        ? ref.watch(expensesForAccountProvider(widget.accountId!))
        : ref.watch(expensesProvider);

    return Container(
      decoration: const BoxDecoration(gradient: mfPremiumCanvasGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // TOP: Filter Tabs (Sticky Header)
            SliverAppBar(
              backgroundColor: MfPalette.canvas.withValues(alpha: 0.1),
              floating: true,
              pinned: true,
              elevation: 0,
              expandedHeight: 0,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _FilterTab(label: 'All Activity', selected: _filter == _ListFilter.all, onTap: () => setState(() => _filter = _ListFilter.all)),
                          _FilterTab(label: 'Spent', selected: _filter == _ListFilter.expense, onTap: () => setState(() => _filter = _ListFilter.expense)),
                          _FilterTab(label: 'Income', selected: _filter == _ListFilter.income, onTap: () => setState(() => _filter = _ListFilter.income)),
                          _FilterTab(label: 'Recurring', selected: _filter == _ListFilter.recurring, onTap: () => setState(() => _filter = _ListFilter.recurring)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // LIST: Grouped History
            async.when(
              data: (list) {
                final filtered = list.where((e) {
                  final amt = double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
                  if (_filter == _ListFilter.expense) return amt < 0;
                  if (_filter == _ListFilter.income) return amt > 0;
                  if (_filter == _ListFilter.recurring) return e['isRecurring'] == true;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white12),
                          const SizedBox(height: 16),
                          Text('No transactions found', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                // Group by Date
                final groups = <DateTime, List<Map<String, dynamic>>>{};
                for (final e in filtered) {
                  final d = DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now();
                  final day = DateTime(d.year, d.month, d.day);
                  groups.putIfAbsent(day, () => []).add(e);
                }
                final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final day = sortedDays[index];
                        final txns = groups[day]!;
                        final isToday = DateUtils.isSameDay(day, DateTime.now());
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                              child: Text(
                                isToday ? 'TODAY' : DateFormat('EEEE, d MMM').format(day).toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white24, letterSpacing: 1.2),
                              ),
                            ),
                            Container(
                              decoration: glassCard(),
                              child: Column(
                                children: txns.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final e = entry.value;
                                  final amt = double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
                                  final systemKey = e['category']?['systemKey']?.toString() ?? 'custom';

                                  return _TransactionItem(
                                    id: e['id']?.toString() ?? 'txn-$index-$i',
                                    title: e['category']?['name']?.toString() ?? 'Transaction',
                                    subtitle: e['note']?.toString() ?? '',
                                    amount: amt,
                                    color: MfCategoryColors.forSystemKey(systemKey),
                                    icon: categoryIconFor(systemKey),
                                    date: day,
                                    animationIndex: i,
                                    showDivider: i < txns.length - 1,
                                    onDelete: () async {
                                      await ref.read(ledgerSyncServiceProvider).deleteExpenseOffline(e['id'].toString());
                                      ref.invalidate(expensesProvider);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: sortedDays.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Colors.white24 : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.icon,
    required this.date,
    required this.animationIndex,
    required this.showDivider,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final Color color;
  final IconData icon;
  final DateTime date;
  final int animationIndex;
  final bool showDivider;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Column(
        children: [
          BuddyTransactionTile(
            title: title,
            subtitle: subtitle,
            amount: amount,
            isExpense: amount < 0,
            categoryColor: color,
            categoryIcon: icon,
            date: date,
            animationIndex: animationIndex,
          ),
          if (showDivider)
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 70),
        ],
      ),
    );
  }
}
