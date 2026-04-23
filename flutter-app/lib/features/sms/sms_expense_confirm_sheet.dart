import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format_amount.dart';
import '../../core/offline/sync/ledger_sync_service.dart';
import '../../core/theme/money_flow_tokens.dart';
import '../expenses/application/expense_providers.dart';
import '../../core/services/smart_categorization_service.dart';
import 'sms_parser.dart';

class SmsExpenseConfirmSheet extends ConsumerStatefulWidget {
  const SmsExpenseConfirmSheet({super.key, required this.txn});

  final SmsTransaction txn;

  @override
  ConsumerState<SmsExpenseConfirmSheet> createState() =>
      _SmsExpenseConfirmSheetState();
}

class _SmsExpenseConfirmSheetState
    extends ConsumerState<SmsExpenseConfirmSheet> {
  String? _categoryId;
  late TextEditingController _sourceController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(
      text: widget.txn.type == 'credit' ? widget.txn.bank : widget.txn.merchant,
    );
    
    if (widget.txn.type == 'debit') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSuggestCategory();
      });
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  void _autoSuggestCategory() {
    final categories = ref.read(categoriesProvider).value ?? [];
    final suggested = SmartCategorizationService.suggestCategoryId(
      '${widget.txn.merchant} ${widget.txn.bank}',
      categories,
    );
    if (suggested != null) {
      setState(() => _categoryId = suggested);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MfSpace.xxl,
          MfSpace.lg,
          MfSpace.xxl,
          MediaQuery.viewInsetsOf(context).bottom + MfSpace.lg,
        ),
        child: categoriesAsync.when(
          data: (categories) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatAmount(widget.txn.amount)} ${widget.txn.type} detected',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: MfSpace.xs),
                Text(
                  'From: ${widget.txn.bank} | Merchant: ${widget.txn.merchant}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: MfSpace.lg),
                Text(
                  'Amount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: MfSpace.xs),
                Text(
                  formatAmount(widget.txn.amount),
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: widget.txn.type == 'debit'
                        ? MfPalette.expenseRed
                        : MfPalette.incomeGreen,
                  ),
                ),
                const SizedBox(height: MfSpace.md),
                if (widget.txn.type == 'debit')
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  )
                else
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      labelText: 'Income Source',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: MfSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: MfSpace.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _confirmSave,
                        child: Text(_saving ? 'Saving...' : 'Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(MfSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(MfSpace.lg),
            child: Text('Failed to load categories: $e'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSave() async {
    if (widget.txn.type == 'debit') {
      if (_categoryId == null || _categoryId!.isEmpty) {
        _showError('Select a category first.');
        return;
      }
    } else {
      if (_sourceController.text.trim().isEmpty) {
        _showError('Enter income source.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final syncSvc = ref.read(ledgerSyncServiceProvider);
      if (widget.txn.type == 'debit') {
        final categories = ref.read(categoriesProvider).value ?? const [];
        String? categoryName;
        for (final c in categories) {
          if (c['id']?.toString() == _categoryId) {
            categoryName = c['name']?.toString();
            break;
          }
        }
        await syncSvc.createExpenseOffline(
          amount: widget.txn.amount,
          categoryId: _categoryId!,
          categoryName: categoryName,
          dateIso: DateTime.now().toUtc().toIso8601String(),
          note: 'SMS: ${widget.txn.bank} ${widget.txn.merchant}',
        );
      } else {
        await syncSvc.createIncomeOffline(
          amount: widget.txn.amount,
          source: _sourceController.text.trim(),
          dateIso: DateTime.now().toUtc().toIso8601String(),
          accountId: 'offline_demo_cash', // Default for SMS detection
        );
      }

      await syncSvc.pullAndFlush();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.txn.type == 'debit' ? 'Expense' : 'Income'} saved from SMS.',
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showError('Failed to save transaction: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}
