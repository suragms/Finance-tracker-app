import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/application/account_providers.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _amountController = TextEditingController(text: '0');
  final _sourceController = TextEditingController(); 
  final _noteController = TextEditingController();

  DateTime _date = DateTime.now();
  String? _accountId;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    
    setState(() {
      _errorText = null;
      _saving = true;
    });

    final amountStr = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountStr) ?? 0.0;
    final source = _sourceController.text.trim();

    if (amount <= 0) {
      setState(() {
        _errorText = 'Please enter a valid amount greater than 0';
        _saving = false;
      });
      return;
    }

    if (source.isEmpty) {
      setState(() {
        _errorText = 'Please specify the income source (e.g. Salary, Client)';
        _saving = false;
      });
      return;
    }

    final accountsAsync = ref.read(accountsProvider);
    final effectiveAccountId = _accountId ?? 
        accountsAsync.valueOrNull?.accounts.firstOrNull?['id'] as String?;

    if (effectiveAccountId == null) {
      setState(() {
        _errorText = 'Please ensure you have an account available before saving';
        _saving = false;
      });
      return;
    }

    try {
      final syncSvc = ref.read(ledgerSyncServiceProvider);
      await syncSvc.createIncomeOffline(
        amount: amount,
        source: source,
        dateIso: _date.toUtc().toIso8601String(),
        accountId: effectiveAccountId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully'),
            backgroundColor: MfPalette.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Failed to add income: $e';
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MfPalette.incomeGreen,
              onPrimary: Colors.black,
              surface: MfPalette.canvas,
              onSurface: MfPalette.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull?.accounts ?? [];

    const primaryColor = MfPalette.incomeGreen;
    
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        backgroundColor: MfPalette.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: MfPalette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Income',
          style: GoogleFonts.manrope(
            color: MfPalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      color: MfPalette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          style: GoogleFonts.manrope(
                            color: primaryColor,
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: MfPalette.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_errorText != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  _buildFieldRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'ACCOUNT',
                    child: InkWell(
                      onTap: () => _showAccountPicker(accounts),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _accountId != null 
                              ? accounts.firstWhere((a) => a['id'] == _accountId, orElse: () => {'name': 'Select'})['name']?.toString() ?? 'Select'
                              : (accounts.isNotEmpty ? accounts.first['name'] : 'Select'),
                          style: GoogleFonts.inter(color: MfPalette.textPrimary, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: MfSurface.cardAlt),
                  _buildFieldRow(
                    icon: Icons.business_center_rounded,
                    label: 'SOURCE',
                    child: TextField(
                      controller: _sourceController,
                      style: GoogleFonts.inter(color: MfPalette.textPrimary, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Salary, Freelance, etc.',
                        hintStyle: TextStyle(color: MfPalette.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Divider(color: MfSurface.cardAlt),
                  _buildFieldRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'DATE',
                    child: InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_date),
                          style: GoogleFonts.inter(color: MfPalette.textPrimary, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: MfSurface.cardAlt),
                  _buildFieldRow(
                    icon: Icons.notes_rounded,
                    label: 'NOTE',
                    child: TextField(
                      controller: _noteController,
                      style: GoogleFonts.inter(color: MfPalette.textPrimary, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Add details...',
                        hintStyle: TextStyle(color: MfPalette.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.3),
              ),
              child: Text(
                'Add Income',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountPicker(List accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MfPalette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MfRadius.xl))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Account', 
              style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 20),
            ...accounts.map((a) {
              final isSelected = _accountId == a['id'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
                tileColor: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MfPalette.incomeGreen.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: MfPalette.incomeGreen, size: 20),
                ),
                title: Text(a['name']?.toString() ?? '', 
                  style: GoogleFonts.inter(color: Colors.white, 
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: MfPalette.neonGreen) : null,
                onTap: () {
                  setState(() => _accountId = a['id']);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
