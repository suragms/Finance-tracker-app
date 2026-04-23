import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../insights/presentation/insights_screen.dart';

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
        onInsightsTap: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(
            rootContext,
          ).push(LedgerPageRoutes.fadeSlide<void>(const InsightsScreen()));
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
    required this.onInsightsTap,
    required this.canCreateIncome,
  });

  final VoidCallback onExpenseTap;
  final VoidCallback onIncomeTap;
  final VoidCallback onInsightsTap;
  final bool canCreateIncome;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(MfRadius.md),
            boxShadow: MfShadow.card,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Action',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What would you like to do?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SquircleActionCard(
                          title: 'Expense',
                          icon: Icons.payments_rounded,
                          accent: MfPalette.expenseAmber,
                          onTap: onExpenseTap,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SquircleActionCard(
                          title: 'Income',
                          icon: Icons.account_balance_wallet_rounded,
                          accent: MfPalette.incomeGreen,
                          onTap: onIncomeTap,
                          enabled: canCreateIncome,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WideActionCard(
                    title: 'AI Insights',
                    subtitle: 'Analyze your spending patterns',
                    icon: Icons.auto_awesome_rounded,
                    accent: MfPalette.primaryIndigo,
                    onTap: onInsightsTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquircleActionCard extends StatefulWidget {
  const _SquircleActionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_SquircleActionCard> createState() => _SquircleActionCardState();
}

class _SquircleActionCardState extends State<_SquircleActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = widget.enabled;
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: active ? 1.0 : 0.4),
            borderRadius: BorderRadius.circular(MfRadius.sm),
            border: Border.all(
              color: widget.accent.withValues(alpha: active ? 0.3 : 0.1),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: active ? 0.15 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: active
                      ? widget.accent
                      : cs.onSurface.withValues(alpha: 0.3),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: active ? 1.0 : 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideActionCard extends StatefulWidget {
  const _WideActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_WideActionCard> createState() => _WideActionCardState();
}

class _WideActionCardState extends State<_WideActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(MfRadius.sm),
            border: Border.all(color: widget.accent.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: cs.onSurface.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
