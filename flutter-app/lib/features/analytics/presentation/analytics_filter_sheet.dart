import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../domain/analytics_filter.dart';

/// Bottom sheet: payment mode + clear drill filters.
Future<AnalyticsFilter?> showAnalyticsFilterSheet(
  BuildContext context, {
  required AnalyticsFilter current,
}) {
  return showModalBottomSheet<AnalyticsFilter>(
    context: context,
    backgroundColor: MfSurface.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModal) {
          final cs = Theme.of(context).colorScheme;
          String? pm = current.paymentMode;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: pm,
                  dropdownColor: MfSurface.card,
                  decoration: InputDecoration(
                    labelText: 'Payment mode',
                    labelStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank transfer'),
                    ),
                    DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setModal(() {
                    pm = v;
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                          AnalyticsFilter(
                            year: current.year,
                            month: current.month,
                            fromYmd: current.fromYmd,
                            toYmd: current.toYmd,
                            categoryId: current.categoryId,
                            subCategoryId: current.subCategoryId,
                            expenseTypeId: current.expenseTypeId,
                            spendEntityId: current.spendEntityId,
                            paymentMode: pm,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
