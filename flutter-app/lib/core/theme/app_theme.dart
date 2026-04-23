import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _lightScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F46E5), // Indigo-600
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEEF2FF),
    onPrimaryContainer: Color(0xFF4338CA),
    secondary: Color(0xFF22C55E), // Green-500
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDCFCE7),
    onSecondaryContainer: Color(0xFF166534),
    tertiary: Color(0xFFF59E0B), // Amber-500 (Expense)
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Color(0xFFF9FAFB), // Gray-50
    onSurface: Color(0xFF111827), // Gray-900
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF3F4F6),
    surfaceContainer: Color(0xFFF3F4F6),
    surfaceContainerHigh: Colors.white, // Cards are white on Gray-50
    surfaceContainerHighest: Color(0xFFE5E7EB),
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFFE5E7EB),
    shadow: Colors.black,
    scrim: Color(0xCC000000),
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6366F1),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF22C55E),
    onSecondary: Colors.white,
    tertiary: Color(0xFFF59E0B),
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Color(0xFF0F172A),
    onSurface: Colors.white,
    surfaceContainerLow: Color(0xFF1E293B),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF334155),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF475569),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness brightness) {
  final base = ThemeData(brightness: brightness, colorScheme: cs).textTheme;
  final inter = GoogleFonts.interTextTheme(base);

  return inter.copyWith(
    displayLarge: GoogleFonts.inter(
      textStyle: inter.displayLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: cs.onSurface,
    ),
    displayMedium: GoogleFonts.inter(
      textStyle: inter.displayMedium,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: cs.onSurface,
    ),
    displaySmall: GoogleFonts.inter(
      textStyle: inter.displaySmall,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: cs.onSurface,
    ),
    headlineLarge: GoogleFonts.inter(
      textStyle: inter.headlineLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: cs.onSurface,
    ),
    headlineMedium: GoogleFonts.inter(
      textStyle: inter.headlineMedium,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: cs.onSurface,
    ),
    headlineSmall: GoogleFonts.inter(
      textStyle: inter.headlineSmall,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: cs.onSurface,
    ),
    titleLarge: GoogleFonts.inter(
      textStyle: inter.titleLarge,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    titleMedium: GoogleFonts.inter(
      textStyle: inter.titleMedium,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: cs.onSurface,
    ),
    titleSmall: GoogleFonts.inter(
      textStyle: inter.titleSmall,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      textStyle: inter.bodyLarge,
      color: cs.onSurface,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      textStyle: inter.bodyMedium,
      color: cs.onSurface,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      textStyle: inter.bodySmall,
      color: cs.onSurface.withValues(alpha: 0.6),
      height: 1.4,
    ),
  );
}

InputDecorationTheme _inputTheme(ColorScheme cs) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(MfRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.56),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    disabledBorder: border(Colors.transparent),
    focusedBorder: border(cs.primary.withValues(alpha: 0.22), width: 2),
    errorBorder: border(cs.error.withValues(alpha: 0.4)),
    focusedErrorBorder: border(cs.error.withValues(alpha: 0.65), width: 2),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: MfSpace.lg,
      vertical: MfSpace.md + 2,
    ),
    hintStyle: GoogleFonts.inter(
      color: cs.onSurface.withValues(alpha: 0.44),
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.inter(
      color: cs.onSurface.withValues(alpha: 0.58),
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.inter(
      color: cs.primary,
      fontWeight: FontWeight.w600,
    ),
  );
}

ThemeData _buildTheme(ColorScheme colorScheme, MoneyFlowThemeExtension mf) {
  final textTheme = _textTheme(colorScheme, colorScheme.brightness);
  final isDark = colorScheme.brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [mf],
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.md), // rounded-2xl = 16px
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: _inputTheme(colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.12),
      disabledColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.md,
        vertical: MfSpace.sm,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.22),
      ),
      brightness: colorScheme.brightness,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: MfSpace.md + 4,
          horizontal: MfSpace.xl,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: MfSpace.md + 4,
          horizontal: MfSpace.xl,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
        foregroundColor: colorScheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: colorScheme.primary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 68,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.22 : 0.1,
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.1,
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.52),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.48),
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.inter(
        color: colorScheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.16),
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHigh,
      circularTrackColor: colorScheme.surfaceContainerHigh,
    ),
  );
}

ThemeData buildAppTheme() => _premiumLightTheme();

ThemeData buildAppDarkTheme() => _premiumDarkTheme();

ThemeData _premiumLightTheme() => _buildTheme(
      _lightScheme(),
      MoneyFlowThemeExtension.light,
    );

ThemeData _premiumDarkTheme() => _buildTheme(
      _darkScheme(),
      MoneyFlowThemeExtension.dark,
    );

List<BoxShadow> ledgerAmbientFabShadows(ColorScheme cs) => [
      BoxShadow(
        offset: const Offset(0, 14),
        blurRadius: 36,
        color: cs.shadow.withValues(alpha: 0.14),
      ),
      BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 12,
        color: cs.shadow.withValues(alpha: 0.08),
      ),
    ];
