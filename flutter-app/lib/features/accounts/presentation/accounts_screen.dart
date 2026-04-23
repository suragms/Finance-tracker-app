import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../application/account_providers.dart';
import 'account_setup_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACCOUNTS',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white24, letterSpacing: 1.5),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        LedgerPageRoutes.fadeSlide<void>(
                          const AccountSetupScreen(isInitialSetup: false),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('ADD ACCOUNT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: const Color(0xFF6366F1))),
                    ),
                  ),
                ],
              ),
            ),

            // LIST: Premium Cards
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white24))),
                data: (ledger) {
                  final list = ledger.accounts;
                  if (list.isEmpty) {
                    return Center(child: Text('No accounts found.', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.bold)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final a = list[index];
                      final name = a['name']?.toString() ?? 'Account';
                      final bal = double.tryParse(a['balance']?.toString() ?? '0') ?? 0;
                      final type = (a['type']?.toString() ?? 'bank').toLowerCase();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _AccountCard(
                          name: name,
                          balance: bal,
                          type: type,
                          onTap: () {
                            Navigator.of(context).push(
                              LedgerPageRoutes.fadeSlide<void>(
                                ExpenseListScreen(
                                  accountId: a['id']?.toString() ?? '',
                                  accountName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.balance,
    required this.type,
    required this.onTap,
  });

  final String name;
  final double balance;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 40, spreadRadius: -10),
          ],
        ),
        child: Stack(
          children: [
            // Ambient Glow
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 1.2),
                      ),
                      Icon(_iconForType(type), color: Colors.white24, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MfCurrency.formatInr(balance),
                    style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(String t) {
    if (t.contains('credit')) return const Color(0xFFEF4444); // Red
    if (t.contains('cash')) return const Color(0xFF10B981); // Green
    if (t.contains('wallet')) return const Color(0xFFFACC15); // Yellow/Gold
    if (t.contains('upi')) return const Color(0xFF38BDF8); // Light Blue
    return const Color(0xFF6366F1); // Indigo (Bank default)
  }

  IconData _iconForType(String t) {
    if (t.contains('credit')) return Icons.credit_card_rounded;
    if (t.contains('wallet')) return Icons.account_balance_wallet_rounded;
    if (t.contains('cash')) return Icons.payments_rounded;
    if (t.contains('upi')) return Icons.qr_code_scanner_rounded;
    return Icons.account_balance_rounded; // Bank Default
  }
}
