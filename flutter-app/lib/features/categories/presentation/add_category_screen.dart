import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/data/categories_api.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF6366F1);
  IconData _selectedIcon = Icons.category_rounded;

  final List<IconData> _iconChoices = [
    Icons.shopping_bag_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.health_and_safety_rounded,
    Icons.movie_rounded,
    Icons.favorite_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.business_center_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.phone_android_rounded,
    Icons.sports_esports_rounded,
    Icons.celebration_rounded,
    Icons.child_friendly_rounded,
    Icons.handshake_rounded,
  ];

  final List<Color> _colorChoices = [
    const Color(0xFF6366F1),
    const Color(0xFF667EEA),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFFFFB347),
    const Color(0xFFF06292),
    const Color(0xFF4FC3F7),
    const Color(0xFF9575CD),
    const Color(0xFFD4E157),
    const Color(0xFF4DB6AC),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NEW CATEGORY',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white24, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // PREVIEW: Large Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, val, child) => Transform.scale(
                scale: 0.8 + (0.2 * val),
                child: child,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _selectedColor.withValues(alpha: 0.2), width: 2),
                  boxShadow: [
                    BoxShadow(color: _selectedColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: -10),
                  ],
                ),
                child: Icon(_selectedIcon, color: _selectedColor, size: 56),
              ),
            ),
            const SizedBox(height: 48),

            // FIELD: Name
            Container(
              decoration: glassCard(borderRadius: 20),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Category Name',
                  hintStyle: GoogleFonts.manrope(color: Colors.white10),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // FIELD: Color Selection
            _SectionHeader(label: 'SELECT COLOR'),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colorChoices.length,
                itemBuilder: (context, index) {
                  final color = _colorChoices[index];
                  final selected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15)] : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // FIELD: Icon Selection
            _SectionHeader(label: 'SELECT ICON'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: glassCard(borderRadius: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _iconChoices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final icon = _iconChoices[index];
                  final selected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? _selectedColor : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: selected ? Colors.white : Colors.white24, size: 24),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a category name')));
              return;
            }
            try {
              await ref.read(categoriesApiProvider).createCategory(name);
              ref.invalidate(categoriesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created successfully')));
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ),
          child: Text('CREATE CATEGORY', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white24, letterSpacing: 1),
      ),
    );
  }
}
