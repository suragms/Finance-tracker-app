import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/application/account_providers.dart';
import '../application/expense_providers.dart';
import '../../../core/services/smart_categorization_service.dart';

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
  Map<String, dynamic>? _selectedSubcategory;
  bool _manuallySetCategory = false;
  bool _isAutoSuggested = false;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    
    // If initial category is provided, try to find it
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        if (categories.isNotEmpty) {
          final found = categories.firstWhere(
            (c) => c['id'].toString() == widget.initialCategoryId,
            orElse: () => <String, dynamic>{},
          );
          if (found.isNotEmpty) {
            setState(() => _selectedCategory = found);
          }
        }
      });
    }
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
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (val == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = val;
        } else if (_amountStr.contains('.') && _amountStr.split('.')[1].length >= 2) {
          return;
        } else if (_amountStr.length >= 9) {
          return; // Prevent excessively large numbers
        } else {
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
      setState(() => _errorText = 'Please enter an amount');
      HapticFeedback.vibrate();
      return;
    }

    if (_selectedCategory == null) {
      setState(() => _errorText = 'Please select a category');
      HapticFeedback.vibrate();
      return;
    }

    final accountsAsync = ref.read(accountsProvider);
    final effectiveAccountId = _accountId ?? 
        accountsAsync.valueOrNull?.accounts.firstOrNull?['id'] as String?;

    if (effectiveAccountId == null) {
      setState(() => _errorText = 'Please select an account');
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      final syncSvc = ref.read(ledgerSyncServiceProvider);
      await syncSvc.createExpenseOffline(
        amount: amount,
        categoryId: _selectedCategory!['id'].toString(),
        categoryName: _selectedCategory!['name']?.toString(),
        subCategoryId: _selectedSubcategory?['id']?.toString(),
        dateIso: _date.toUtc().toIso8601String(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        accountId: effectiveAccountId,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        // Show snackbar BEFORE popping
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('₹$amount expense recorded'),
            backgroundColor: MfPalette.expenseAmber,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
          ),
        );
        // Reset form state
        setState(() {
          _amountStr = '0';
          _selectedCategory = null;
          _selectedSubcategory = null;
          _manuallySetCategory = false;
          _isAutoSuggested = false;
          _saving = false;
        });
        _noteController.clear();
        // Pop after short delay so user sees the updated form
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Failed to save: $e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull?.accounts ?? [];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MfPalette.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Expense',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          // Amount Display Area
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TOTAL SPENT',
                    style: GoogleFonts.inter(
                      color: MfPalette.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FittedBox(
                      child: Text(
                        '₹$_amountStr',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 80,
                            ),
                      ),
                    ),
                  ),
                  if (_errorText != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorText!,
                        style: GoogleFonts.inter(
                          color: MfPalette.expenseRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(MfRadius.xl)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Row
                categoriesAsync.when(
                  data: (list) => _buildCategoryRow(list),
                  loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, __) => const Text('Error loading categories', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 24),

                // Account & Date Tiles
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'From Account',
                        value: _accountId != null 
                            ? accounts.firstWhere((a) => a['id'] == _accountId, orElse: () => {'name': 'Select'})['name']
                            : (accounts.isNotEmpty ? accounts.first['name'] : 'Select'),
                        onTap: () => _showAccountPicker(accounts),
                        color: MfPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSelectorTile(
                        icon: Icons.calendar_month_rounded,
                        label: 'Date',
                        value: DateFormat('EEE, dd MMM').format(_date),
                        onTap: () => _pickDate(),
                        color: MfPalette.accentSoftPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Note Tile
                _buildNoteTile(),
              ],
            ),
          ),

          // Numpad
          _buildModernNumpad(),
          
          // Confirm Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
            color: Theme.of(context).colorScheme.surface,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MfPalette.expenseAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
                elevation: 4,
        shadowColor: MfPalette.expenseAmber.withValues(alpha: 0.4),
              ),
              child: _saving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Save Expense',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildCategoryRow(List<Map<String, dynamic>> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATEGORY',
              style: GoogleFonts.inter(
                color: MfPalette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            if (_isAutoSuggested)
               Text(
                'AI SUGGESTED',
                style: GoogleFonts.inter(
                  color: MfPalette.neonGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catId = cat['id']?.toString() ?? 'cat-$index';
              final isSelected = _selectedCategory?['id']?.toString() == catId;
              final systemKey = cat['systemKey']?.toString() ?? 'custom';
              final color = isSelected ? MfCategoryColors.forSystemKey(systemKey) : MfPalette.textMuted;
              
              return GestureDetector(
                key: ValueKey(catId),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _manuallySetCategory = true;
                    _isAutoSuggested = false;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? color.withValues(alpha: 0.15) 
                            : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getIcon(systemKey),
                          size: 24,
                          color: isSelected ? color : MfPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MfRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MfRadius.md),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: MfPalette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTile() {
    return InkWell(
      onTap: () => _showNoteDialog(),
      borderRadius: BorderRadius.circular(MfRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(MfRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: MfPalette.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _noteController.text.isEmpty ? 'Description (Optional)' : _noteController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: _noteController.text.isEmpty ? MfPalette.textMuted : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNumpad() {
    return Container(
      color: MfPalette.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              _numpadBtn('1'), _numpadBtn('2'), _numpadBtn('3'),
            ],
          ),
          Row(
            children: [
              _numpadBtn('4'), _numpadBtn('5'), _numpadBtn('6'),
            ],
          ),
          Row(
            children: [
              _numpadBtn('7'), _numpadBtn('8'), _numpadBtn('9'),
            ],
          ),
          Row(
            children: [
              _numpadBtn('.'), _numpadBtn('0'), _numpadBtn('back', icon: Icons.backspace_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadBtn(String label, {IconData? icon}) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPress(label),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: icon != null 
            ? Icon(icon, color: MfPalette.textMuted, size: 22)
            : Text(
                label,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
        ),
      ),
    );
  }

  IconData _getIcon(String k) {
    k = k.toLowerCase();
    if (k.contains('food')) return Icons.restaurant_rounded;
    if (k.contains('home')) return Icons.home_rounded;
    if (k.contains('tran')) return Icons.directions_car_rounded;
    if (k.contains('shop')) return Icons.shopping_bag_rounded;
    if (k.contains('health')) return Icons.medical_services_rounded;
    if (k.contains('ent')) return Icons.movie_rounded;
    if (k.contains('bill')) return Icons.receipt_long_rounded;
    if (k.contains('educ')) return Icons.school_rounded;
    return Icons.grid_view_rounded;
  }

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
        title: Text('Expense Note', style: Theme.of(context).textTheme.titleLarge),
        content: TextField(
          controller: _noteController,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'What was this expense for?',
            hintStyle: const TextStyle(color: MfPalette.textHint),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(MfRadius.md), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MfPalette.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              _applySmartCategorization();
              Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: MfPalette.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applySmartCategorization() {
    if (_manuallySetCategory || _noteController.text.trim().isEmpty) return;

    final categoriesAsync = ref.read(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    
    final suggestedId = SmartCategorizationService.suggestCategoryId(
      _noteController.text, 
      categories,
    );

    if (suggestedId != null) {
      final suggestedCat = categories.firstWhere((c) => c['id'].toString() == suggestedId.toString());
      setState(() {
        _selectedCategory = suggestedCat;
        _isAutoSuggested = true;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MfPalette.accentSoftPurple,
              onPrimary: Colors.white,
              surface: MfPalette.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }  void _showAccountPicker(List accounts) {
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
            Text('Select Account', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 20),
            ...accounts.map((a) {
              final isSelected = _accountId == a['id'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
                tileColor: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: MfPalette.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: MfPalette.primary, size: 20),
                ),
                title: Text(a['name']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
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
