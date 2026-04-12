import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../dashboard/presentation/money_flow_home_screen.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'quick_create_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _destinations = [
    _ShellDestination('Home', Icons.home_outlined, Icons.home_rounded),
    _ShellDestination(
      'Activity',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _ShellDestination(
      'Analytics',
      Icons.insights_outlined,
      Icons.insights_rounded,
    ),
    _ShellDestination(
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = ref.read(ledgerSyncServiceProvider);
      await sync.ensureNoApiSeed();
      if (!kNoApiMode) {
        await sync.pullAndFlush();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          const _ShellBackdrop(),
          IndexedStack(
            index: _index,
            children: const [
              MoneyFlowHomeScreen(),
              ExpenseListScreen(),
              AnalyticsDashboardScreen(),
              ProfileScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          MfSpace.lg,
          0,
          MfSpace.lg,
          bottomInset == 0 ? MfSpace.lg : bottomInset,
        ),
        child: SizedBox(
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                top: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xD9161616),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 28,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavItemButton(
                              destination: _destinations[0],
                              selected: _index == 0,
                              onTap: () => setState(() => _index = 0),
                            ),
                          ),
                          Expanded(
                            child: _NavItemButton(
                              destination: _destinations[1],
                              selected: _index == 1,
                              onTap: () => setState(() => _index = 1),
                            ),
                          ),
                          const SizedBox(width: 78),
                          Expanded(
                            child: _NavItemButton(
                              destination: _destinations[2],
                              selected: _index == 2,
                              onTap: () => setState(() => _index = 2),
                            ),
                          ),
                          Expanded(
                            child: _NavItemButton(
                              destination: _destinations[3],
                              selected: _index == 3,
                              onTap: () => setState(() => _index = 3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: _FloatingCreateButton(
                  onTap: () => showMoneyFlowQuickCreateSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF0D0D0D)),
        Positioned(
          top: -130,
          right: -50,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MfPalette.neonGreen.withValues(alpha: 0.16),
                    MfPalette.neonGreen.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItemButton extends StatefulWidget {
  const _NavItemButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? MfPalette.neonGreen
        : Colors.white.withValues(alpha: 0.62);

    return AnimatedScale(
      scale: _pressed
          ? 0.95
          : _hovered
          ? 1.02
          : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: MfMotion.fast,
                  curve: MfMotion.curve,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? MfPalette.neonGreen.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.selected
                        ? widget.destination.selectedIcon
                        : widget.destination.icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.destination.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
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

class _FloatingCreateButton extends StatefulWidget {
  const _FloatingCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingCreateButton> createState() => _FloatingCreateButtonState();
}

class _FloatingCreateButtonState extends State<_FloatingCreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MfPalette.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF4ACBFF).withValues(alpha: 0.2),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              customBorder: const CircleBorder(),
              child: Ink(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MfPalette.neonGreenSoft,
                      MfPalette.neonGreen,
                      Color(0xFF86F9FF),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: MfPalette.onNeonGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
