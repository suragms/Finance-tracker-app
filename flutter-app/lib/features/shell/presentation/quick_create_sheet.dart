import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/presentation/add_income_screen.dart';

Future<void> showMoneyFlowQuickCreateSheet(BuildContext context) {
  final rootContext = context;
  final canCreateIncome = !kNoApiMode;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _MoneyFlowQuickCreateSheet(
        onExpenseTap: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(
            rootContext,
          ).push(LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()));
        },
        onIncomeTap: () {
          Navigator.of(sheetContext).pop();
          if (!canCreateIncome) {
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'Income capture is available when the live API is connected.',
                ),
              ),
            );
            return;
          }
          Navigator.of(
            rootContext,
          ).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
        },
        canCreateIncome: canCreateIncome,
      );
    },
  );
}

class _MoneyFlowQuickCreateSheet extends StatelessWidget {
  const _MoneyFlowQuickCreateSheet({
    required this.onExpenseTap,
    required this.onIncomeTap,
    required this.canCreateIncome,
  });

  final VoidCallback onExpenseTap;
  final VoidCallback onIncomeTap;
  final bool canCreateIncome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Action',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'What would you like to track today?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Expense',
                        icon: Icons.upload_rounded,
                        color: const Color(0xFFFB7185),
                        onTap: onExpenseTap,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        title: 'Income',
                        icon: Icons.download_rounded,
                        color: const Color(0xFF2DD4BF),
                        onTap: onIncomeTap,
                        enabled: canCreateIncome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _WideAction(
                  title: 'Financial Analysis',
                  subtitle: 'View detailed insights',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF667EEA),
                  onTap: () {
                    Navigator.pop(context);
                    // This is handled by switching tabs in AppShell usually,
                    // but we can just pop and let user click the tab.
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
