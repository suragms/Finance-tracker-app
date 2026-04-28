import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/application/account_providers.dart';
import '../application/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.initialAccountId,
    this.initialCategoryId,
  });

  final String? initialAccountId;
  final String? initialCategoryId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String _amountStr = '0';
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _accountId;
  Map<String, dynamic>? _selectedCategory;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      if (widget.initialCategoryId != null) {
        final found = categories.firstWhere((c) => c['id'].toString() == widget.initialCategoryId, orElse: () => {});
        if (found.isNotEmpty) setState(() => _selectedCategory = found);
      } else if (categories.isNotEmpty) {
        setState(() => _selectedCategory = categories.first);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    setState(() {
      _errorText = null;
      if (val == 'back') {
        _amountStr = _amountStr.length > 1 ? _amountStr.substring(0, _amountStr.length - 1) : '0';
      } else if (val == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else {
        if (_amountStr == '0') {
          _amountStr = val;
        } else if (!(_amountStr.contains('.') && _amountStr.split('.')[1].length >= 2) && _amountStr.length < 10) {
          _amountStr += val;
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amountStr) ?? 0;
    if (amount <= 0) {
      setState(() => _errorText = 'Enter an amount');
      HapticFeedback.vibrate();
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorText = 'Select a category');
      return;
    }

    final accountsAsync = ref.read(accountsProvider);
    final effectiveAccountId = _accountId ?? accountsAsync.valueOrNull?.accounts.firstOrNull?['id'] as String?;
    if (effectiveAccountId == null) {
      setState(() => _errorText = 'Select an account');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(ledgerSyncServiceProvider).createExpenseOffline(
        amount: amount,
        categoryId: _selectedCategory!['id'].toString(),
        categoryName: _selectedCategory!['name']?.toString(),
        dateIso: _date.toUtc().toIso8601String(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        accountId: effectiveAccountId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _errorText = 'Error: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull?.accounts ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF59E0B), // Amber-500 for Expense
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Add Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(MfCurrency.symbol, style: GoogleFonts.inter(color: Colors.white70, fontSize: 32, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Text(_amountStr, style: GoogleFonts.inter(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  if (_errorText != null) Text(_errorText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildField('Category', _selectedCategory?['name'] ?? 'Select', Icons.category_outlined, () => _showCategoryPicker(categoriesAsync.valueOrNull ?? [])),
                const SizedBox(height: 16),
                _buildField('Account', accounts.firstWhere((a) => a['id'] == _accountId, orElse: () => {'name': 'Select'})['name'], Icons.account_balance_wallet_outlined, () => _showAccountPicker(accounts)),
                const SizedBox(height: 16),
                _buildField('Note', _noteController.text.isEmpty ? 'Add description' : _noteController.text, Icons.description_outlined, () => _showNoteDialog()),
                const SizedBox(height: 32),
                _buildNumpad(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7280), size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
            const Spacer(),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(children: [_num('1'), _num('2'), _num('3')]),
        const SizedBox(height: 12),
        Row(children: [_num('4'), _num('5'), _num('6')]),
        const SizedBox(height: 12),
        Row(children: [_num('7'), _num('8'), _num('9')]),
        const SizedBox(height: 12),
        Row(children: [_num('.'), _num('0'), _back()]),
      ],
    );
  }

  Widget _num(String l) => Expanded(child: TextButton(onPressed: () => _onKeyPress(l), child: Text(l, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827)))));
  Widget _back() => Expanded(child: IconButton(onPressed: () => _onKeyPress('back'), icon: const Icon(Icons.backspace_outlined, color: Color(0xFF6B7280))));

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note'),
        content: TextField(controller: _noteController, autofocus: true, decoration: const InputDecoration(hintText: 'Description')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    ).then((_) => setState(() {}));
  }

  void _showAccountPicker(List accounts) {
    showModalBottomSheet(context: context, builder: (ctx) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: accounts.map((a) => ListTile(title: Text(a['name']), onTap: () { setState(() => _accountId = a['id']); Navigator.pop(ctx); })).toList()));
  }

  void _showCategoryPicker(List cats) {
    showModalBottomSheet(context: context, builder: (ctx) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: cats.map((c) => ListTile(title: Text(c['name']), onTap: () { setState(() => _selectedCategory = c); Navigator.pop(ctx); })).toList()));
  }
}
