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
    isScrollControlled: false,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MfSpace.lg,
          0,
          MfSpace.lg,
          MfSpace.lg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xEE141414),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x29FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MfSpace.xl,
                  MfSpace.lg,
                  MfSpace.xl,
                  MfSpace.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: MfSpace.lg),
                    Text(
                      'Quick create',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jump into the next action without leaving the dashboard flow.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.64),
                      ),
                    ),
                    const SizedBox(height: MfSpace.xl),
                    _QuickSheetTile(
                      title: 'Record expense',
                      subtitle: 'Capture spend in a couple of taps.',
                      icon: Icons.arrow_upward_rounded,
                      accent: const Color(0xFFE6FF4D),
                      onTap: onExpenseTap,
                    ),
                    const SizedBox(height: MfSpace.md),
                    _QuickSheetTile(
                      title: 'Record income',
                      subtitle: canCreateIncome
                          ? 'Log salary, transfers, and other inflows.'
                          : 'Available when the live API connection is enabled.',
                      icon: Icons.arrow_downward_rounded,
                      accent: const Color(0xFF55C5FF),
                      onTap: onIncomeTap,
                      enabled: canCreateIncome,
                    ),
                    const SizedBox(height: MfSpace.md),
                    _QuickSheetTile(
                      title: 'Open AI insights',
                      subtitle: 'Review summaries, patterns, and next moves.',
                      icon: Icons.auto_awesome_rounded,
                      accent: const Color(0xFFF3FD6F),
                      onTap: onInsightsTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSheetTile extends StatefulWidget {
  const _QuickSheetTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_QuickSheetTile> createState() => _QuickSheetTileState();
}

class _QuickSheetTileState extends State<_QuickSheetTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    return AnimatedScale(
      scale: _pressed
          ? 0.98
          : _hovered
          ? 1.01
          : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: AnimatedContainer(
        duration: MfMotion.fast,
        curve: MfMotion.curve,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: active ? 0.05 : 0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.accent.withValues(alpha: active ? 0.18 : 0.08),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(MfSpace.lg),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(
                        alpha: active ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: active
                          ? widget.accent
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: MfSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(
                              alpha: active ? 0.96 : 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.45,
                            color: Colors.white.withValues(
                              alpha: active ? 0.6 : 0.36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: active ? 0.64 : 0.28),
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
