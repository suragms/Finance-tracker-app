import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../dashboard/presentation/money_flow_home_screen.dart';
import '../../expenses/application/recurring_manager.dart';
import '../../onboarding/presentation/demo_get_started_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import 'quick_create_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AddShellState();
}

class _AddShellState extends ConsumerState<AppShell> {
  int _mobileIndex = 0;

  static const _mobileScreens = [
    MoneyFlowHomeScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = ref.read(ledgerSyncServiceProvider);
      await sync.ensureNoApiSeed();
      ref.read(recurringManagerProvider).init();
      if (!kNoApiMode) {
        await sync.pullAndFlush();
      } else if (mounted) {
        await showDemoGetStartedIfNeeded(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: MfPalette.canvas,
      body: AnimatedSwitcher(
        duration: MfMotion.medium,
        child: KeyedSubtree(
          key: ValueKey(_mobileIndex),
          child: _mobileScreens[_mobileIndex],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onTap: () => showMoneyFlowQuickCreateSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _MoneyFlowBottomNav(
        selectedIndex: _mobileIndex,
        onTap: (index) => setState(() => _mobileIndex = index),
      ),
    );
  }
}

class _MoneyFlowBottomNav extends StatelessWidget {
  const _MoneyFlowBottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavTab(
              label: 'Dashboard',
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavTab(
              label: 'Transactions',
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 48), // Space for FAB
            _NavTab(
              label: 'Reports',
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavTab(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = MfPalette.primary;
    final inactiveColor = Color(0xFF9CA3AF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFab extends StatelessWidget {
  const _AnimatedFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: MfPalette.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }
}
