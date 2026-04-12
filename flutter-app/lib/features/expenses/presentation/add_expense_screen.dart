import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/application/account_providers.dart';
import '../application/expense_providers.dart';
import '../data/categories_api.dart';

// Minimal dark expense form palette.
const Color _aeBg = Color(0xFF0D0D0D);
const Color _aeSurface = Color(0xFF141418);
const Color _aeField = Color(0xFF1C1C22);
const Color _aeBorder = Color(0xFF32323A);

InputDecoration _aeFieldDec({
  required String label,
  String? hint,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  ),
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.45),
    ),
    hintStyle: GoogleFonts.inter(
      color: Colors.white.withValues(alpha: 0.28),
    ),
    floatingLabelStyle: GoogleFonts.inter(
      color: MfPalette.neonGreen,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: _aeField,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: const BorderSide(color: _aeBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: const BorderSide(color: _aeBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: MfPalette.neonGreen, width: 2),
    ),
    contentPadding: contentPadding,
  );
}

InputDecoration _aeAmountDec() {
  return InputDecoration(
    filled: true,
    fillColor: _aeField,
    prefixText: '${MfCurrency.symbol} ',
    prefixStyle: GoogleFonts.manrope(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.lg),
      borderSide: const BorderSide(color: _aeBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.lg),
      borderSide: const BorderSide(color: _aeBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.lg),
      borderSide: BorderSide(color: MfPalette.neonGreen, width: 2.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
  );
}

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _taxAmount = TextEditingController();

  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _subId;
  String? _accountId;
  bool _saving = false;
  bool _taxable = false;
  String _taxScheme = 'gst_in';

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _taxAmount.dispose();
    super.dispose();
  }

  void _showSnack(
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _aeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.md),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        content: Row(
          children: [
            Icon(icon, size: 20, color: MfPalette.neonGreen),
            const SizedBox(width: MfSpace.sm),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _createCategory(
    String name, {
    bool announce = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _showSnack(
        'Enter a category name first.',
        icon: Icons.label_outline_rounded,
      );
      return <String, dynamic>{};
    }

    try {
      final created = await ref
          .read(categoriesApiProvider)
          .createCategory(trimmed);
      ref.invalidate(categoriesProvider);
      if (announce) {
        _showSnack(
          'Category added successfully.',
          icon: Icons.check_circle_outline_rounded,
        );
      }
      return created;
    } on DioException catch (e) {
      _showSnack(dioErrorMessage(e), icon: Icons.error_outline_rounded);
      rethrow;
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    var creating = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.dark(
              primary: MfPalette.neonGreen,
              surface: _aeSurface,
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: _aeSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MfRadius.lg),
                ),
                title: Text(
                  'Add category',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: _aeFieldDec(
                    label: 'Category name',
                    hint: 'e.g. Groceries',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) async {
                    if (creating) return;
                    final created = await _createCategory(
                      controller.text,
                      announce: false,
                    );
                    if (!mounted || created.isEmpty) return;
                    setState(() {
                      _categoryId = created['id']?.toString() ?? _categoryId;
                      _subId = null;
                    });
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    _showSnack(
                      'Category added successfully.',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: creating
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MfPalette.neonGreen,
                      foregroundColor: MfPalette.onNeonGreen,
                    ),
                    onPressed: creating
                        ? null
                        : () async {
                            setDialogState(() => creating = true);
                            try {
                              final created = await _createCategory(
                                controller.text,
                                announce: false,
                              );
                              if (!mounted || created.isEmpty) return;
                              setState(() {
                                _categoryId =
                                    created['id']?.toString() ?? _categoryId;
                                _subId = null;
                              });
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              _showSnack(
                                'Category added successfully.',
                                icon: Icons.check_circle_outline_rounded,
                              );
                            } catch (_) {
                              if (dialogContext.mounted) {
                                setDialogState(() => creating = false);
                              }
                            }
                          },
                    child: creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Add',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.dark(
              primary: MfPalette.neonGreen,
              onPrimary: MfPalette.onNeonGreen,
              surface: _aeSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_categoryId == null) {
      _showSnack(
        'Pick a category before saving.',
        icon: Icons.category_outlined,
      );
      return;
    }
    if (_accountId == null || _accountId!.isEmpty) {
      _showSnack(
        'Pick an account before saving.',
        icon: Icons.account_balance_wallet_outlined,
      );
      return;
    }

    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      _showSnack(
        'Enter a valid expense amount.',
        icon: Icons.currency_rupee_rounded,
      );
      return;
    }

    double? taxAmt;
    if (_taxable) {
      taxAmt = double.tryParse(_taxAmount.text.trim().replaceAll(',', ''));
      if (taxAmt == null || taxAmt < 0 || taxAmt > amt) {
        _showSnack(
          'Enter a valid tax amount between 0 and the expense amount.',
          icon: Icons.receipt_long_outlined,
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final iso = _date.toUtc().toIso8601String();
      final cats =
          ref.read(categoriesProvider).value ?? const <Map<String, dynamic>>[];
      String? catName;
      for (final c in cats) {
        if (c['id']?.toString() == _categoryId) {
          catName = c['name']?.toString();
          break;
        }
      }
      await ref
          .read(ledgerSyncServiceProvider)
          .createExpenseOffline(
            amount: amt,
            categoryId: _categoryId!,
            categoryName: catName,
            subCategoryId: _subId,
            dateIso: iso,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            accountId: _accountId,
            taxable: _taxable,
            taxScheme: _taxable ? _taxScheme : null,
            taxAmount: _taxable ? taxAmt : null,
          );
      await ref.read(ledgerSyncServiceProvider).pullAndFlush();
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(dioErrorMessage(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final accs = ref.watch(accountsProvider);
    final today = DateTime.now();
    final isToday =
        _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _aeBg,
      appBar: AppBar(
        backgroundColor: _aeBg,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Add expense',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: cats.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(MfSpace.xxl),
                children: [
                  Text(
                    'No categories yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: MfSpace.sm),
                  Text(
                    'Create your first expense category to continue.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: MfSpace.xl),
                  _InlineCategoryCreator(
                    onCreated: (name) async {
                      final created = await _createCategory(name);
                      if (!mounted || created.isEmpty) return;
                      setState(() {
                        _categoryId =
                            created['id']?.toString() ?? _categoryId;
                      });
                    },
                  ),
                ],
              );
            }

            Map<String, dynamic>? selected;
            for (final c in list) {
              if (c['id']?.toString() == _categoryId) {
                selected = c;
              }
            }

            final subs =
                (selected?['subCategoryRows'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

            final dropdownStyle = GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            );

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.md,
                MfSpace.xxl,
                MfSpace.xxl + bottomInset,
              ),
              children: [
                Text(
                  'Amount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: MfSpace.sm),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                  cursorColor: MfPalette.neonGreen,
                  decoration: _aeAmountDec(),
                ),
                const SizedBox(height: MfSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Category',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: _aeField,
                        foregroundColor: MfPalette.neonGreen,
                      ),
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      tooltip: 'Add category',
                    ),
                  ],
                ),
                const SizedBox(height: MfSpace.sm),
                DropdownButtonFormField<String>(
                  key: ValueKey('cat-$_categoryId'),
                  initialValue: _categoryId,
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  dropdownColor: _aeField,
                  iconEnabledColor: Colors.white.withValues(alpha: 0.65),
                  style: dropdownStyle,
                  decoration: _aeFieldDec(
                    label: 'Select category',
                    hint: 'Shopping, food…',
                  ),
                  items: list
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c['id']?.toString(),
                          child: Text(c['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _categoryId = v;
                    _subId = null;
                  }),
                ),
                if (subs.isNotEmpty) ...[
                  const SizedBox(height: MfSpace.lg),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('sub-$_subId'),
                    initialValue: _subId,
                    borderRadius: BorderRadius.circular(MfRadius.md),
                    dropdownColor: _aeField,
                    iconEnabledColor: Colors.white.withValues(alpha: 0.65),
                    style: dropdownStyle,
                    decoration: _aeFieldDec(
                      label: 'Subcategory',
                      hint: 'Optional',
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None',
                          style: dropdownStyle,
                        ),
                      ),
                      ...subs.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s['id']?.toString(),
                          child: Text(s['name']?.toString() ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _subId = v),
                  ),
                ],
                const SizedBox(height: MfSpace.lg),
                accs.when(
                  data: (ledger) {
                    final accounts = ledger.accounts;
                    if (accounts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: MfSpace.md),
                        child: Text(
                          'Add an account under Profile → Accounts first.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: MfPalette.expenseRed.withValues(alpha: 0.9),
                          ),
                        ),
                      );
                    }

                    final accVal =
                        _accountId != null &&
                            accounts.any(
                              (a) => a['id']?.toString() == _accountId,
                            )
                        ? _accountId
                        : null;

                    return DropdownButtonFormField<String>(
                      key: ValueKey('acc-$accVal'),
                      initialValue: accVal,
                      borderRadius: BorderRadius.circular(MfRadius.md),
                      dropdownColor: _aeField,
                      iconEnabledColor: Colors.white.withValues(alpha: 0.65),
                      style: dropdownStyle,
                      decoration: _aeFieldDec(label: 'Account'),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem<String>(
                              value: a['id']?.toString(),
                              child: Text(
                                '${a['name']?.toString() ?? ''} (${MfCurrency.formatInr(a['balance'])})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _accountId = v),
                    );
                  },
                  loading: () => LinearProgressIndicator(
                    color: MfPalette.neonGreen,
                    backgroundColor: _aeField,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  error: (e, _) => Text(
                    'Could not load accounts.',
                    style: GoogleFonts.inter(color: MfPalette.expenseRed),
                  ),
                ),
                const SizedBox(height: MfSpace.lg),
                Text(
                  'Date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: MfSpace.sm),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(MfRadius.md),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MfSpace.lg,
                        vertical: MfSpace.lg,
                      ),
                      decoration: BoxDecoration(
                        color: _aeField,
                        borderRadius: BorderRadius.circular(MfRadius.md),
                        border: Border.all(color: _aeBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: MfPalette.neonGreen,
                          ),
                          const SizedBox(width: MfSpace.md),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, d MMM yyyy').format(_date),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MfPalette.neonGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: MfPalette.neonGreen.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: MfPalette.neonGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MfSpace.lg),
                TextField(
                  controller: _note,
                  minLines: 1,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  cursorColor: MfPalette.neonGreen,
                  decoration: _aeFieldDec(
                    label: 'Description',
                    hint: 'What was this for?',
                  ),
                ),
                const SizedBox(height: MfSpace.xl),
                SwitchTheme(
                  data: SwitchThemeData(
                    thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? MfPalette.neonGreen
                          : Colors.white54,
                    ),
                    trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? MfPalette.neonGreen.withValues(alpha: 0.35)
                          : _aeBorder,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _taxable,
                    onChanged: (v) => setState(() => _taxable = v),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Taxable (GST / VAT)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message:
                              'Track GST or VAT on this expense.',
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Optional — for business or tax reporting',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                if (_taxable) ...[
                  const SizedBox(height: MfSpace.md),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_taxScheme),
                    initialValue: _taxScheme,
                    borderRadius: BorderRadius.circular(MfRadius.md),
                    dropdownColor: _aeField,
                    iconEnabledColor: Colors.white.withValues(alpha: 0.65),
                    style: dropdownStyle,
                    decoration: _aeFieldDec(label: 'Tax type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'gst_in',
                        child: Text('India GST'),
                      ),
                      DropdownMenuItem(
                        value: 'vat_ae',
                        child: Text('UAE VAT'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _taxScheme = v ?? 'gst_in'),
                  ),
                  const SizedBox(height: MfSpace.lg),
                  TextField(
                    controller: _taxAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    cursorColor: MfPalette.neonGreen,
                    decoration: _aeFieldDec(
                      label: 'Tax amount',
                      hint: 'Included in amount above',
                    ).copyWith(
                      prefixText: '${MfCurrency.symbol} ',
                      prefixStyle: GoogleFonts.manrope(
                        color: MfPalette.neonGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: MfSpace.xxxl),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: MfPalette.neonGreen,
                      foregroundColor: MfPalette.onNeonGreen,
                      disabledBackgroundColor: MfPalette.neonGreen.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MfRadius.lg),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: MfPalette.onNeonGreen.withValues(alpha: 0.9),
                            ),
                          )
                        : Text(
                            'Save expense',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: MfPalette.neonGreen),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(MfSpace.xl),
              child: Text(
                'Something went wrong. Pull to refresh or try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineCategoryCreator extends StatefulWidget {
  const _InlineCategoryCreator({required this.onCreated});

  final Future<void> Function(String name) onCreated;

  @override
  State<_InlineCategoryCreator> createState() => _InlineCategoryCreatorState();
}

class _InlineCategoryCreatorState extends State<_InlineCategoryCreator> {
  final _controller = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      await widget.onCreated(name);
      if (!mounted) return;
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: _aeFieldDec(
            label: 'Category name',
            hint: 'e.g. Groceries',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: MfSpace.lg),
        FilledButton(
          onPressed: _creating ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: MfPalette.neonGreen,
            foregroundColor: MfPalette.onNeonGreen,
            padding: const EdgeInsets.symmetric(vertical: MfSpace.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MfRadius.lg),
            ),
          ),
          child: _creating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MfPalette.onNeonGreen.withValues(alpha: 0.9),
                  ),
                )
              : Text(
                  'Create & continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ],
    );
  }
}
