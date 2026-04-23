import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MoneyFlow AI - New Product Design System (Light Mode prioritized per spec)
/// Based on 8pt Grid System and Modern B2B SaaS aesthetics.

abstract final class MfUI {
  // Colors (Modern Indigo Palette)
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoDark = Color(0xFF4338CA);
  static const Color slateGray = Color(0xFF64748B);
  static const Color backgroundGray = Color(0xFFF9FAFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Semantic
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Spacing (8pt System)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Radii
  static const double radiusButton = 12.0; // rounded-xl
  static const double radiusCard = 16.0;   // rounded-2xl

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
}

/// Primary CTA Button
class MfPrimaryButton extends StatelessWidget {
  const MfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final active = isEnabled && !isLoading;

    return GestureDetector(
      onTap: active ? onPressed : null,
      child: Opacity(
        opacity: active ? 1.0 : 0.6,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Base Card Component
class MfCard extends StatelessWidget {
  const MfCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? const Color(0xFF1F2937);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Text Input Field
class MfTextField extends StatelessWidget {
  const MfTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.errorText,
    this.prefixIcon,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? errorText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MfUI.textSecondary,
          ),
        ),
        const SizedBox(height: MfUI.space8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          style: GoogleFonts.inter(fontSize: 16, color: MfUI.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: MfUI.slateGray.withValues(alpha: 0.5)),
            filled: true,
            fillColor: MfUI.surfaceWhite,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: MfUI.slateGray) : null,
            contentPadding: const EdgeInsets.all(MfUI.space16),
            border: _border(MfUI.slateGray.withValues(alpha: 0.3)),
            enabledBorder: _border(MfUI.slateGray.withValues(alpha: 0.3)),
            focusedBorder: _border(MfUI.primaryIndigo, width: 2),
            errorBorder: _border(MfUI.errorRed),
            focusedErrorBorder: _border(MfUI.errorRed, width: 2),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfUI.radiusButton),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Standard Modal / Bottom Sheet Helper
class MfModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(MfUI.space16),
        decoration: BoxDecoration(
          color: MfUI.surfaceWhite,
          borderRadius: BorderRadius.circular(MfUI.radiusCard),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: MfUI.space24,
            right: MfUI.space24,
            top: MfUI.space24,
            bottom: MfUI.space24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MfUI.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: MfUI.slateGray),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: MfUI.space24),
              child,
              if (actions != null) ...[
                const SizedBox(height: MfUI.space32),
                ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: MfUI.space8),
                  child: a,
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
