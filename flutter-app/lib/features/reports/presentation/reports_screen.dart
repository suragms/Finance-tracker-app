import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../income/application/income_providers.dart';

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
        title: Text('Reports', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: expenseAsync.when(
          data: (expenses) => incomeAsync.when(
            data: (incomes) => _buildBody(expenses, incomes),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> incomes) {
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
    final balance = totalInc - totalExp;

    final catMap = <String, double>{};
    for (final e in monthExpenses) {
      final cat = e['category'];
      final name = (cat is Map ? cat['name']?.toString() : null) ?? 'Other';
      catMap[name] = (catMap[name] ?? 0) + _toDouble(e['amount']).abs();
    }
    final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Navigator
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Text(DateFormat('MMMM yyyy').format(_focusedDate), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: MfPalette.textPrimary)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Cards
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Income', amount: totalInc, color: MfPalette.incomeGreen)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'Expense', amount: totalExp, color: MfPalette.expenseAmber)),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(label: 'Net Profit', amount: balance, color: MfPalette.primary, isFullWidth: true),
        const SizedBox(height: 24),

        // Charts
        _CategoryBreakdown(categories: sortedCats, totalExpense: totalExp),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amount, required this.color, this.isFullWidth = false});
  final String label;
  final double amount;
  final Color color;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: MfPalette.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            MfCurrency.formatInr(amount),
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories, required this.totalExpense});
  final List<MapEntry<String, double>> categories;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expenses by Category', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: MfPalette.textPrimary)),
          const SizedBox(height: 24),
          if (categories.isEmpty)
            Center(child: Text('No data for this month', style: GoogleFonts.inter(color: MfPalette.textSecondary)))
          else ...[
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: categories.map((c) {
                      final i = categories.indexOf(c);
                      return PieChartSectionData(
                        value: c.value,
                        color: _colorForIndex(i),
                        radius: 12,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...categories.map((c) {
              final i = categories.indexOf(c);
              final pct = totalExpense > 0 ? (c.value / totalExpense * 100).toInt() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorForIndex(i), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.key, style: GoogleFonts.inter(fontSize: 14, color: MfPalette.textPrimary))),
                    Text('$pct%', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: MfPalette.textPrimary)),
                    const SizedBox(width: 12),
                    Text(MfCurrency.formatInr(c.value), style: GoogleFonts.inter(fontSize: 14, color: MfPalette.textSecondary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _colorForIndex(int i) {
    const palette = [Color(0xFF4F46E5), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899)];
    return palette[i % palette.length];
  }
}
