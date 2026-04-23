import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/mf_ui_system.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../application/account_providers.dart';
import '../data/accounts_api.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key, this.isInitialSetup = true});

  final bool isInitialSetup;

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  final List<String> _accountTypes = ['cash', 'bank', 'upi', 'wallet'];
  String _selectedType = 'bank';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final balStr = _balanceController.text.replaceAll(',', '');
    final balance = double.tryParse(balStr) ?? 0.0;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter an account name');
      return;
    }

    if (balance < 0) {
      setState(() => _error = 'Initial balance cannot be negative');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(accountsApiProvider);
      await api.create(name: name, type: _selectedType, initialBalance: balance);

      // Force a pull from remote to update Drift DB and account state immediately
      final syncSvc = ref.read(ledgerSyncServiceProvider);
      await syncSvc.pullAndFlush();
      
      if (!widget.isInitialSetup && mounted) {
        Navigator.of(context).pop();
      }
      // If isInitialSetup is true, Riverpod AuthGuard automatically routes to dashboard once state updates.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create account: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfPalette.surface,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isInitialSetup)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: MfPalette.primaryIndigo.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: MfPalette.primaryIndigo, size: 36),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isInitialSetup ? 'Create your first account' : 'Add new account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isInitialSetup ? 'Track where your money lives' : 'Expanding your portfolio',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.white60),
                    ),
                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                        child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCOUNT NAME',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: MfPalette.textSecondary, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 8),
                          _InputTile(
                            controller: _nameController,
                            hint: 'e.g., Main Checking, Cash',
                            icon: Icons.edit_rounded,
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'ACCOUNT TYPE',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: MfPalette.textSecondary, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.start,
                            children: _accountTypes.map((t) => _TypeChip(
                              type: t,
                              selected: _selectedType == t,
                              onTap: () => setState(() => _selectedType = t),
                            )).toList(),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'INITIAL BALANCE',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: MfPalette.textSecondary, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 8),
                          _InputTile(
                            controller: _balanceController,
                            hint: '0.00',
                            icon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: MfPrimaryButton(
                label: 'Create Account',
                onPressed: _loading ? () {} : _submit,
                isLoading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, required this.selected, required this.onTap});
  final String type;
  final bool selected;
  final VoidCallback onTap;

  String _format(String t) {
    if (t == 'upi') return 'UPI';
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? MfPalette.primaryIndigo : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          _format(type),
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
