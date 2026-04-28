import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// MoneyFlow AI - spacing, radii, motion.
abstract final class MfRadius {
  static const double sm = 12; 
  static const double md = 16; 
  static const double lg = 24;
  static const double xl = 32;
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
  static const Duration slow = Duration(milliseconds: 460);
  static const Curve curve = Curves.easeOutCubic;
}

/// Brand + semantic colors (use with [ColorScheme] in theme).
abstract final class MfPalette {
  static const Color canvas = Color(0xFFF9FAFB); // gray-50
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE5E7EB); // gray-200

  // Brand
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryDark = Color(0xFF4338CA); // indigo-700
  static const Color primaryLight = Color(0xFF818CF8); // indigo-400
  static const Color primaryGlow = Color(0x334F46E5);

  // Semantic
  static const Color incomeGreen = Color(0xFF10B981); // green-500
  static const Color expenseAmber = Color(0xFFF59E0B); // amber-500
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color insightBlue = Color(0xFF4F46E5);

  // Text
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textMuted = Color(0xFF6B7280); 
  static const Color textHint = Color(0xFF9CA3AF); // gray-400

  // Backwards-compatible aliases
  static const Color success = incomeGreen;
  static const Color error = expenseAmber; 
  static const Color warning = warningAmber;
  static const Color surface = canvas;
  static const Color primaryIndigo = primary;
  static const Color income = incomeGreen;
  static const Color expense = expenseAmber;
  static const Color expenseRed = expenseAmber;
  static const Color accentIndigo = primary;
  static const Color accentTeal = Color(0xFF10B981);
  static const Color accentSoftPurple = Color(0xFF8B5CF6);
  static const Color heroStart = primary;
  static const Color heroMid = Color(0xFF6366F1);
  static const Color heroEnd = Color(0xFF818CF8);

  // Premium / Fintech accents
  static const Color neonGreen = Color(0xFF3DFF8B);
  static const Color neonGreenSoft = Color(0xFF4ADE80);
  static const Color onNeonGreen = Color(0xFF06120E);

  // Gradient anchors
  static const Color canvasGradientTop = Color(0xFFFFFFFF);
  static const Color canvasGradientBottom = Color(0xFFF8F9FB);
}

/// Buddy-style category colors used by icon chips, progress, and charts.
abstract final class MfCategoryColors {
  static const Color dailyExpenses = Color(0xFF667EEA);
  static const Color household = Color(0xFF006B55);
  static const Color vehicle = Color(0xFF45B7D1);
  static const Color insurance = Color(0xFF96CEB4);
  static const Color financial = Color(0xFF6C5CE7);
  static const Color donations = Color(0xFFFF7675);
  static const Color business = Color(0xFF00B894);
  static const Color custom = Color(0xFFFDAA5A);
  static const Color food = Color(0xFF667EEA);
  static const Color transport = Color(0xFF0984E3);
  static const Color shopping = Color(0xFFAA2D32);
  static const Color entertainment = Color(0xFFA29BFE);
  static const Color health = Color(0xFF55EFC4);
  static const Color fuel = Color(0xFFFD79A8);

  static Color forSystemKey(String key) {
    switch (key) {
      case 'daily_expenses':
        return dailyExpenses;
      case 'household':
        return household;
      case 'vehicle':
        return vehicle;
      case 'insurance':
        return insurance;
      case 'financial':
        return financial;
      case 'donations':
        return donations;
      case 'business':
        return business;
      default:
        return custom;
    }
  }

  static const List<Color> chartPalette = [
    dailyExpenses,
    household,
    vehicle,
    insurance,
    financial,
    donations,
    business,
    custom,
    food,
    transport,
    shopping,
    entertainment,
    health,
  ];
}

abstract final class MfSurface {
  static const Color base = Color(0xFFF8F9FB);
  static const Color card = Colors.white;
  static const Color cardAlt = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color inputFill = Colors.white;
}

/// Buddy shadow system.
abstract final class MfShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)), 
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> hero = [
    BoxShadow(color: Color(0x40667EEA), blurRadius: 24, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x2E667EEA), blurRadius: 22, offset: Offset(0, 0)),
  ];
}

/// Indian Rupee symbol - use everywhere instead of hardcoded literals.
abstract final class MfCurrency {
  static const String symbol = '\u20B9';

  static String format(num value) =>
      '$symbol${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';

  static String formatCompact(num value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 10000000) {
      final crore = abs / 10000000;
      final digits = crore == crore.truncateToDouble() ? 0 : 1;
      return '$sign$symbol${crore.toStringAsFixed(digits)}Cr';
    }
    if (abs >= 100000) {
      final lakh = abs / 100000;
      final digits = lakh == lakh.truncateToDouble() ? 0 : 1;
      return '$sign$symbol${lakh.toStringAsFixed(digits)}L';
    }
    return format(value);
  }

  /// Indian grouping + ₹ (en_IN). Use for API/map numeric strings shown in UI.
  static String formatInr(dynamic raw) {
    final n = double.tryParse(raw?.toString() ?? '0') ?? 0;
    final digits = n == n.roundToDouble() ? 0 : 2;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: digits,
    ).format(n);
  }
}

const String kCurrencySymbol = MfCurrency.symbol;

const LinearGradient mfPremiumCanvasGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    MfPalette.canvasGradientTop,
    MfPalette.canvasGradientBottom,
  ],
);

const LinearGradient mfBrandGradient = LinearGradient(
  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient mfSuccessGradient = LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF34D399)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Glass card decoration - use for premium list and summary cards.
BoxDecoration glassCard({
  Color? color,
  double borderRadius = MfRadius.lg,
  Color? borderColor,
}) =>
    BoxDecoration(
      color: color ?? MfPalette.cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border:
          Border.all(color: borderColor ?? const Color(0x26FFFFFF), width: 1),
      boxShadow: [
        BoxShadow(
          color: MfPalette.accentSoftPurple.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        const BoxShadow(
          offset: Offset(0, 18),
          blurRadius: 48,
          color: Color(0x12000B60),
        ),
        const BoxShadow(
          offset: Offset(0, 6),
          blurRadius: 18,
          color: Color(0x100C152F),
        ),
      ],
    );

/// BUG-T08: theme-aware hero gradient anchors for net worth / balance surfaces.
({Color heroStart, Color heroEnd}) heroCardGradientEndpoints(
    BuildContext context) {
  return (heroStart: MfPalette.heroStart, heroEnd: MfPalette.heroEnd);
}

/// True glassmorphism shell for net worth / balance hero cards (blur + frosted gradient).
Widget mfHeroGlassShell({
  required BuildContext context,
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  final (:heroStart, :heroEnd) = heroCardGradientEndpoints(context);
  return ClipRRect(
    borderRadius: BorderRadius.circular(MfRadius.xl),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MfRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              heroStart.withValues(alpha: 0.55),
              heroEnd.withValues(alpha: 0.40),
            ],
          ),
        ),
        padding: padding,
        child: child,
      ),
    ),
  );
}

LinearGradient incomeGradient() => LinearGradient(
      colors: [
        MfPalette.incomeGreen.withValues(alpha: 0.96),
        MfPalette.incomeGreen.withValues(alpha: 0.62),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient expenseGradient(Color categoryColor) => LinearGradient(
      colors: [
        categoryColor.withValues(alpha: 0.94),
        categoryColor.withValues(alpha: 0.58),
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
    glassOpacity: 0.52,
  );

  static const dark = MoneyFlowThemeExtension(
    success: MfPalette.incomeGreen,
    onSuccess: Color(0xFF06120E),
    warning: MfPalette.warningAmber,
    glassOpacity: 0.52,
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
