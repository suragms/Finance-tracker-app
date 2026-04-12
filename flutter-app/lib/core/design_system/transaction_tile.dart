import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

Color _categoryColor(String? name) {
  final colors = [
    const Color(0xFF4B79F8),
    const Color(0xFF10997A),
    const Color(0xFFE6A93D),
    const Color(0xFFD06B5E),
    const Color(0xFF6B74F8),
    const Color(0xFF8E5CF6),
  ];
  final idx = (name?.codeUnits.fold(0, (a, b) => a + b) ?? 0) % colors.length;
  return colors[idx];
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.avatarColor,
    required this.avatarLabel,
    this.endAction,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final Color avatarColor;
  final String avatarLabel;
  final Widget? endAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = isExpense ? MfPalette.expenseRed : MfPalette.incomeGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: Container(
          decoration: glassCard(
            borderRadius: MfRadius.lg,
            color: cs.surfaceContainerLowest.withValues(alpha: 0.76),
            borderColor: cs.outlineVariant.withValues(alpha: 0.14),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MfSpace.lg,
            vertical: MfSpace.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isExpense
                      ? expenseGradient(avatarColor)
                      : incomeGradient(),
                  borderRadius: BorderRadius.circular(MfRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _categoryColor(title),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        subtitle.isEmpty ? 'No note attached' : subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.64),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isExpense ? '-$amount' : '+$amount',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (endAction != null) ...[
                    const SizedBox(height: MfSpace.xs),
                    endAction!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
