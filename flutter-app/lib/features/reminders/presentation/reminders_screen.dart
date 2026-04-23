import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/money_flow_tokens.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final List<Map<String, dynamic>> _reminders = [
    {
      'id': '1',
      'title': 'Monthly Rent',
      'amount': 25000.0,
      'dueDate': DateTime.now().add(const Duration(days: 2)),
      'category': 'Household',
      'priority': 'high',
    },
    {
      'id': '2',
      'title': 'Electricity Bill',
      'amount': 4200.0,
      'dueDate': DateTime.now().add(const Duration(days: 5)),
      'category': 'Utilities',
      'priority': 'medium',
    },
    {
      'id': '3',
      'title': 'Gym Membership',
      'amount': 1500.0,
      'dueDate': DateTime.now().subtract(const Duration(days: 1)),
      'category': 'Health',
      'priority': 'low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REMINDERS',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white24, letterSpacing: 1.5),
                  ),
                  const Icon(Icons.tune_rounded, color: Colors.white24, size: 20),
                ],
              ),
            ),

            // LIST: Reminder Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final item = _reminders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ReminderCard(
                      reminder: item,
                      onPaid: () {
                        setState(() => _reminders.removeAt(index));
                      },
                      onSnooze: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onPaid,
    required this.onSnooze,
  });

  final Map<String, dynamic> reminder;
  final VoidCallback onPaid;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final dueDate = reminder['dueDate'] as DateTime;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final accentColor = isOverdue ? const Color(0xFFEF4444) : const Color(0xFF6366F1);

    return Container(
      decoration: glassCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        isOverdue ? 'OVERDUE' : 'UPCOMING',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 9, color: accentColor, letterSpacing: 1),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(dueDate),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  reminder['title'].toString(),
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  MfCurrency.formatInr(reminder['amount'] as double),
                  style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),

          // ACTIONS: Responsive Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'SNOOZE',
                    icon: Icons.snooze_rounded,
                    onTap: onSnooze,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'MARK PAID',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                    onTap: onPaid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.color});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: (color ?? Colors.white).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.white54),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color ?? Colors.white54, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
