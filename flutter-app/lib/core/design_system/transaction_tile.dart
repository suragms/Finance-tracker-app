import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/money_flow_tokens.dart';

IconData categoryIconFor(String key) {
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

class BuddyTransactionTile extends StatelessWidget {
  const BuddyTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.categoryColor,
    required this.categoryIcon,
    required this.date,
    this.animationIndex = 0,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isExpense;
  final Color categoryColor;
  final IconData categoryIcon;
  final DateTime date;
  final int animationIndex;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + animationIndex * 60),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - t)),
        child: Opacity(opacity: t, child: child),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MfRadius.md),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}${MfCurrency.formatInr(amount)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExpense
                          ? MfPalette.expenseRed
                          : MfPalette.incomeGreen,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
