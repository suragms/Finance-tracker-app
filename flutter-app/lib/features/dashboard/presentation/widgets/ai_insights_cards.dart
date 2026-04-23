import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/design_system/mf_ui_system.dart';
import '../../application/dashboard_providers.dart';


class AiInsightsCards extends ConsumerWidget {
  const AiInsightsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsSnapshotProvider);

    return insightsAsync.when(
      data: (data) => _buildInsightsList(data['alerts'] as List<dynamic>? ?? []),
      loading: () => const _InsightsLoadingSkeleton(),
      error: (error, _) => const SizedBox(), // Hide on error
    );
  }

  Widget _buildInsightsList(List<dynamic> alerts) {
    if (alerts.isEmpty) {
      return const SizedBox(); // No insights
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHTS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final alert = alerts[index] as Map;
              return _InsightCard(
                title: alert['title']?.toString() ?? '',
                message: alert['message']?.toString() ?? '',
                type: alert['type']?.toString() ?? 'info',
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final String type;

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData icon;

    switch (type) {
      case 'warning':
        accentColor = MfUI.warningAmber;
        icon = Icons.warning_amber_rounded;
        break;
      case 'success':
        accentColor = MfUI.successGreen;
        icon = Icons.trending_down_rounded;
        break;
      case 'error':
        accentColor = MfUI.errorRed;
        icon = Icons.error_outline_rounded;
        break;
      default:
        accentColor = MfUI.primaryIndigo;
        icon = Icons.insights_rounded;
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MfUI.surfaceWhite.withValues(alpha: 0.03), // Assuming dark mode parent
        borderRadius: BorderRadius.circular(MfUI.radiusCard),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: MfUI.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsLoadingSkeleton extends StatelessWidget {
  const _InsightsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _skeletonCard(),
              const SizedBox(width: 16),
              _skeletonCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
