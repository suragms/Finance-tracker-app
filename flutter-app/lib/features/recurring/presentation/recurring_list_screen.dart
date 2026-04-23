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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECURRING',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white24, letterSpacing: 1.5),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddRecurringScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('ADD NEW', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: const Color(0xFF6366F1))),
                    ),
                  ),
                ],
              ),
            ),

            // LIST: Recurring Cards
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white24))),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(child: Text('No recurring active.', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.bold)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final id = item['id']?.toString() ?? '';
                      final name = item['name']?.toString() ?? item['title']?.toString() ?? 'Subscription';
                      final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
                      final freq = (item['frequency']?.toString() ?? 'monthly').toUpperCase();
                      final active = item['active'] != false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RecurringCard(
                          name: name,
                          amount: amount,
                          frequency: freq,
                          active: active,
                          onToggle: (v) => _toggleActive(context, ref, id: id, active: v),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
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
      padding: const EdgeInsets.all(24),
      decoration: glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                frequency,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 10, color: const Color(0xFF6366F1), letterSpacing: 1),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: active,
                  activeThumbColor: const Color(0xFF6366F1),
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MfCurrency.formatInr(amount),
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: active ? Colors.white : Colors.white24),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white12),
            ],
          ),
        ],
      ),
    );
  }
}
