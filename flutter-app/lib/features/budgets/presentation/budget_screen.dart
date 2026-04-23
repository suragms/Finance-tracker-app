import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/budget_providers.dart';
import '../data/budgets_api.dart';

double _money(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0;

class _Overview {
  const _Overview(this.spent, this.budget);
  final double spent;
  final double budget;
  double get ratio => budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0;
  double get remaining => budget - spent;
}

_Overview _buildOverview(List<Map<String, dynamic>> rows) {
  var spent = 0.0;
  var budget = 0.0;
  for (final r in rows) {
    spent += _money(r['spent']);
    budget += _money(r['limit']);
  }
  return _Overview(spent, budget);
}

DateTime _parseMonth(String monthKey) {
  final parts = monthKey.split('-');
  final y =
      int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? DateTime.now().year;
  final m =
      int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
  return DateTime(y, m);
}

String _categoryKey(String name) {
  final n = name.toLowerCase();
  if (n.contains('food')) return 'food';
  if (n.contains('house')) return 'household';
  if (n.contains('car') || n.contains('vehicle')) return 'vehicle';
  if (n.contains('insur')) return 'insurance';
  if (n.contains('donat')) return 'donations';
  if (n.contains('business')) return 'business';
  if (n.contains('shop')) return 'shopping';
  if (n.contains('entertain')) return 'entertainment';
  if (n.contains('health')) return 'health';
  if (n.contains('fuel')) return 'fuel';
  if (n.contains('transport')) return 'transport';
  if (n.contains('finance') || n.contains('bank')) return 'financial';
  return 'daily_expenses';
}

IconData _categoryIcon(String key) {
  switch (key) {
    case 'daily_expenses':
      return Icons.shopping_bag_outlined;
    case 'household':
      return Icons.home_outlined;
    case 'vehicle':
      return Icons.directions_car_outlined;
    case 'insurance':
      return Icons.shield_outlined;
    case 'financial':
      return Icons.account_balance_outlined;
    case 'donations':
      return Icons.favorite_outline;
    case 'business':
      return Icons.business_center_outlined;
    case 'food':
      return Icons.restaurant_outlined;
    case 'transport':
      return Icons.directions_bus_outlined;
    case 'shopping':
      return Icons.local_mall_outlined;
    case 'entertainment':
      return Icons.movie_outlined;
    case 'health':
      return Icons.health_and_safety_outlined;
    case 'fuel':
      return Icons.local_gas_station_outlined;
    default:
      return Icons.attach_money_rounded;
  }
}

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = BudgetsApi.monthQueryParam();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
    });
  }

  Future<void> _pull() async {
    await ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
  }

  Future<void> _openAddBudgetSheet() async {
    final categoriesAsync = ref.read(categoriesProvider);
    await categoriesAsync.when(
      data: (list) async {
        final expenseCategories =
            list.where((c) => c['type']?.toString() == 'expense').toList();
        if (expenseCategories.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Create an expense category first.')),
            );
          }
          return;
        }

        String? selectedCategoryId = expenseCategories.first['id']?.toString();
        final amountCtrl = TextEditingController();
        DateTime selectedMonth = _parseMonth(_monthKey);
        bool saved = false;

        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          backgroundColor: MfSurface.card,
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                MfSpace.lg,
                MfSpace.md,
                MfSpace.lg,
                MediaQuery.viewInsetsOf(ctx).bottom + MfSpace.lg,
              ),
              child: StatefulBuilder(
                builder: (_, setModal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: MfSpace.lg),
                      Center(
                        child: Text(
                          'Set Budget',
                          style: GoogleFonts.manrope(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: MfSpace.lg),
                      Text(
                        'Category',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: MfSpace.sm),
                      SizedBox(
                        height: 78,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: expenseCategories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final c = expenseCategories[i];
                            final id = c['id']?.toString();
                            final name = c['name']?.toString() ?? 'Category';
                            final key = _categoryKey(name);
                            final color = MfCategoryColors.forSystemKey(key);
                            final selected = id == selectedCategoryId;
                            return InkWell(
                              onTap: () =>
                                  setModal(() => selectedCategoryId = id),
                              borderRadius: BorderRadius.circular(30),
                              child: SizedBox(
                                width: 62,
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: MfMotion.fast,
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? color
                                            : color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: selected
                                            ? Border.all(color: color, width: 3)
                                            : null,
                                        boxShadow:
                                            selected ? MfShadow.card : null,
                                      ),
                                      child: Icon(
                                        _categoryIcon(key),
                                        color: selected ? Colors.white : color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: MfSpace.lg),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: GoogleFonts.manrope(
                            fontSize: 26, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'Monthly amount',
                          filled: true,
                          fillColor: MfSurface.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(MfRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          prefixText: '${MfCurrency.symbol} ',
                        ),
                      ),
                      const SizedBox(height: MfSpace.md),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedMonth,
                            firstDate: DateTime(DateTime.now().year - 2, 1),
                            lastDate: DateTime(DateTime.now().year + 2, 12),
                          );
                          if (picked != null) {
                            setModal(() => selectedMonth =
                                DateTime(picked.year, picked.month));
                          }
                        },
                        borderRadius: BorderRadius.circular(MfRadius.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(MfSpace.md),
                          decoration: BoxDecoration(
                            color: MfSurface.inputFill,
                            borderRadius: BorderRadius.circular(MfRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMMM yyyy').format(selectedMonth),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MfSpace.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final limit =
                                double.tryParse(amountCtrl.text.trim()) ?? 0;
                            if (selectedCategoryId == null || limit <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Pick category and valid amount')),
                              );
                              return;
                            }
                            _monthKey =
                                '${selectedMonth.year}-${selectedMonth.month}';
                            saved = true;
                            Navigator.of(ctx).pop();
                          },
                          child: Text(
                            'Save Budget',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );

        final limit = double.tryParse(amountCtrl.text.trim()) ?? 0;
        amountCtrl.dispose();
        if (!saved || selectedCategoryId == null || limit <= 0) return;

        try {
          await ref.read(budgetsApiProvider).create(
                categoryId: selectedCategoryId!,
                limit: limit,
                month: _monthKey,
              );
          await _pull();
        } on DioException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(dioErrorMessage(e))),
            );
          }
        }
      },
      loading: () async {},
      error: (_, __) async {},
    );
  }

  Future<void> _openEditBudgetSheet(Map<String, dynamic> row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final limitCtrl =
        TextEditingController(text: _money(row['limit']).toStringAsFixed(0));

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: MfSurface.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          MfSpace.lg,
          MfSpace.md,
          MfSpace.lg,
          MediaQuery.viewInsetsOf(ctx).bottom + MfSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: MfSpace.lg),
            Text(
              'Edit Budget',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: MfSpace.lg),
            TextField(
              controller: limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly amount',
                filled: true,
                fillColor: MfSurface.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  borderSide: BorderSide.none,
                ),
                prefixText: '${MfCurrency.symbol} ',
              ),
            ),
            const SizedBox(height: MfSpace.lg),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop('save'),
                child: const Text('Save')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('delete'),
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
        ),
      ),
    );

    final limit = double.tryParse(limitCtrl.text.trim()) ?? 0;
    limitCtrl.dispose();
    if (action == null) return;

    try {
      if (action == 'save' && limit > 0) {
        await ref.read(budgetsApiProvider).update(id: id, limit: limit);
      } else if (action == 'delete') {
        await ref.read(budgetsApiProvider).delete(id);
      }
      await _pull();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(budgetsForMonthProvider(_monthKey));
    final month = _parseMonth(_monthKey);

    return Scaffold(
      backgroundColor: MfSurface.base,
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
              onPressed: _openAddBudgetSheet,
              icon: const Icon(Icons.add_rounded))
        ],
        elevation: 0,
        backgroundColor: MfSurface.base,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _pull,
        child: async.when(
          data: (rows) {
            final overview = _buildOverview(rows);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _SummaryHero(month: month, overview: overview)),
                if (rows.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(MfSpace.lg),
                        child: Text(
                          'No budgets yet. Tap + to set your first budget.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _BuddyBudgetCard(
                        row: rows[index],
                        month: month,
                        onTap: () => _openEditBudgetSheet(rows[index]),
                      ),
                      childCount: rows.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 88),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(MfSpace.lg),
            child: LedgerErrorState(
              title: 'Could not load budgets',
              message: e is DioException ? dioErrorMessage(e) : e.toString(),
              onRetry: _pull,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.month,
    required this.overview,
  });

  final DateTime month;
  final _Overview overview;

  @override
  Widget build(BuildContext context) {
    final overBudget = overview.spent > overview.budget && overview.budget > 0;
    return Container(
      margin: const EdgeInsets.all(MfSpace.lg),
      padding: const EdgeInsets.all(MfSpace.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MfRadius.xl),
        boxShadow: MfShadow.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MMMM').format(month)} Budget',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                  Text(
                    MfCurrency.formatInr(overview.spent),
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                  Text(
                    MfCurrency.formatInr(overview.budget),
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: overview.ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(
                  overBudget ? MfPalette.expenseRed : const Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${MfCurrency.formatInr(overview.remaining)} remaining',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuddyBudgetCard extends StatelessWidget {
  const _BuddyBudgetCard({
    required this.row,
    required this.month,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryName = row['categoryName']?.toString() ?? 'Category';
    final key = _categoryKey(categoryName);
    final catColor = MfCategoryColors.forSystemKey(key);
    final spent = _money(row['spent']);
    final limit = _money(row['limit']);
    final fraction = limit > 0 ? spent / limit : 0.0;
    final over = spent > limit && limit > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MfRadius.lg),
      child: Container(
        margin:
            const EdgeInsets.fromLTRB(MfSpace.lg, 0, MfSpace.lg, MfSpace.lg),
        padding: const EdgeInsets.all(MfSpace.lg),
        decoration: BoxDecoration(
          color: MfSurface.card,
          borderRadius: BorderRadius.circular(MfRadius.lg),
          boxShadow: MfShadow.card,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_categoryIcon(key), color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(
                      DateFormat('MMMM yyyy').format(month),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MfCurrency.formatInr(spent),
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MfPalette.expenseRed,
                      ),
                    ),
                    Text(
                      'of ${MfCurrency.formatInr(limit)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BuddyProgressBar(fraction: fraction, color: catColor),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  over
                      ? 'Over by ${MfCurrency.formatInr(spent - limit)}'
                      : '${MfCurrency.formatInr(limit - spent)} left',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: over
                        ? MfPalette.expenseRed
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(fraction * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: catColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BuddyProgressBar extends StatelessWidget {
  const _BuddyProgressBar({
    required this.fraction,
    required this.color,
  });

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: v,
        minHeight: 8,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor:
            AlwaysStoppedAnimation(v > 0.9 ? MfPalette.expenseRed : color),
      ),
    );
  }
}
