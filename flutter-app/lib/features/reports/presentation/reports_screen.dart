import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedMonthKey;
  int? _highlightedPieIndex;

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _AnalyticsColors.background,
      body: Stack(
        children: [
          const _AnalyticsBackdrop(),
          SafeArea(
            bottom: false,
            child: expensesAsync.when(
              data: (expenses) {
                final entries = expenses.map(_ExpenseEntry.fromMap).toList()
                  ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

                final monthKeys =
                    entries.map((entry) => entry.monthKey).toSet().toList()
                      ..sort((a, b) => b.compareTo(a));

                if (monthKeys.isEmpty) {
                  monthKeys.add(_monthKey(DateTime.now()));
                }

                final selectedMonthKey = monthKeys.contains(_selectedMonthKey)
                    ? _selectedMonthKey!
                    : monthKeys.first;
                final monthLabel = _formatMonthLabel(selectedMonthKey);
                final selectedEntries = entries
                    .where((entry) => entry.monthKey == selectedMonthKey)
                    .toList();

                final ym = _yearMonthFromKey(selectedMonthKey);
                final mvpAsync = ref.watch(expenseMvpProvider(ym));

                return mvpAsync.when(
                  data: (mvp) {
                    final pie = mvp['chart'] is Map
                        ? Map<String, dynamic>.from(mvp['chart']['pie'] as Map)
                        : <String, dynamic>{};
                    final pieLabels = (pie['labels'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    final pieValues = (pie['values'] as List<dynamic>?)
                            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
                            .toList() ??
                        <double>[];
                    final monthTotal = double.tryParse(
                          mvp['thisMonthExpenses']?.toString() ?? '0',
                        ) ??
                        0;
                    final allTime = mvp['totalSpentAllTime']?.toString() ?? '0';

                    final bar = mvp['chart'] is Map &&
                            (mvp['chart'] as Map)['monthlyExpenses'] is Map
                        ? Map<String, dynamic>.from(
                            (mvp['chart'] as Map)['monthlyExpenses'] as Map,
                          )
                        : <String, dynamic>{};
                    final barLabels = (bar['labels'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    final barValues = (bar['values'] as List<dynamic>?)
                            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
                            .toList() ??
                        <double>[];

                    final breakdownRaw = mvp['categoryBreakdownMonth'];
                    final breakdown = breakdownRaw is List
                        ? breakdownRaw
                            .map((e) => Map<String, dynamic>.from(e as Map))
                            .toList()
                        : <Map<String, dynamic>>[];

                    final vehicle = mvp['vehicle'] is Map
                        ? Map<String, dynamic>.from(mvp['vehicle'] as Map)
                        : <String, dynamic>{};

                    return RefreshIndicator(
                      color: const Color(0xFF49D6FF),
                      backgroundColor: const Color(0xFF121722),
                      onRefresh: () async {
                        await _refresh();
                        ref.invalidate(expenseMvpProvider(ym));
                      },
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xl,
                          MfSpace.md,
                          MfSpace.xl,
                          132,
                        ),
                        children: [
                          _AnalyticsHeader(
                            canPop: canPop,
                            monthKeys: monthKeys,
                            selectedMonthKey: selectedMonthKey,
                            onBack: () => Navigator.of(context).maybePop(),
                            onMonthChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedMonthKey = value;
                                _highlightedPieIndex = null;
                              });
                            },
                          ),
                          const SizedBox(height: MfSpace.lg),
                          _MvpSummaryStrip(
                            monthLabel: monthLabel,
                            monthTotal: monthTotal,
                            allTime: allTime,
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _MvpCategoryPieCard(
                            monthLabel: monthLabel,
                            labels: pieLabels,
                            values: pieValues,
                            monthTotal: monthTotal,
                            highlightedIndex: _highlightedPieIndex,
                            onSliceTap: (i) {
                              setState(() {
                                _highlightedPieIndex = i;
                              });
                            },
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _MvpMonthlyExpenseBarCard(
                            barLabels: barLabels,
                            barValues: barValues,
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _VehicleCostCard(vehicle: vehicle),
                          const SizedBox(height: MfSpace.xl),
                          if (breakdown.isEmpty)
                            _EmptyAnalyticsCard(
                              monthLabel: monthLabel,
                              onAddExpense: () {
                                Navigator.of(context).push(
                                  LedgerPageRoutes.fadeSlide<void>(
                                    const AddExpenseScreen(),
                                  ),
                                );
                              },
                            )
                          else ...[
                            Text(
                              'Categories (this month)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: MfSpace.md),
                            ...breakdown.map(
                              (row) => Padding(
                                padding: const EdgeInsets.only(bottom: MfSpace.sm),
                                child: _MvpCategoryRow(
                                  name: row['name']?.toString() ?? '',
                                  total: row['total']?.toString() ?? '0',
                                ),
                              ),
                            ),
                          ],
                          if (selectedEntries.isNotEmpty) ...[
                            const SizedBox(height: MfSpace.xl),
                            Text(
                              'Recent in month',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: MfSpace.md),
                            ...selectedEntries.take(6).map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: MfSpace.sm,
                                    ),
                                    child: _MvpRecentRow(entry: e),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xl,
                      MfSpace.md,
                      MfSpace.xl,
                      132,
                    ),
                    children: [
                      _AnalyticsHeader(
                        canPop: canPop,
                        monthKeys: monthKeys,
                        selectedMonthKey: selectedMonthKey,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMonthChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedMonthKey = value);
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      const _LoadingChartCard(),
                    ],
                  ),
                  error: (e, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xl,
                      MfSpace.md,
                      MfSpace.xl,
                      132,
                    ),
                    children: [
                      _AnalyticsHeader(
                        canPop: canPop,
                        monthKeys: monthKeys,
                        selectedMonthKey: selectedMonthKey,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMonthChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedMonthKey = value);
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      _ErrorAnalyticsCard(message: e.toString()),
                    ],
                  ),
                );
              },
              loading: () => _AnalyticsScaffoldState(
                canPop: canPop,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: const [
                    _LoadingHeader(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingChartCard(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingTransactions(),
                  ],
                ),
              ),
              error: (error, _) => RefreshIndicator(
                color: const Color(0xFF49D6FF),
                backgroundColor: const Color(0xFF121722),
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: [
                    _AnalyticsHeader(
                      canPop: canPop,
                      monthKeys: const [],
                      selectedMonthKey: null,
                      onBack: () => Navigator.of(context).maybePop(),
                      onMonthChanged: (_) {},
                    ),
                    const SizedBox(height: MfSpace.xl),
                    _ErrorAnalyticsCard(message: error.toString()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

ExpenseMvpMonth _yearMonthFromKey(String key) {
  final p = key.split('-');
  if (p.length < 2) {
    final n = DateTime.now();
    return (year: n.year, month: n.month);
  }
  return (year: int.parse(p[0]), month: int.parse(p[1]));
}

const _mvpPiePalette = <Color>[
  Color(0xFFFFB26B),
  Color(0xFF67E7FF),
  Color(0xFFFF8FD8),
  Color(0xFF63FFCB),
  Color(0xFFFFE36D),
  Color(0xFFADB7FF),
  Color(0xFFFF8A65),
  Color(0xFF81C784),
];

class _MvpSummaryStrip extends StatelessWidget {
  const _MvpSummaryStrip({
    required this.monthLabel,
    required this.monthTotal,
    required this.allTime,
  });

  final String monthLabel;
  final double monthTotal;
  final String allTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnalyticsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This month',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(monthTotal),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  monthLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: MfSpace.md),
        Expanded(
          child: _AnalyticsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-time spent',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(
                    double.tryParse(allTime) ?? 0,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  'Workspace expenses',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MvpCategoryPieCard extends StatelessWidget {
  const _MvpCategoryPieCard({
    required this.monthLabel,
    required this.labels,
    required this.values,
    required this.monthTotal,
    required this.highlightedIndex,
    required this.onSliceTap,
  });

  final String monthLabel;
  final List<String> labels;
  final List<double> values;
  final double monthTotal;
  final int? highlightedIndex;
  final ValueChanged<int?> onSliceTap;

  @override
  Widget build(BuildContext context) {
    final nonZero = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (values[i] > 0) nonZero.add(i);
    }
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category split (DB)',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monthLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  duration: MfMotion.medium,
                  curve: MfMotion.curve,
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 78,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        final touched = response?.touchedSection;
                        if (!event.isInterestedForInteractions ||
                            touched == null ||
                            touched.touchedSectionIndex < 0) {
                          onSliceTap(null);
                          return;
                        }
                        final idx = nonZero[touched.touchedSectionIndex];
                        onSliceTap(idx);
                      },
                    ),
                    sections: nonZero.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                              radius: 70,
                              showTitle: false,
                            ),
                          ]
                        : List.generate(nonZero.length, (j) {
                            final i = nonZero[j];
                            final v = values[i];
                            final share = monthTotal <= 0
                                ? 0.0
                                : (v / monthTotal) * 100;
                            final selected = highlightedIndex == i;
                            return PieChartSectionData(
                              value: v,
                              color: _mvpPiePalette[i % _mvpPiePalette.length],
                              radius: selected ? 84 : 72,
                              title: share >= 8 ? '${share.round()}%' : '',
                              titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A0D13),
                                width: 2,
                              ),
                            );
                          }),
                  ),
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Month total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(monthTotal),
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _AnalyticsColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Wrap(
            spacing: MfSpace.sm,
            runSpacing: MfSpace.sm,
            children: List.generate(labels.length, (i) {
              if (values.length <= i || values[i] <= 0) {
                return const SizedBox.shrink();
              }
              final active = highlightedIndex == i;
              return Chip(
                label: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.text,
                  ),
                ),
                backgroundColor: _mvpPiePalette[i % _mvpPiePalette.length]
                    .withValues(alpha: active ? 0.35 : 0.18),
                side: BorderSide(
                  color: active
                      ? _mvpPiePalette[i % _mvpPiePalette.length]
                      : _AnalyticsColors.border,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MvpMonthlyExpenseBarCard extends StatelessWidget {
  const _MvpMonthlyExpenseBarCard({
    required this.barLabels,
    required this.barValues,
  });

  final List<String> barLabels;
  final List<double> barValues;

  @override
  Widget build(BuildContext context) {
    final maxV = barValues.isEmpty
        ? 1.0
        : barValues.reduce((a, b) => a > b ? a : b);
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly expense trend',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxV > 0 ? maxV * 1.15 : 1,
                barGroups: List.generate(
                  barLabels.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: i < barValues.length ? barValues[i] : 0,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF2F7BFF),
                            Color(0xFF67E7FF),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= barLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            barLabels[i],
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxV > 0 ? maxV / 4 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCostCard extends StatelessWidget {
  const _VehicleCostCard({required this.vehicle});

  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    final has = vehicle['hasVehicles'] == true;
    final total = vehicle['vehicleExpenseTotalAllTime']?.toString() ?? '0';
    final hint = vehicle['emptyHint']?.toString();
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle costs',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          if (!has)
            Text(
              hint ?? 'No vehicles yet — add one under Profile.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _AnalyticsColors.muted,
                height: 1.4,
              ),
            )
          else
            Text(
              'Logged vehicle expenses (all time): ${_formatCurrency(double.tryParse(total) ?? 0)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _AnalyticsColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _MvpCategoryRow extends StatelessWidget {
  const _MvpCategoryRow({required this.name, required this.total});

  final String name;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _AnalyticsColors.text,
              ),
            ),
          ),
          Text(
            _formatCurrency(double.tryParse(total) ?? 0),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF49D6FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MvpRecentRow extends StatelessWidget {
  const _MvpRecentRow({required this.entry});

  final _ExpenseEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MfSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  entry.rawCategory,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _AnalyticsColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatExpenseCurrency(entry.amount),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF8FD8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntry {
  const _ExpenseEntry({
    required this.amount,
    required this.title,
    required this.description,
    required this.rawCategory,
    required this.date,
  });

  final double amount;
  final String title;
  final String description;
  final String rawCategory;
  final DateTime? date;

  DateTime get sortDate => date ?? DateTime.fromMillisecondsSinceEpoch(0);
  String get monthKey => _monthKey(date ?? DateTime.now());

  factory _ExpenseEntry.fromMap(Map<String, dynamic> raw) {
    final amount = _expenseAmount(raw['amount']);
    final note = raw['note']?.toString().trim() ?? '';
    final rawCategory = _rawCategory(raw);
    final date = _expenseDate(raw['date']);
    final title = note.isNotEmpty
        ? note
        : rawCategory.isNotEmpty
        ? rawCategory
        : 'Expense';
    final details = <String>[
      if (note.isNotEmpty && rawCategory.isNotEmpty) rawCategory,
      if (date != null) DateFormat('d MMM').format(date.toLocal()),
    ];

    return _ExpenseEntry(
      amount: amount,
      title: title,
      description: details.isEmpty ? 'Ledger entry' : details.join(' • '),
      rawCategory: rawCategory,
      date: date,
    );
  }
}

abstract final class _AnalyticsColors {
  static const background = Color(0xFF060910);
  static const backgroundDeep = Color(0xFF0B1020);
  static const panel = Color(0xD9151A24);
  static const panelAlt = Color(0xCC111722);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFF93A0B8);
  static const border = Color(0x1FFFFFFF);
}

double _expenseAmount(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

DateTime? _expenseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _rawCategory(Map<String, dynamic> expense) {
  final category = expense['category'];
  if (category is Map) {
    final name = category['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }

  final categoryName = expense['categoryName']?.toString().trim() ?? '';
  if (categoryName.isNotEmpty) return categoryName;

  return expense['category']?.toString().trim() ?? '';
}

String _monthKey(DateTime date) => DateFormat('yyyy-MM').format(date.toLocal());

String _formatMonthLabel(String key) {
  final parsed = DateTime.tryParse('$key-01');
  if (parsed == null) return key;
  return DateFormat('MMMM yyyy').format(parsed);
}

String _formatCurrency(num value) {
  final digits = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: digits,
  ).format(value);
}

String _formatExpenseCurrency(num value) => '-${_formatCurrency(value)}';

class _AnalyticsBackdrop extends StatelessWidget {
  const _AnalyticsBackdrop();

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
                _AnalyticsColors.background,
                _AnalyticsColors.backgroundDeep,
                Color(0xFF04060B),
              ],
            ),
          ),
        ),
        _GlowOrb(
          top: -80,
          right: -30,
          size: 230,
          colors: [
            const Color(0xFF49D6FF).withValues(alpha: 0.24),
            const Color(0xFF49D6FF).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          top: 120,
          left: -90,
          size: 240,
          colors: [
            const Color(0xFFFF5E7E).withValues(alpha: 0.18),
            const Color(0xFFFF5E7E).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          bottom: 90,
          right: -80,
          size: 250,
          colors: [
            const Color(0xFFFFD65C).withValues(alpha: 0.18),
            const Color(0xFFFFD65C).withValues(alpha: 0),
          ],
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.colors,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.canPop,
    required this.monthKeys,
    required this.selectedMonthKey,
    required this.onBack,
    required this.onMonthChanged,
  });

  final bool canPop;
  final List<String> monthKeys;
  final String? selectedMonthKey;
  final VoidCallback onBack;
  final ValueChanged<String?> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canPop) ...[
          _HeaderIconButton(onTap: onBack),
          const SizedBox(width: MfSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense analytics',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                  color: _AnalyticsColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A clean read on this month\'s category mix.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _AnalyticsColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (monthKeys.isNotEmpty && selectedMonthKey != null)
          _MonthSelector(
            monthKeys: monthKeys,
            value: selectedMonthKey!,
            onChanged: onMonthChanged,
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AnalyticsColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _AnalyticsColors.text,
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthKeys,
    required this.value,
    required this.onChanged,
  });

  final List<String> monthKeys;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: false,
          dropdownColor: const Color(0xFF121722),
          borderRadius: BorderRadius.circular(18),
          iconEnabledColor: _AnalyticsColors.text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _AnalyticsColors.text,
          ),
          items: monthKeys
              .map(
                (monthKey) => DropdownMenuItem(
                  value: monthKey,
                  child: Text(
                    _formatMonthLabel(monthKey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _AnalyticsColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AnalyticsColors.panel, _AnalyticsColors.panelAlt],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsScaffoldState extends StatelessWidget {
  const _AnalyticsScaffoldState({required this.canPop, required this.child});

  final bool canPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xl,
            MfSpace.md,
            MfSpace.xl,
            0,
          ),
          child: _AnalyticsHeader(
            canPop: canPop,
            monthKeys: const [],
            selectedMonthKey: null,
            onBack: () => Navigator.of(context).maybePop(),
            onMonthChanged: (_) {},
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.monthLabel,
    required this.onAddExpense,
  });

  final String monthLabel;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF49D6FF).withValues(alpha: 0.24),
                  const Color(0xFFFF8FD8).withValues(alpha: 0.24),
                ],
              ),
            ),
            child: const Icon(
              Icons.pie_chart_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'No expenses in $monthLabel',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Add a few transactions to light up the chart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}

class _ErrorAnalyticsCard extends StatelessWidget {
  const _ErrorAnalyticsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E7E).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF8DA2),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'Analytics unavailable',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 170,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 132,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class _LoadingChartCard extends StatelessWidget {
  const _LoadingChartCard();

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsPanel(
      child: SizedBox(
        height: 520,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF49D6FF)),
        ),
      ),
    );
  }
}

class _LoadingTransactions extends StatelessWidget {
  const _LoadingTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : MfSpace.md),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _AnalyticsColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
