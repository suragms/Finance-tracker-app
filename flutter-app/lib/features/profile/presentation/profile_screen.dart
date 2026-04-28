import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/application/theme_mode_provider.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/providers.dart';
import '../../auth/application/session_notifier.dart';
import 'package:moneyflow_ai/features/recurring/presentation/recurring_list_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
  Widget build(BuildContext context) {
    final email = ref.watch(tokenStorageProvider).userEmail;
    final userName = _userNameFromEmail(email);
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: MfPalette.primary.withValues(alpha: 0.1),
                  child: Text(userInitial, style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w700, color: MfPalette.primary)),
                ),
                const SizedBox(height: 16),
                Text(userName, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: MfPalette.textPrimary)),
                Text(email ?? '', style: GoogleFonts.inter(fontSize: 14, color: MfPalette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSection('Settings', [
            _ProfileTile(
              icon: Icons.palette_outlined,
              label: 'App Theme',
              subtitle: mode == ThemeMode.system ? 'System Default' : (mode == ThemeMode.light ? 'Light' : 'Dark'),
              color: MfPalette.primary,
              onTap: () => _showThemePicker(context, ref, mode),
            ),
            _ProfileTile(
              icon: Icons.repeat_rounded,
              label: 'Recurring Payments',
              subtitle: 'Manage automatic bills',
              color: MfPalette.incomeGreen,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringListScreen())),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Account', [
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              subtitle: 'Sign out of your account',
              color: MfPalette.textSecondary,
              onTap: () => ref.read(sessionProvider.notifier).logout(),
            ),
            _ProfileTile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Account',
              subtitle: 'Permanently remove all data',
              color: MfPalette.expenseAmber,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 40),
          Text(
            'MoneyFlow AI v2.5.0\nSecure • Private • Fast',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: MfPalette.textHint),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: MfPalette.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('App Theme', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _themeTile(ref, 'System Default', ThemeMode.system, current == ThemeMode.system),
            _themeTile(ref, 'Light', ThemeMode.light, current == ThemeMode.light),
            _themeTile(ref, 'Dark', ThemeMode.dark, current == ThemeMode.dark),
          ],
        ),
      ),
    );
  }

  Widget _themeTile(WidgetRef ref, String label, ThemeMode mode, bool selected) {
    return ListTile(
      title: Text(label, style: GoogleFonts.inter(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      onTap: () { ref.read(themeModeProvider.notifier).setMode(mode); Navigator.pop(context); },
      trailing: selected ? const Icon(Icons.check, color: MfPalette.primary) : null,
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.subtitle, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: MfPalette.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: MfPalette.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
    );
  }
}
