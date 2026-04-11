import 'package:flutter/material.dart';

/// MoneyFlow AI — spacing, radii, motion (Stripe / Linear–inspired rhythm).
abstract final class MfRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}

abstract final class MfSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class MfMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
}

/// Brand + semantic colors (use with [ColorScheme] in theme).
abstract final class MfPalette {
  // Canvas
  static const Color canvas = Color(0xFF0A0E1A);
  static const Color phoneBg = Color(0xFF0D1120);
  static const Color cardBg = Color(0x0AFFFFFF);
  static const Color cardBorder = Color(0x0FFFFFFF);

  // Brand
  static const Color primary = Color(0xFF5B4CEC);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryGlow = Color(0xFFA259FF);

  // Semantic
  static const Color incomeGreen = Color(0xFF4ADE80);
  static const Color expenseRed = Color(0xFFF87171);
  static const Color warningAmber = Color(0xFFFB923C);

  // Hero card gradient stops
  static const Color heroStart = Color(0xFF1A2460);
  static const Color heroMid = Color(0xFF0F1A50);
  static const Color heroEnd = Color(0xFF121F6E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0x73FFFFFF);
  static const Color textHint = Color(0x40FFFFFF);

  // Legacy aliases (keep for non-redesigned screens)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFF64748B);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBgElevated = Color(0xFF1E293B);
  static const Color darkMuted = Color(0xFF94A3B8);

  /// Backwards-compatible names used by older widgets / light theme.
  static const Color success = incomeGreen;
  static const Color error = expenseRed;
  static const Color warning = warningAmber;
}

/// Indian Rupee symbol — use everywhere instead of hardcoded literals.
abstract final class MfCurrency {
  static const String symbol = '₹';

  static String format(num value) =>
      '$symbol${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';

  static String formatCompact(num value) {
    if (value >= 100000) return '$symbol${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    return format(value);
  }
}

const String kCurrencySymbol = MfCurrency.symbol;

/// Glass card decoration — use for ALL card widgets.
BoxDecoration glassCard({
  Color? color,
  double borderRadius = MfRadius.lg,
  Color? borderColor,
}) =>
    BoxDecoration(
      color: color ?? MfPalette.cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? MfPalette.cardBorder,
        width: 1,
      ),
    );

/// Hero gradient — for balance/summary cards.
BoxDecoration heroCardDecoration() => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [MfPalette.heroStart, MfPalette.heroMid, MfPalette.heroEnd],
        stops: [0.0, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.circular(MfRadius.xl),
      border: Border.all(
        color: const Color(0x2D6F82FF),
        width: 1,
      ),
    );

LinearGradient incomeGradient() => LinearGradient(
      colors: [
        MfPalette.incomeGreen.withValues(alpha: 0.85),
        MfPalette.incomeGreen.withValues(alpha: 0.50),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient expenseGradient(Color categoryColor) => LinearGradient(
      colors: [
        categoryColor.withValues(alpha: 0.85),
        categoryColor.withValues(alpha: 0.50),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

/// Optional theme extension for widgets that need explicit semantic colors.
@immutable
class MoneyFlowThemeExtension extends ThemeExtension<MoneyFlowThemeExtension> {
  const MoneyFlowThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.glassOpacity,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final double glassOpacity;

  static const light = MoneyFlowThemeExtension(
    success: MfPalette.incomeGreen,
    onSuccess: Colors.white,
    warning: MfPalette.warningAmber,
    glassOpacity: 0.72,
  );

  static const dark = MoneyFlowThemeExtension(
    success: MfPalette.incomeGreen,
    onSuccess: Color(0xFF064E3B),
    warning: MfPalette.warningAmber,
    glassOpacity: 0.55,
  );

  @override
  MoneyFlowThemeExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    double? glassOpacity,
  }) {
    return MoneyFlowThemeExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      glassOpacity: glassOpacity ?? this.glassOpacity,
    );
  }

  @override
  MoneyFlowThemeExtension lerp(
    ThemeExtension<MoneyFlowThemeExtension>? other,
    double t,
  ) {
    if (other is! MoneyFlowThemeExtension) return this;
    return MoneyFlowThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      glassOpacity: glassOpacity + (other.glassOpacity - glassOpacity) * t,
    );
  }
}

extension MoneyFlowThemeX on BuildContext {
  MoneyFlowThemeExtension get mf =>
      Theme.of(this).extension<MoneyFlowThemeExtension>() ??
      MoneyFlowThemeExtension.light;
}
