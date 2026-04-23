import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/api_config.dart';
import '../../../core/dio_errors.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/recurring_provider.dart';

class AddRecurringScreen extends ConsumerStatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  ConsumerState<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends ConsumerState<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();

  String? _categoryId;
  String? _subCategoryId;
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _reminderEnabled = true;
  bool _autoAdd = false;
  bool _saving = false;

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'custom':
        return 'Custom';
      default:
        return frequency;
    }
  }

  String _frequencyPreview() {
    switch (_frequency) {
      case 'weekly':
        return 'Every ${DateFormat('EEEE').format(_startDate)}';
      case 'monthly':
        final day = _startDate.day;
        final suffix = (day >= 11 && day <= 13)
            ? 'th'
            : switch (day % 10) {
                1 => 'st',
                2 => 'nd',
                3 => 'rd',
                _ => 'th',
              };
        return 'Every month on $day$suffix';
      case 'custom':
        return 'Custom schedule from ${DateFormat('d MMM yyyy').format(_startDate)}';
      default:
        return 'Every ${_frequencyLabel(_frequency).toLowerCase()}';
    }
  }

  Future<void> _pickFrequency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: MfSurface.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MfRadius.xl)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final options = const <Map<String, String>>[
          {'id': 'weekly', 'title': 'Weekly', 'subtitle': 'Repeat every week'},
          {
            'id': 'monthly',
            'title': 'Monthly',
            'subtitle': 'Repeat every month'
          },
          {
            'id': 'custom',
            'title': 'Custom',
            'subtitle': 'Define a custom cadence'
          },
        ];
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.md,
              MfSpace.xxl,
              MfSpace.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: MfSpace.lg),
                Text(
                  'Select Frequency',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: MfSpace.md),
                ...options.map((o) {
                  final id = o['id']!;
                  final selected = _frequency == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: MfSpace.sm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MfRadius.md),
                      onTap: () => Navigator.of(ctx).pop(id),
                      child: AnimatedContainer(
                        duration: MfMotion.fast,
                        padding: const EdgeInsets.all(MfSpace.md),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.14)
                              : MfSurface.inputFill,
                          borderRadius: BorderRadius.circular(MfRadius.md),
                          border: Border.all(
                            color: selected ? cs.primary : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              id == 'weekly'
                                  ? Icons.view_week_rounded
                                  : id == 'monthly'
                                      ? Icons.event_repeat_rounded
                                      : Icons.tune_rounded,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: MfSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o['title']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    o['subtitle']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_circle_rounded,
                                  color: cs.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _frequency = picked);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_categoryId == null || _categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a category.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than 0.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (kNoApiMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring API is unavailable in demo mode.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post<dynamic>(
        '/api/recurring',
        data: {
          'name': _name.text.trim(),
          'title': _name.text.trim(),
          'amount': amount,
          'categoryId': _categoryId,
          if (_subCategoryId != null && _subCategoryId!.isNotEmpty)
            'subcategoryId': _subCategoryId,
          if (_subCategoryId != null && _subCategoryId!.isNotEmpty)
            'subCategoryId': _subCategoryId,
          'frequency': _frequency,
          'startDate': _startDate.toUtc().toIso8601String(),
          'nextDate': _startDate.toUtc().toIso8601String(),
          'reminderEnabled': _reminderEnabled,
          'autoAdd': _autoAdd,
          'autoCreateExpense': _autoAdd,
        },
      );
      ref.invalidate(recurringProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring entry created.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dioErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Recurring')),
      body: categoriesAsync.when(
        data: (categories) {
          Map<String, dynamic>? selectedCategory;
          for (final category in categories) {
            if (category['id']?.toString() == _categoryId) {
              selectedCategory = category;
              break;
            }
          }
          final subRows =
              (selectedCategory?['subCategoryRows'] as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];

          return ListView(
            padding: EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.lg,
              MfSpace.xxl,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MfSpace.lg),
                    TextFormField(
                      controller: _amount,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final amt = double.tryParse(
                          (value ?? '').trim().replaceAll(',', ''),
                        );
                        if (amt == null || amt <= 0) {
                          return 'Enter a valid amount > 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MfSpace.lg),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category['id']?.toString(),
                              child: Text(category['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoryId = value;
                          _subCategoryId = null;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MfSpace.lg),
                    DropdownButtonFormField<String>(
                      initialValue: _subCategoryId,
                      decoration:
                          const InputDecoration(labelText: 'Subcategory'),
                      items: subRows
                          .map(
                            (sub) => DropdownMenuItem<String>(
                              value: sub['id']?.toString(),
                              child: Text(sub['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _subCategoryId = value),
                    ),
                    const SizedBox(height: MfSpace.lg),
                    Text(
                      'Frequency',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: MfSpace.sm),
                    InkWell(
                      onTap: _pickFrequency,
                      borderRadius: BorderRadius.circular(MfRadius.md),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(MfSpace.md),
                        decoration: BoxDecoration(
                          color: MfSurface.inputFill,
                          borderRadius: BorderRadius.circular(MfRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat_rounded, size: 18),
                            const SizedBox(width: MfSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _frequencyLabel(_frequency),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _frequencyPreview(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: MfSpace.lg),
                    InkWell(
                      borderRadius: BorderRadius.circular(MfRadius.md),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: MfSpace.lg),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder ON/OFF'),
                      value: _reminderEnabled,
                      onChanged: (value) {
                        setState(() => _reminderEnabled = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-create expense on due date'),
                      value: _autoAdd,
                      onChanged: (value) {
                        setState(() => _autoAdd = value);
                      },
                    ),
                    const SizedBox(height: MfSpace.xl),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Saving...' : 'Create Recurring'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.xxl),
            child: Text('Failed to load categories: $error'),
          ),
        ),
      ),
    );
  }
}
