import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/mf_ui_system.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../income/application/income_providers.dart';
import '../../shell/presentation/quick_create_sheet.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + delta);
    });
  }

  double _toDouble(dynamic raw) => double.tryParse(raw?.toString() ?? '') ?? 0;
  DateTime? _toDate(dynamic raw) => DateTime.tryParse(raw?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expensesProvider);
    final incomeAsync = ref.watch(incomesProvider);

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        title: Text(
          'Financial Analytics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: expenseAsync.when(
        data: (expenses) => incomeAsync.when(
          data: (incomes) => _buildReport(expenses, incomes),
          loading: () => const Center(child: CircularProgressIndicator(color: MfPalette.primary)),
          error: (e, __) => _buildError(e),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: MfPalette.primary)),
        error: (e, __) => _buildError(e),
      ),
    );
  }

  Widget _buildReport(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> incomes) {
    final start = _focusedDate;
    final end = DateTime(start.year, start.month + 1);

    final monthExpenses = expenses.where((e) {
      final d = _toDate(e['date']);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).toList();

    final monthIncomes = incomes.where((i) {
      final d = _toDate(i['date']);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).toList();

    final totalExp = monthExpenses.fold<double>(0, (s, e) => s + _toDouble(e['amount']).abs());
    final totalInc = monthIncomes.fold<double>(0, (s, i) => s + _toDouble(i['amount']).abs());
    final net = totalInc - totalExp;

    final hasData = monthExpenses.isNotEmpty || monthIncomes.isNotEmpty;

    // Category aggregation
    final catMap = <String, double>{};
    for (final e in monthExpenses) {
      final cat = e['category'];
      final name = (cat is Map ? cat['name']?.toString() : null) ?? 'Other';
      catMap[name] = (catMap[name] ?? 0) + _toDouble(e['amount']).abs();
    }
    final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Trend calculation (last 6 months)
    final trendPoints = <_TrendPoint>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(start.year, start.month - i);
      final dEnd = DateTime(d.year, d.month + 1);
      final eSum = expenses
          .where((e) {
            final dt = _toDate(e['date']);
            return dt != null && !dt.isBefore(d) && dt.isBefore(dEnd);
          })
          .fold<double>(0, (s, e) => s + _toDouble(e['amount']).abs());
      final iSum = incomes
          .where((inc) {
            final dt = _toDate(inc['date']);
            return dt != null && !dt.isBefore(d) && dt.isBefore(dEnd);
          })
          .fold<double>(0, (s, inc) => s + _toDouble(inc['amount']).abs());
      trendPoints.add(_TrendPoint(label: DateFormat('MMM').format(d), expense: eSum, income: iSum));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // Month Selector
        _MonthPager(
          focusedDate: _focusedDate,
          onPrev: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 24),

        if (!hasData)
          _EmptyReportState(onAdd: () => showMoneyFlowQuickCreateSheet(context))
        else ...[
          // Summary Card
          _SummaryCard(income: totalInc, expense: totalExp, net: net),
          const SizedBox(height: 24),

          // Spending by Category (Pie Chart)
          _CategoryBreakdownCard(sortedCats: sortedCats, totalExpense: totalExp),
          const SizedBox(height: 24),

          // Monthly Trend (Bar Chart)
          _TrendChartCard(trendPoints: trendPoints),
        ],
      ],
    );
  }

  Widget _buildError(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: MfPalette.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'Analytics temporarily unavailable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _MonthPager extends StatelessWidget {
  final DateTime focusedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthPager({required this.focusedDate, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MfRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
          ),
          Text(
            DateFormat('MMMM yyyy').format(focusedDate).toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double net;

  const _SummaryCard({required this.income, required this.expense, required this.net});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(MfRadius.md),
        boxShadow: MfShadow.card,
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Net Flow', amount: net, color: net >= 0 ? MfPalette.incomeGreen : MfPalette.expenseRed, isLarge: true),
              Icon(Icons.insights_rounded, color: cs.onSurface.withValues(alpha: 0.2), size: 32),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Income', amount: income, color: cs.primary)),
              Container(width: 1, height: 40, color: cs.outlineVariant),
              Expanded(child: _MiniStat(label: 'Expense', amount: expense, color: cs.error)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isLarge;

  const _MiniStat({required this.label, required this.amount, required this.color, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(color: MfPalette.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Text(
          MfCurrency.formatInr(amount),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isLarge ? color : null,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> sortedCats;
  final double totalExpense;

  const _CategoryBreakdownCard({required this.sortedCats, required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(MfRadius.md),
        boxShadow: MfShadow.card,
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING BREAKDOWN',
            style: GoogleFonts.inter(color: MfPalette.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: sortedCats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  return PieChartSectionData(
                    value: e.value,
                    color: MfCategoryColors.chartPalette[i % MfCategoryColors.chartPalette.length],
                    radius: 50,
                    title: '',
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...sortedCats.map((cat) {
            final idx = sortedCats.indexOf(cat);
            final color = MfCategoryColors.chartPalette[idx % MfCategoryColors.chartPalette.length];
            final pct = totalExpense > 0 ? (cat.value / totalExpense * 100).toStringAsFixed(0) : '0';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${pct}%',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    MfCurrency.formatCompact(cat.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<_TrendPoint> trendPoints;

  const _TrendChartCard({required this.trendPoints});

  @override
  Widget build(BuildContext context) {
    final maxVal = trendPoints.map((p) => p.expense > p.income ? p.expense : p.income).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.3;

    return Container(
      decoration: glassCard(borderRadius: MfRadius.xl),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY TREND',
            style: GoogleFonts.inter(color: MfPalette.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(enabled: true),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= trendPoints.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(trendPoints[i].label, style: const TextStyle(color: MfPalette.textMuted, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: trendPoints.asMap().entries.map((ent) {
                  return BarChartGroupData(
                    x: ent.key,
                    barRods: [
                      BarChartRodData(
                        toY: ent.value.income,
                        color: MfPalette.incomeGreen,
                        width: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: ent.value.expense,
                        color: MfPalette.expenseRed,
                        width: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: MfPalette.incomeGreen, label: 'Income'),
              const SizedBox(width: 20),
              _LegendItem(color: MfPalette.expenseRed, label: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(color: MfPalette.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyReportState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(MfRadius.md),
        boxShadow: MfShadow.card,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: MfPalette.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bar_chart_rounded, size: 48, color: MfPalette.primaryLight),
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'We need a few transactions to generate your financial insights.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: MfPalette.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MfPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double expense;
  final double income;
  _TrendPoint({required this.label, required this.expense, required this.income});
}
