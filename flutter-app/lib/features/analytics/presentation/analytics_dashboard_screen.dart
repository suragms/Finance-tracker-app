import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart'
    show categoriesProvider, expensesProvider;
import '../../income/application/income_providers.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
    ref.invalidate(expensesProvider);
    ref.invalidate(incomesProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = <DateTime>[
      for (var i = 0; i < 24; i++) DateTime(now.year, now.month - i),
    ];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: MfSurface.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MfRadius.xl)),
      ),
      builder: (ctx) => ListView.builder(
        itemCount: months.length,
        itemBuilder: (_, i) {
          final m = months[i];
          final selected =
              m.year == _selectedMonth.year && m.month == _selectedMonth.month;
          return ListTile(
            title: Text(
              DateFormat('MMMM yyyy').format(m),
              style: GoogleFonts.manrope(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            trailing: selected ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.of(ctx).pop(m),
          );
        },
      ),
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  DateTime? _toDate(dynamic raw) => DateTime.tryParse(raw?.toString() ?? '');

  double _toAmount(dynamic raw) => double.tryParse(raw?.toString() ?? '') ?? 0;

  String _catId(Map<String, dynamic> e) {
    final cat = e['category'];
    if (cat is Map) return cat['id']?.toString() ?? 'unknown';
    return e['categoryId']?.toString() ?? 'unknown';
  }

  String _catName(String id, List<Map<String, dynamic>> categories) {
    for (final c in categories) {
      if (c['id']?.toString() == id) return c['name']?.toString() ?? id;
    }
    return id == 'unknown' ? 'Uncategorised' : id;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expenses = ref.watch(expensesProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    final incomes = ref.watch(incomesProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ??
        const <Map<String, dynamic>>[];

    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);

    final monthExpenses = expenses.where((e) {
      final d = _toDate(e['date']);
      if (d == null) return false;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();
    final monthIncomes = incomes.where((i) {
      final d = _toDate(i['date']);
      if (d == null) return false;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    final totalExpense =
        monthExpenses.fold<double>(0, (s, e) => s + _toAmount(e['amount']));
    final totalIncome =
        monthIncomes.fold<double>(0, (s, i) => s + _toAmount(i['amount']));
    final totalBalance = totalIncome - totalExpense;

    final weeklyIncome = List<double>.filled(4, 0);
    final weeklyExpense = List<double>.filled(4, 0);
    for (final e in monthExpenses) {
      final d = _toDate(e['date']);
      if (d == null) continue;
      final idx = ((d.day - 1) / 7).floor().clamp(0, 3);
      weeklyExpense[idx] += _toAmount(e['amount']);
    }
    for (final i in monthIncomes) {
      final d = _toDate(i['date']);
      if (d == null) continue;
      final idx = ((d.day - 1) / 7).floor().clamp(0, 3);
      weeklyIncome[idx] += _toAmount(i['amount']);
    }

    final byCategory = <String, double>{};
    for (final e in monthExpenses) {
      final id = _catId(e);
      byCategory[id] = (byCategory[id] ?? 0) + _toAmount(e['amount']);
    }
    final donut = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = donut.take(6).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Analytics',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            MfSpace.xxl,
            MfSpace.sm,
            MfSpace.xxl,
            MediaQuery.paddingOf(context).bottom + 88,
          ),
          children: [
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(MfRadius.md),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: MfSpace.lg,
                  vertical: MfSpace.md,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded),
                    const SizedBox(width: MfSpace.sm),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
              style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MfSpace.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Income / Expense / Balance',
                    style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: MfSpace.md),
                  Row(
                    children: [
                      _MetricTile(
                        label: 'Income',
                        amount: totalIncome,
                        color: MfPalette.incomeGreen,
                      ),
                      const SizedBox(width: MfSpace.sm),
                      _MetricTile(
                        label: 'Expense',
                        amount: totalExpense,
                        color: MfPalette.expenseRed,
                      ),
                      const SizedBox(width: MfSpace.sm),
                      _MetricTile(
                        label: 'Balance',
                        amount: totalBalance,
                        color: totalBalance >= 0
                            ? const Color(0xFF4DB5FF)
                            : MfPalette.expenseRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MfSpace.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bar chart',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: MfSpace.sm),
                  Text(
                    'Week-wise income vs expense',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: MfSpace.md),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, t, __) {
                      final maxY = [
                        ...weeklyExpense.map((e) => e * t),
                        ...weeklyIncome.map((e) => e * t),
                        1.0
                      ].reduce((a, b) => a > b ? a : b);
                      return SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY * 1.2,
                            barGroups: List.generate(4, (i) {
                              return BarChartGroupData(
                                x: i,
                                barsSpace: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: weeklyIncome[i] * t,
                                    width: 10,
                                    color: MfPalette.incomeGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  BarChartRodData(
                                    toY: weeklyExpense[i] * t,
                                    width: 10,
                                    color: MfPalette.expenseRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.white.withValues(alpha: 0.08),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) => Text(
                                    'W${v.toInt() + 1}',
                                    style: GoogleFonts.inter(fontSize: 11),
                                  ),
                                ),
            ),
          ),
        ),
      ),
    );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: MfSpace.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donut chart (category split)',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: MfSpace.sm),
                  if (top.isEmpty)
                    Text(
                      'No expense categories this month.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, __) => SizedBox(
                            width: 150,
                            height: 150,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 45,
                                sectionsSpace: 2,
                                sections: List.generate(top.length, (i) {
                                  final e = top[i];
                                  return PieChartSectionData(
                                    value: e.value * t,
                                    radius: 18,
                                    title: '',
                                    color: MfCategoryColors.chartPalette[i %
                                        MfCategoryColors.chartPalette.length],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: MfSpace.md),
                        Expanded(
                          child: Column(
                            children: top.asMap().entries.map((entry) {
                              final i = entry.key;
                              final e = entry.value;
                              final c = MfCategoryColors.chartPalette[
                                  i % MfCategoryColors.chartPalette.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _catName(e.key, categories),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      MfCurrency.formatInr(e.value),
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(MfSpace.sm),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(MfRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
                  label,
                  style: GoogleFonts.inter(
                fontSize: 11,
                    fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
          Text(
              MfCurrency.formatInr(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
                fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
