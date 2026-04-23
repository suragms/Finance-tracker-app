import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../application/account_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController(text: '0');
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(accountsProvider);
    final accounts = async.valueOrNull?.accounts ?? [];

    if (_fromAccountId == null && accounts.isNotEmpty) {
      _fromAccountId = accounts.first['id']?.toString();
      if (accounts.length > 1) {
        _toAccountId = accounts[1]['id']?.toString();
      }
    }

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'INTERNAL TRANSFER',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white24, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            // Hero: Amount Input
            Text(
              'TRANSFER AMOUNT',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white24, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₹', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w300, color: const Color(0xFF6366F1))),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white),
                    decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Flow Visualizer
            Row(
              children: [
                Expanded(child: _AccountSelectBox(label: 'FROM', accountId: _fromAccountId, accounts: accounts, onSelect: (v) => setState(() => _fromAccountId = v))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                ),
                Expanded(child: _AccountSelectBox(label: 'TO', accountId: _toAccountId, accounts: accounts, onSelect: (v) => setState(() => _toAccountId = v))),
              ],
            ),
            const SizedBox(height: 40),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: glassCard(),
              child: Column(
                children: [
                  _InfoRow(label: 'Transfer Fee', value: '₹0.00', icon: Icons.info_outline_rounded),
                  const Divider(color: Colors.white10, height: 1),
                  _InfoRow(label: 'Estimated Arrival', value: 'Instant', icon: Icons.bolt_rounded, color: const Color(0xFF10B981)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ),
          child: Text('CONFIRM TRANSFER', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}

class _AccountSelectBox extends StatelessWidget {
  const _AccountSelectBox({required this.label, this.accountId, required this.accounts, required this.onSelect});
  final String label;
  final String? accountId;
  final List<Map<String, dynamic>> accounts;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final account = accounts.firstWhere((a) => a['id']?.toString() == accountId, orElse: () => {});
    final name = account['name']?.toString() ?? 'Select';

    return GestureDetector(
      onTap: () {
        // Show account picker
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: glassCard(borderRadius: 20),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 9, color: Colors.white24, letterSpacing: 1)),
            const SizedBox(height: 12),
            const Icon(Icons.account_balance_rounded, color: Colors.white54, size: 24),
            const SizedBox(height: 12),
            Text(name.toUpperCase(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.icon, this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)),
          const Spacer(),
          Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: color ?? Colors.white)),
        ],
      ),
    );
  }
}
