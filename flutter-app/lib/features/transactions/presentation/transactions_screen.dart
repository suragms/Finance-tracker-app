import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../income/application/income_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomesAsync = ref.watch(incomesProvider);

    final all = <_TxItem>[];
    
    expensesAsync.whenData((list) {
      for (final e in list) {
        all.add(_TxItem(
          id: e['id']?.toString() ?? UniqueKey().toString(),
          title: e['note']?.toString() ?? (e['category'] is Map ? e['category']['name'] : 'Expense'),
          subtitle: e['category'] is Map ? e['category']['name'] : 'General',
          amount: -(double.tryParse(e['amount']?.toString() ?? '0') ?? 0).abs(),
          date: DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime.now(),
          color: MfPalette.expenseAmber,
          icon: Icons.upload_rounded,
        ));
      }
    });

    incomesAsync.whenData((list) {
      for (final i in list) {
        all.add(_TxItem(
          id: i['id']?.toString() ?? UniqueKey().toString(),
          title: i['note']?.toString() ?? i['source']?.toString() ?? 'Income',
          subtitle: i['source']?.toString() ?? 'General',
          amount: (double.tryParse(i['amount']?.toString() ?? '0') ?? 0).abs(),
          date: DateTime.tryParse(i['date']?.toString() ?? '') ?? DateTime.now(),
          color: MfPalette.incomeGreen,
          icon: Icons.download_rounded,
        ));
      }
    });

    all.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        title: Text('Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: all.isEmpty && (expensesAsync.isLoading || incomesAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = all[index];
                    return Container(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: MfPalette.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  '${item.subtitle} • ${DateFormat('dd MMM').format(item.date)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: MfPalette.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            MfCurrency.formatInr(item.amount),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: item.amount >= 0 ? MfPalette.incomeGreen : MfPalette.expenseAmber,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text('No transactions yet', style: GoogleFonts.inter(fontSize: 16, color: MfPalette.textSecondary)),
        ],
      ),
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
