import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/application/theme_mode_provider.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_notifier.dart';
import '../../expenses/presentation/recurring_management_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  String _userNameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return 'MoneyFlow User';
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'MoneyFlow User';
    final words = local.split(RegExp(r'[._\-]+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _onSync() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync completed')));
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final email = ref.watch(tokenStorageProvider).userEmail;
    final userName = _userNameFromEmail(email);
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'M';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 24, color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primary,
                    child: Text(
                      userInitial,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ?? 'user@moneyflow.ai',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: const Color(0xFF9CA3AF)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const _SectionTitle(label: 'FINANCIAL'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.repeat_rounded,
                  label: 'Recurring Bills',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecurringManagementScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: const Color(0xFF374151), indent: 56),
                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Accounts & Wallets',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _SectionTitle(label: 'PREFERENCES'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  label: 'Theme',
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: mode,
                      dropdownColor: cs.surfaceContainerHigh,
                      style: GoogleFonts.inter(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                      iconEnabledColor: const Color(0xFF9CA3AF),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(themeModeProvider.notifier).setMode(v);
                        }
                      },
                    ),
                  ),
                ),
                Divider(height: 1, color: const Color(0xFF374151), indent: 56),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: cs.primary,
                    activeTrackColor: cs.primary.withValues(alpha: 0.3),
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const _SectionTitle(label: 'SYSTEM'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.cloud_sync_outlined,
                  label: 'Sync Data',
                  onTap: _onSync,
                ),
                Divider(height: 1, color: const Color(0xFF374151), indent: 56),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: const Color(0xFFEF4444),
                  hideArrow: true,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFF9CA3AF), // Tailwind Gray-400
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.color,
    this.onTap,
    this.hideArrow = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  final bool hideArrow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallbackColor = color ?? cs.primary;
    final textColor = color ?? cs.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fallbackColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: fallbackColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) 
              trailing!
            else if (!hideArrow && onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280), // Tailwind Gray-500
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
