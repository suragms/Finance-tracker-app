import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/transaction_tile.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TOP: Premium Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Container(
                decoration: glassCard(borderRadius: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // GRID: Scrollable 3-column view
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white24))),
                data: (rows) {
                  final filtered = rows.where((row) {
                    if (_query.isEmpty) return true;
                    return (row['name']?.toString() ?? '').toLowerCase().contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No categories found', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.bold)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final name = c['name']?.toString() ?? 'Category';
                      final key = c['systemKey']?.toString() ?? c['slug']?.toString() ?? 'custom';
                      final color = MfCategoryColors.forSystemKey(key);
                      final icon = categoryIconFor(key);

                      return _CategoryItem(
                        name: name,
                        icon: icon,
                        color: color,
                        animationIndex: index,
                      );
                    },
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

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.animationIndex,
  });

  final String name;
  final IconData icon;
  final Color color;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (animationIndex * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - t)),
        child: Opacity(opacity: t, child: child),
      ),
      child: Container(
        decoration: glassCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
