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
      appBar: AppBar(
        title: Text('Accounts', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AccountSetupScreen(isInitialSetup: false))),
            icon: const Icon(Icons.add_circle_outline, color: MfPalette.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: async.when(
                data: (ledger) => _NetWorthCard(total: ledger.totalNetWorth),
                loading: () => const _SkeletonCard(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          async.when(
            data: (ledger) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final a = ledger.accounts[index];
                  final id = a['id']?.toString() ?? UniqueKey().toString();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _AccountListItem(
                      key: ValueKey(id),
                      account: a,
                      onTap: () {
                        Navigator.of(context).push(
                          LedgerPageRoutes.fadeSlide<void>(
                            ExpenseListScreen(
                              accountId: id,
                              accountName: a['name']?.toString() ?? 'Account',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: ledger.accounts.length,
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, __) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MfPalette.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MfPalette.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL NET WORTH',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            MfCurrency.formatInr(total),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountListItem extends StatelessWidget {
  const _AccountListItem({super.key, required this.account, required this.onTap});
  final Map<String, dynamic> account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = account['name']?.toString() ?? 'Account';
    final bal = double.tryParse(account['balance']?.toString() ?? '0') ?? 0;
    final type = (account['type']?.toString() ?? 'bank').toLowerCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MfPalette.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(type), color: MfPalette.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MfPalette.textPrimary,
                    ),
                  ),
                  Text(
                    _subtitleForType(type),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MfPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              MfCurrency.formatInr(bal),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MfPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String t) {
    if (t.contains('credit')) return Icons.credit_card;
    if (t.contains('cash')) return Icons.payments;
    return Icons.account_balance;
  }

  String _subtitleForType(String t) {
    if (t.contains('credit')) return 'Credit Card';
    if (t.contains('cash')) return 'Cash Wallet';
    return 'Bank Account';
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );
  }
}
