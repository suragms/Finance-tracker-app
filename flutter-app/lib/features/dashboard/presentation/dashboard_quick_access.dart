import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/ledger_page_routes.dart';
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
import '../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../send_money/presentation/receive_money_screen.dart';
import '../../send_money/presentation/send_money_screen.dart';
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
        icon: Icons.send_rounded,
        title: 'Send money',
        subtitle: 'UPI & transfers',
        iconBgColor: MfPalette.neonGreen.withValues(alpha: 0.2),
        iconColor: MfPalette.neonGreen,
        onTap: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(const SendMoneyScreen()),
          );
        },
      ),
      _QuickLink(
        icon: Icons.south_west_rounded,
        title: 'Receive',
        subtitle: 'Request UPI',
        iconBgColor: MfPalette.neonGreen.withValues(alpha: 0.14),
        iconColor: MfPalette.neonGreenSoft,
        onTap: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(const ReceiveMoneyScreen()),
          );
        },
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
        icon: Icons.insights_outlined,
        title: 'Analytics',
        subtitle: 'Weekly & categories',
        iconBgColor: MfPalette.neonGreen.withValues(alpha: 0.16),
        iconColor: MfPalette.neonGreen,
        onTap: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(const AnalyticsDashboardScreen()),
          );
        },
      ),
      _QuickLink(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'Summaries',
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossCount = screenWidth > 600
        ? 4
        : screenWidth > 400
            ? 3
            : 2;
    final aspectRatio = crossCount == 4
        ? 1.1
        : crossCount == 3
            ? 0.92
            : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick access',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: MfSpace.xs),
            Text(
              'Jump to accounts, planning, and tools',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: MfSpace.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: MfSpace.sm,
            mainAxisSpacing: MfSpace.sm,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _QuickTile(link: items[i]),
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
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(MfRadius.md),
            boxShadow: MfShadow.card,
            border: Border.all(color: cs.outlineVariant),
          ),
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
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                link.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
