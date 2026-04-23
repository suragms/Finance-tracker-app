import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/application/theme_mode_provider.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../auth/application/session_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final email = ref.watch(tokenStorageProvider).userEmail;
    final userName = email != null ? email.split('@').first : 'User';

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // PROFILE: Avatar + Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF667EEA)],
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 0),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userName[0].toUpperCase(),
                        style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName.toUpperCase(),
                    style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    email ?? 'user@moneyflow.ai',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white24, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // OPTIONS: Preferences
            _Header(label: 'PREFERENCES'),
            const SizedBox(height: 16),
            Container(
              decoration: glassCard(),
              child: Column(
                children: [
                  _OptionTile(
                    label: 'Theme',
                    icon: Icons.palette_rounded,
                    trailing: _DropdownTile(
                      value: mode == ThemeMode.dark ? 'Dark' : 'System',
                      onTap: () {},
                    ),
                  ),
                  const _Divider(),
                  _OptionTile(
                    label: 'Currency',
                    icon: Icons.payments_rounded,
                    trailing: _DropdownTile(value: 'INR (₹)', onTap: () {}),
                  ),
                  const _Divider(),
                  _OptionTile(
                    label: 'Notifications',
                    icon: Icons.notifications_active_rounded,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OPTIONS: Account
            _Header(label: 'ACCOUNT'),
            const SizedBox(height: 16),
            Container(
              decoration: glassCard(),
              child: Column(
                children: [
                  _OptionTile(
                    label: 'Sync Data',
                    icon: Icons.sync_rounded,
                    onTap: () async {
                      await ref.read(ledgerSyncServiceProvider).pullAndFlush();
                    },
                  ),
                  const _Divider(),
                  _OptionTile(
                    label: 'Logout',
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white24, letterSpacing: 1.5),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.icon, this.trailing, this.color, this.onTap});
  final String label;
  final IconData icon;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.white.withValues(alpha: 0.9);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? const Color(0xFF6366F1)),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white38),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.03), indent: 56);
  }
}
