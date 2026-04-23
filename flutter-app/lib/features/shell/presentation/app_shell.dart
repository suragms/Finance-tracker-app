import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/design_system/mf_ui_system.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../dashboard/presentation/money_flow_home_screen.dart';
import '../../expenses/application/recurring_manager.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../../onboarding/presentation/demo_get_started_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import 'quick_create_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _mobileIndex = 0;

  static const _mobileScreens = [
    MoneyFlowHomeScreen(),
    ExpenseListScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  String _userNameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return 'User';
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'User';
    final words = local.split(RegExp(r'[._\-]+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

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
    // Current requirement focusing on Mobile-First Navigation
    return _buildMobile();
  }

  Widget _buildMobile() {
    final email = ref.watch(tokenStorageProvider).userEmail;
    final userName = _userNameFromEmail(email);
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(gradient: mfPremiumCanvasGradient),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: MfPalette.accentSoftPurple.withValues(alpha: 0.2),
                child: Text(
                  userInitial,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MoneyFlow AI',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white38),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: AnimatedSwitcher(
          duration: MfMotion.medium,
          child: KeyedSubtree(
            key: ValueKey(_mobileIndex),
            child: _mobileScreens[_mobileIndex],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _AnimatedFab(
          onTap: () => showMoneyFlowQuickCreateSheet(context),
        ),
        bottomNavigationBar: _FloatingBottomNav(
          selectedIndex: _mobileIndex,
          onTap: (index) => setState(() => _mobileIndex = index),
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomSafe + 12),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavTab(
                  label: 'Home',
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavTab(
                  label: 'Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                _AnimatedFab(
                  onTap: () => showMoneyFlowQuickCreateSheet(context),
                ),
                _NavTab(
                  label: 'Trends',
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
              letterSpacing: 0.2,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  const _AnimatedFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
         _controller.reverse();
         widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF667EEA)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
