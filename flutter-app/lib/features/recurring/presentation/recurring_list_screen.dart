import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/dio_errors.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../application/recurring_provider.dart';
import 'add_recurring_screen.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required bool active,
  }) async {
    if (kNoApiMode) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch<dynamic>('/recurring/$id/active', data: {'active': active});
      ref.invalidate(recurringProvider);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringProvider);
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        title: Text('Recurring', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddRecurringScreen())),
            icon: const Icon(Icons.add_circle_outline, color: MfPalette.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: MfPalette.textSecondary))),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_repeat, size: 64, color: Colors.black12),
                  const SizedBox(height: 16),
                  Text('No recurring payments', style: GoogleFonts.inter(fontSize: 18, color: MfPalette.textSecondary)),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddRecurringScreen())),
                    child: const Text('Add Recurring'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id']?.toString() ?? UniqueKey().toString();
              return _RecurringCard(
                key: ValueKey(id),
                name: item['name']?.toString() ?? 'Subscription',
                amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0,
                frequency: (item['frequency']?.toString() ?? 'monthly').toUpperCase(),
                active: item['active'] != false,
                onToggle: (v) => _toggleActive(context, ref, id: id, active: v),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    super.key,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.active,
    required this.onToggle,
  });

  final String name;
  final double amount;
  final String frequency;
  final bool active;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: MfPalette.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_repeat, color: MfPalette.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: MfPalette.textPrimary)),
                Text(frequency, style: GoogleFonts.inter(fontSize: 12, color: MfPalette.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(MfCurrency.formatInr(amount), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: MfPalette.textPrimary)),
              Transform.scale(
                scale: 0.7,
                child: Switch.adaptive(value: active, onChanged: onToggle, activeColor: MfPalette.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
