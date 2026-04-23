import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/dio_errors.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (kNoApiMode) {
    final now = DateTime.now();
    return <Map<String, dynamic>>[
      {
        'id': 'demo-1',
        'category': 'ai',
        'title': 'AI budget tip',
        'body': 'You can save ₹2,100 by lowering dining expenses this week.',
        'date': now.subtract(const Duration(minutes: 45)).toIso8601String(),
        'createdAt':
            now.subtract(const Duration(minutes: 45)).toIso8601String(),
        'readAt': null,
      },
      {
        'id': 'demo-2',
        'category': 'recurring',
        'title': 'Rent due today',
        'body': 'Monthly rent payment is due.',
        'date': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'createdAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'readAt': null,
      },
      {
        'id': 'demo-3',
        'category': 'system',
        'title': 'Sync complete',
        'body': 'Your transactions are up to date.',
        'date':
            now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
        'createdAt':
            now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
        'readAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }
  final dio = ref.read(dioProvider);
  final res = await dio.get<dynamic>('/notifications');
  return List<Map<String, dynamic>>.from(res.data['data'] ?? const []);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context, ref),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(MfSpace.xxl),
          child: LedgerErrorState(
            title: 'Could not load notifications',
            message: error is DioException
                ? dioErrorMessage(error)
                : error.toString(),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                await ref.read(notificationsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  MfSpace.xxl,
                  MfSpace.lg,
                  MfSpace.xxl,
                  MediaQuery.paddingOf(context).bottom + 88,
                ),
                children: const [
                  LedgerEmptyState(
                    title: 'No notifications yet',
                    subtitle: 'Alerts and reminders will appear here.',
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              ),
            );
          }

          final grouped = _groupByDate(rows);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                for (final section in grouped) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MfSpace.xxl,
                        MfSpace.md,
                        MfSpace.xxl,
                        MfSpace.sm,
                      ),
                      child: Text(
                        section.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                    sliver: SliverList.separated(
                      itemCount: section.rows.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: MfSpace.sm),
                      itemBuilder: (context, index) {
                        final row = section.rows[index];
                        return _NotificationTile(
                          row: row,
                          onTap: () => _openNotification(context, ref, row),
                        );
                      },
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 88),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    if (kNoApiMode) {
      ref.invalidate(notificationsProvider);
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>('/notifications/mark-all-read');
      ref.invalidate(notificationsProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dioErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> row,
  ) async {
    final id = row['id']?.toString() ?? '';
    if (!kNoApiMode && id.isNotEmpty) {
      try {
        final dio = ref.read(dioProvider);
        await dio.patch<void>('/notifications/$id/read');
        ref.invalidate(notificationsProvider);
      } catch (_) {}
    }

    final actionUrl = row['actionUrl']?.toString();
    if (actionUrl != null && actionUrl.isNotEmpty && context.mounted) {
      if (actionUrl.startsWith('/')) {
        Navigator.of(context).pushNamed(actionUrl);
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.row, required this.onTap});

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final category = row['category']?.toString() ?? 'system';
    final title = row['title']?.toString() ?? 'Notification';
    final body = row['body']?.toString() ?? '';
    final unread = row['readAt'] == null;
    final time = _timeAgo(_parseDate(row));
    final dotColor = _categoryDotColor(category);

    return InkWell(
      borderRadius: BorderRadius.circular(MfRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MfSpace.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(MfRadius.lg),
          border: Border(
            left: BorderSide(
              color: unread ? cs.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(MfRadius.md),
              ),
              child: Icon(_categoryIcon(category), size: 20, color: dotColor),
            ),
            const SizedBox(width: MfSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: MfSpace.xs),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSection {
  const _NotificationSection({required this.label, required this.rows});
  final String label;
  final List<Map<String, dynamic>> rows;
}

List<_NotificationSection> _groupByDate(List<Map<String, dynamic>> rows) {
  final today = <Map<String, dynamic>>[];
  final yesterday = <Map<String, dynamic>>[];
  final earlier = <Map<String, dynamic>>[];
  final now = DateTime.now();
  final dayNow = DateTime(now.year, now.month, now.day);
  final dayYesterday = dayNow.subtract(const Duration(days: 1));

  final sorted = [...rows]..sort((a, b) {
      final ad = _parseDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

  for (final row in sorted) {
    final dt = _parseDate(row);
    if (dt == null) {
      earlier.add(row);
      continue;
    }
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == dayNow) {
      today.add(row);
    } else if (d == dayYesterday) {
      yesterday.add(row);
    } else {
      earlier.add(row);
    }
  }

  final sections = <_NotificationSection>[];
  if (today.isNotEmpty) {
    sections.add(_NotificationSection(label: 'Today', rows: today));
  }
  if (yesterday.isNotEmpty) {
    sections.add(_NotificationSection(label: 'Yesterday', rows: yesterday));
  }
  if (earlier.isNotEmpty) {
    sections.add(_NotificationSection(label: 'Earlier', rows: earlier));
  }
  return sections;
}

DateTime? _parseDate(Map<String, dynamic> row) {
  final raw = row['date']?.toString() ?? row['createdAt']?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'recurring':
      return Icons.repeat_rounded;
    case 'emi':
      return Icons.credit_card_rounded;
    case 'ai':
      return Icons.auto_awesome_rounded;
    case 'system':
    default:
      return Icons.info_outline_rounded;
  }
}

Color _categoryDotColor(String category) {
  switch (category.toLowerCase()) {
    case 'recurring':
    case 'emi':
      return MfPalette.warningAmber;
    case 'ai':
      return const Color(0xFF8B5CF6);
    case 'system':
    default:
      return MfPalette.incomeGreen;
  }
}
