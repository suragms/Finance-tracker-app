import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../income/presentation/income_history_screen.dart';
import '../../insurance/presentation/insurance_screen.dart';
import '../../investments/presentation/investments_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../vehicles/presentation/vehicles_screen.dart';

/// Premium quick links on the dashboard (same destinations as More, except log out).
class DashboardQuickAccess extends StatelessWidget {
  const DashboardQuickAccess({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_QuickLink>[
      _QuickLink(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Accounts',
        subtitle: 'Balances & cards',
        iconBgColor: MfPalette.primary.withValues(alpha: 0.22),
        iconColor: MfPalette.primaryLight,
        onTap: () => _push(context, const AccountsScreen()),
      ),
      _QuickLink(
        icon: Icons.savings_outlined,
        title: 'Add income',
        subtitle: 'Log earnings',
        iconBgColor: MfPalette.incomeGreen.withValues(alpha: 0.22),
        iconColor: MfPalette.incomeGreen,
        onTap: () => _push(context, const AddIncomeScreen()),
      ),
      _QuickLink(
        icon: Icons.trending_up_outlined,
        title: 'Investments',
        subtitle: 'Portfolio',
        iconBgColor: MfPalette.warningAmber.withValues(alpha: 0.22),
        iconColor: MfPalette.warningAmber,
        onTap: () => _push(context, const InvestmentsScreen()),
      ),
      _QuickLink(
        icon: Icons.pie_chart_outline_outlined,
        title: 'Budgets',
        subtitle: 'Spending caps',
        iconBgColor: MfPalette.primaryGlow.withValues(alpha: 0.22),
        iconColor: MfPalette.primaryGlow,
        onTap: () => _push(context, const BudgetScreen()),
      ),
      _QuickLink(
        icon: Icons.notifications_outlined,
        title: 'Alerts',
        subtitle: 'Notifications',
        iconBgColor: cs.secondary.withValues(alpha: 0.22),
        iconColor: cs.secondary,
        onTap: () => _push(context, const NotificationsScreen()),
      ),
      _QuickLink(
        icon: Icons.payments_outlined,
        title: 'Income history',
        subtitle: 'Past entries',
        iconBgColor: MfPalette.primaryLight.withValues(alpha: 0.18),
        iconColor: MfPalette.primaryLight,
        onTap: () => _push(context, const IncomeHistoryScreen()),
      ),
      _QuickLink(
        icon: Icons.folder_outlined,
        title: 'Documents',
        subtitle: 'Statements',
        iconBgColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        iconColor: cs.onSurface.withValues(alpha: 0.75),
        onTap: () => _push(context, const DocumentsScreen()),
      ),
      _QuickLink(
        icon: Icons.health_and_safety_outlined,
        title: 'Insurance',
        subtitle: 'Coverage',
        iconBgColor: MfPalette.primary.withValues(alpha: 0.2),
        iconColor: MfPalette.primaryLight,
        onTap: () => _push(context, const InsuranceScreen()),
      ),
      _QuickLink(
        icon: Icons.directions_car_outlined,
        title: 'Vehicles',
        subtitle: 'Assets',
        iconBgColor: cs.onSurface.withValues(alpha: 0.12),
        iconColor: cs.onSurface.withValues(alpha: 0.65),
        onTap: () => _push(context, const VehiclesScreen()),
      ),
      _QuickLink(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'Analytics',
        iconBgColor: MfPalette.heroMid.withValues(alpha: 0.35),
        iconColor: MfPalette.primaryLight,
        onTap: () => _push(context, const ReportsScreen()),
      ),
      _QuickLink(
        icon: Icons.auto_awesome_outlined,
        title: 'AI insights',
        subtitle: 'Smart tips',
        iconBgColor: MfPalette.heroStart.withValues(alpha: 0.45),
        iconColor: MfPalette.primaryLight,
        onTap: () => _push(context, const InsightsScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick access',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: MfSpace.xs),
            Text(
              'Jump to accounts, planning, and tools',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: MfSpace.md),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 480 ? 3 : 2;
            final ratio = cols == 3 ? 0.92 : 1.0;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: MfSpace.sm + 2,
                crossAxisSpacing: MfSpace.sm + 2,
                childAspectRatio: ratio,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _QuickTile(link: items[i]),
            );
          },
        ),
      ],
    );
  }
}

class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.link});

  final _QuickLink link;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: link.onTap,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: Container(
          decoration: glassCard(borderRadius: MfRadius.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: MfSpace.sm,
            vertical: MfSpace.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: link.iconBgColor,
                  borderRadius: BorderRadius.circular(MfRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(link.icon, size: 18, color: link.iconColor),
              ),
              const SizedBox(height: MfSpace.sm),
              Text(
                link.title,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
