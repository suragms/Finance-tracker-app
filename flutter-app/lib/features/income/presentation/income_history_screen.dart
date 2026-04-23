import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../accounts/application/account_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/income_providers.dart';
import '../data/incomes_api.dart';

enum _IncomeRangeFilter { all, expense, income, thisWeek, thisMonth }

double _amount(dynamic raw) => double.tryParse(raw?.toString() ?? '') ?? 0;
DateTime _date(dynamic raw) =>
    DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();

String _groupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('EEE, d MMM').format(day);
}

String _sourceLabel(String s) =>
    s.isEmpty ? 'Income' : '${s[0].toUpperCase()}${s.substring(1)}';

String _sourceKey(String source) {
  switch (source.toLowerCase()) {
    case 'salary':
      return 'financial';
    case 'business':
      return 'business';
    default:
      return 'custom';
  }
}

class IncomeHistoryScreen extends ConsumerStatefulWidget {
  const IncomeHistoryScreen({super.key});

  @override
  ConsumerState<IncomeHistoryScreen> createState() =>
      _IncomeHistoryScreenState();
}

class _IncomeHistoryScreenState extends ConsumerState<IncomeHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _IncomeRangeFilter _filter = _IncomeRangeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter =>
      _query.isNotEmpty || _filter != _IncomeRangeFilter.all;

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
    ref.invalidate(incomesProvider);
  }

  bool _matchFilter(Map<String, dynamic> row) {
    final now = DateTime.now();
    final d = _date(row['date']);
    switch (_filter) {
      case _IncomeRangeFilter.all:
      case _IncomeRangeFilter.income:
        return true;
      case _IncomeRangeFilter.expense:
        return false;
      case _IncomeRangeFilter.thisWeek:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return !d.isBefore(start);
      case _IncomeRangeFilter.thisMonth:
        return d.year == now.year && d.month == now.month;
    }
  }

  bool _matchQuery(Map<String, dynamic> row) {
    if (_query.isEmpty) return true;
    final text = [
      row['source']?.toString() ?? '',
      row['note']?.toString() ?? '',
      row['amount']?.toString() ?? '',
      row['date']?.toString() ?? '',
    ].join(' ').toLowerCase();
    return text.contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(incomesProvider);
    return Scaffold(
      backgroundColor: MfSurface.base,
      appBar: AppBar(
        backgroundColor: MfSurface.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Income History',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: async.when(
        data: (list) {
          final filtered = list.where(_matchFilter).where(_matchQuery).toList()
            ..sort((a, b) => _date(b['date']).compareTo(_date(a['date'])));

          final groups = <DateTime, List<Map<String, dynamic>>>{};
          for (final row in filtered) {
            final d = _date(row['date']);
            final key = DateTime(d.year, d.month, d.day);
            groups.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(row);
          }
          final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                MfSpace.sm,
                0,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v.trim()),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: MfSurface.inputFill,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            hintText: 'Search transactions...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(99),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _hasActiveFilter
                              ? Theme.of(context).colorScheme.primary
                              : MfSurface.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilter
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MfSpace.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filter == _IncomeRangeFilter.all,
                        onTap: () =>
                            setState(() => _filter = _IncomeRangeFilter.all),
                      ),
                      _FilterChip(
                        label: 'Expense',
                        isSelected: _filter == _IncomeRangeFilter.expense,
                        onTap: () => setState(
                            () => _filter = _IncomeRangeFilter.expense),
                      ),
                      _FilterChip(
                        label: 'Income',
                        isSelected: _filter == _IncomeRangeFilter.income,
                        onTap: () =>
                            setState(() => _filter = _IncomeRangeFilter.income),
                      ),
                      _FilterChip(
                        label: 'This Week',
                        isSelected: _filter == _IncomeRangeFilter.thisWeek,
                        onTap: () => setState(
                            () => _filter = _IncomeRangeFilter.thisWeek),
                      ),
                      _FilterChip(
                        label: 'This Month',
                        isSelected: _filter == _IncomeRangeFilter.thisMonth,
                        onTap: () => setState(
                            () => _filter = _IncomeRangeFilter.thisMonth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MfSpace.sm),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(MfSpace.xxl),
                    child: LedgerEmptyState(
                      title: 'No income found',
                      subtitle: 'Try another filter or add income.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                else
                  ...keys.map((day) {
                    final txns = groups[day]!;
                    final dayTotal = txns.fold<double>(
                        0, (sum, e) => sum + _amount(e['amount']));
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              MfSpace.xxl, MfSpace.lg, MfSpace.xxl, MfSpace.sm),
                          child: Row(
                            children: [
                              Text(
                                _groupLabel(day),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                MfCurrency.formatInr(dayTotal),
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: dayTotal < 0
                                      ? MfPalette.expenseRed
                                      : MfPalette.incomeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppCard(
                          margin: const EdgeInsets.symmetric(
                              horizontal: MfSpace.xxl),
                          padding:
                              const EdgeInsets.symmetric(vertical: MfSpace.sm),
                          child: Column(
                            children: txns.asMap().entries.map((entry) {
                              final i = entry.key;
                              final row = entry.value;
                              final id = row['id']?.toString() ??
                                  '${day.millisecondsSinceEpoch}-$i';
                              final source = row['source']?.toString() ?? '';
                              final note = row['note']?.toString().trim() ?? '';
                              final date = _date(row['date']);
                              final amount = _amount(row['amount']);
                              final key = _sourceKey(source);
                              final color = MfCategoryColors.forSystemKey(key);
                              return Column(
                                children: [
                                  Dismissible(
                                    key: ValueKey('inc-$id'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                          right: MfSpace.xxl),
                                      color: MfPalette.expenseRed,
                                      child: const Icon(Icons.delete_rounded,
                                          color: Colors.white),
                                    ),
                                    onDismissed: (_) async {
                                      try {
                                        await ref
                                            .read(incomesApiProvider)
                                            .delete(id);
                                        await ref
                                            .read(ledgerSyncServiceProvider)
                                            .pullAndFlush();
                                        ref.invalidate(incomesProvider);
                                        ref.invalidate(accountsProvider);
                                        ref.invalidate(monthlySummaryProvider);
                                      } on DioException catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text(dioErrorMessage(e))),
                                          );
                                        }
                                      }
                                    },
                                    child: BuddyTransactionTile(
                                      title: _sourceLabel(source),
                                      subtitle: note,
                                      amount: amount,
                                      isExpense: false,
                                      categoryColor: color,
                                      categoryIcon: categoryIconFor(key),
                                      date: date,
                                      animationIndex: i,
                                    ),
                                  ),
                                  if (i < txns.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: MfSpace.xxl + 44 + MfSpace.md,
                                      color: MfSurface.divider,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(MfSpace.xxl),
          child: LedgerErrorState(
            title: 'Could not load income history',
            message: e is DioException ? dioErrorMessage(e) : e.toString(),
            onRetry: _refresh,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: MfMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : MfSurface.inputFill,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
