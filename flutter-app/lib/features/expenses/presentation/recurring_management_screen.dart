import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design_system/mf_ui_system.dart';
import '../../../core/offline/db/ledger_database.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../application/expense_providers.dart';

class RecurringManagementScreen extends ConsumerWidget {
  const RecurringManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider);

    return Scaffold(
      backgroundColor: MfUI.backgroundGray,
      appBar: AppBar(
        title: Text('Recurring Bills', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: MfUI.surfaceWhite,
        elevation: 0,
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MfUI.space16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: MfUI.space12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecurringTile(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurring(context),
        backgroundColor: MfUI.primaryIndigo,
        label: const Text('Add Recurring', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.repeat_rounded, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text('No recurring bills set up', style: GoogleFonts.inter(color: MfUI.textSecondary)),
        ],
      ),
    );
  }

  void _showAddRecurring(BuildContext context) {
    MfModal.show(
      context: context,
      title: 'New Recurring Bill',
      child: const _AddRecurringForm(),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    final nextDate = DateTime.tryParse(item['nextDate']?.toString() ?? '') ?? DateTime.now();
    final isActive = item['active'] == true;
    final category = item['category'] as Map?;
    final categoryName = category?['name']?.toString() ?? 'Other';

    return MfCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MfUI.primaryIndigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.repeat_rounded, color: MfUI.primaryIndigo, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'Untitled',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '$categoryName • ${item['frequency']}',
                  style: GoogleFonts.inter(fontSize: 12, color: MfUI.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MfCurrency.formatInr(amount),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: MfUI.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Next: ${DateFormat('MMM dd').format(nextDate)}',
                style: GoogleFonts.inter(fontSize: 11, color: MfUI.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Switch(
            value: isActive,
            activeThumbColor: MfUI.primaryIndigo,
            onChanged: (v) {
              final payload = Map<String, dynamic>.from(item);
              payload['active'] = v;
              ref.read(ledgerDatabaseProvider).upsertRecurringFromServer(
                payload,
                status: LedgerSyncStatus.pendingPush,
              );
              // In real apps, you'd enqueue an outbox for partial update if backend supports it.
              // For simplicity, we assume full upsert or wait for sync.
            },
          ),
        ],
      ),
    );
  }
}

class _AddRecurringForm extends ConsumerStatefulWidget {
  const _AddRecurringForm();

  @override
  ConsumerState<_AddRecurringForm> createState() => _AddRecurringFormState();
}

class _AddRecurringFormState extends ConsumerState<_AddRecurringForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';
  String? _categoryId;
  DateTime _nextDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        MfTextField(label: 'Title', controller: _titleController, hint: 'e.g. Rent, Netflix'),
        const SizedBox(height: 16),
        MfTextField(label: 'Amount', controller: _amountController, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Frequency', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: MfUI.textSecondary)),
                   const SizedBox(height: 8),
                   DropdownButtonFormField<String>(
                     initialValue: _frequency,
                     decoration: _inputDecor(),
                     items: ['daily', 'weekly', 'monthly', 'yearly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                     onChanged: (v) => setState(() => _frequency = v!),
                   ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('First Due', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: MfUI.textSecondary)),
                   const SizedBox(height: 8),
                   InkWell(
                     onTap: () async {
                       final d = await showDatePicker(context: context, initialDate: _nextDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                       if (d != null) setState(() => _nextDate = d);
                     },
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: _boxDecor(),
                       child: Row(
                         children: [
                           Text(DateFormat('MMM dd, yyyy').format(_nextDate)),
                           const Spacer(),
                           const Icon(Icons.calendar_today, size: 16, color: MfUI.slateGray),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        categoriesAsync.when(
          data: (cats) {
            final expenseCats = cats.where((c) => (c['type'] == null || c['type'] == 'expense')).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: MfUI.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: _inputDecor(),
                  items: expenseCats.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['name']?.toString() ?? ''))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Failed to load categories'),
        ),
        const SizedBox(height: 32),
        MfPrimaryButton(
          label: 'Create Recurring Bill',
          onPressed: _save,
        ),
      ],
    );
  }

  InputDecoration _inputDecor() {
    return InputDecoration(
      filled: true,
      fillColor: MfUI.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(MfUI.radiusButton), borderSide: BorderSide(color: MfUI.slateGray.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MfUI.radiusButton), borderSide: BorderSide(color: MfUI.slateGray.withValues(alpha: 0.3))),
    );
  }

  BoxDecoration _boxDecor() {
    return BoxDecoration(
      color: MfUI.surfaceWhite,
      borderRadius: BorderRadius.circular(MfUI.radiusButton),
      border: Border.all(color: MfUI.slateGray.withValues(alpha: 0.3)),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty || _categoryId == null) return;
    
    final db = ref.read(ledgerDatabaseProvider);
    final id = const Uuid().v4();
    final payload = {
      'id': id,
      'title': _titleController.text,
      'amount': _amountController.text,
      'frequency': _frequency,
      'categoryId': _categoryId,
      'nextDate': _nextDate.toIso8601String(),
      'active': true,
      'mode': 'auto_create',
    };
    
    await db.insertPendingRecurring(id: id, payload: payload);
    
    // Enqueue outbox
    await db.enqueueOutbox(
      opCode: 'recurring.create',
      entityId: id,
      payload: {
        ...payload,
        'nextDateIso': _nextDate.toIso8601String(),
      },
      idempotencyKey: const Uuid().v4(),
    );
    
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recurring bill scheduled')));
  }
}
