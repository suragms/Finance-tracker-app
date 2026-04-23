import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6366F1), // Indigo
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1F2937),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF10B981), // Green
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF064E3B),
    onSecondaryContainer: Color(0xFFA7F3D0),
    tertiary: Color(0xFF3B82F6), // Blue
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF1E3A8A),
    onTertiaryContainer: Color(0xFFDBEAFE),
    error: Color(0xFFEF4444), // Red
    onError: Colors.white,
    surface: Color(0xFF0B0F1A), // Background
    onSurface: Colors.white,
    surfaceContainerLowest: Color(0xFF0B0F1A),
    surfaceContainerLow: Color(0xFF111827), // Surface
    surfaceContainer: Color(0xFF111827),
    surfaceContainerHigh: Color(0xFF1F2937), // Card
    surfaceContainerHighest: Color(0xFF374151),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFF4B5563),
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    inverseSurface: Colors.white,
    onInverseSurface: Color(0xFF111827),
    inversePrimary: Color(0xFFA5B4FC),
    surfaceTint: Color(0xFF6366F1),
    surfaceDim: Color(0xFF0B0F1A),
    surfaceBright: Color(0xFF1F2937),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness brightness) {
  final base = ThemeData(brightness: brightness, colorScheme: cs).textTheme;
  final inter = GoogleFonts.interTextTheme(base);

  return inter.copyWith(
    displayLarge: GoogleFonts.manrope(
      textStyle: inter.displayLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.3,
      color: cs.onSurface,
    ),
    displayMedium: GoogleFonts.manrope(
      textStyle: inter.displayMedium,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      color: cs.onSurface,
    ),
    displaySmall: GoogleFonts.manrope(
      textStyle: inter.displaySmall,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.9,
      color: cs.onSurface,
    ),
    headlineLarge: GoogleFonts.manrope(
      textStyle: inter.headlineLarge,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: cs.onSurface,
    ),
    headlineMedium: GoogleFonts.manrope(
      textStyle: inter.headlineMedium,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: cs.onSurface,
    ),
    headlineSmall: GoogleFonts.manrope(
      textStyle: inter.headlineSmall,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: cs.onSurface,
    ),
    titleLarge: GoogleFonts.manrope(
      textStyle: inter.titleLarge,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
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
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.inter(
      textStyle: inter.bodyMedium,
      color: cs.onSurface,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.inter(
      textStyle: inter.bodySmall,
      color: const Color(0xFF9CA3AF), // Secondary Gray
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      textStyle: inter.labelLarge,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    labelMedium: GoogleFonts.inter(
      textStyle: inter.labelMedium,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF9CA3AF),
    ),
    labelSmall: GoogleFonts.inter(
      textStyle: inter.labelSmall,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF9CA3AF),
    ),
  );
}

InputDecorationTheme _inputTheme(ColorScheme cs) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
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
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh, // Card: #1F2937
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.lg),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

ThemeData _premiumDarkTheme() => _buildTheme(
      _darkScheme(),
      MoneyFlowThemeExtension.dark,
    );

ThemeData buildAppTheme() => _premiumDarkTheme();

ThemeData buildAppDarkTheme() => _premiumDarkTheme();

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
