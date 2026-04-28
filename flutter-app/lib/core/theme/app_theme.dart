import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _lightScheme() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: MfPalette.primary, 
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEEF2FF),
    onPrimaryContainer: MfPalette.primaryDark,
    secondary: MfPalette.incomeGreen, 
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE6FFFA),
    onSecondaryContainer: Color(0xFF065F46),
    tertiary: MfPalette.expenseAmber, 
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: Color(0xFF92400E),
    error: MfPalette.expenseAmber, 
    onError: Colors.white,
    surface: MfPalette.canvas, 
    onSurface: MfPalette.textPrimary, 
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF3F4F6),
    surfaceContainer: Color(0xFFE5E7EB),
    surfaceContainerHigh: Colors.white, 
    surfaceContainerHighest: Color(0xFFD1D5DB),
    outline: MfPalette.textHint,
    outlineVariant: MfPalette.cardBorder,
    shadow: Colors.black,
    scrim: Color(0xCC000000),
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8194EB),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3953BD),
    onPrimaryContainer: Color(0xFFDDE1FF),
    secondary: Color(0xFF4BDDB7),
    onSecondary: Colors.black,
    tertiary: Color(0xFFFDBA74),
    onTertiary: Colors.black,
    error: Color(0xFFFDBA74),
    onError: Color(0xFF431407),
    surface: Color(0xFF111827),
    onSurface: Colors.white,
    surfaceContainerLow: Color(0xFF1F2937),
    surfaceContainer: Color(0xFF1F2937),
    surfaceContainerHigh: Color(0xFF374151),
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFF4B5563),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness brightness) {
  final base = ThemeData(brightness: brightness, colorScheme: cs).textTheme;
  final inter = GoogleFonts.interTextTheme(base);

  return inter.copyWith(
    displayLarge: GoogleFonts.inter(
      textStyle: inter.displayLarge,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    ),
    displayMedium: GoogleFonts.inter(
      textStyle: inter.displayMedium,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    ),
    displaySmall: GoogleFonts.inter(
      textStyle: inter.displaySmall,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    ),
    headlineLarge: GoogleFonts.inter(
      textStyle: inter.headlineLarge,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: cs.onSurface,
    ),
    headlineMedium: GoogleFonts.inter(
      textStyle: inter.headlineMedium,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: cs.onSurface,
    ),
    headlineSmall: GoogleFonts.inter(
      textStyle: inter.headlineSmall,
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: cs.onSurface,
    ),
    titleLarge: GoogleFonts.inter(
      textStyle: inter.titleLarge,
      fontWeight: FontWeight.w600,
      fontSize: 20,
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
      fontSize: 14,
      color: cs.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      textStyle: inter.bodyLarge,
      fontSize: 16,
      color: cs.onSurface,
    ),
    bodyMedium: GoogleFonts.inter(
      textStyle: inter.bodyMedium,
      fontSize: 14,
      color: cs.onSurface,
    ),
    bodySmall: GoogleFonts.inter(
      textStyle: inter.bodySmall,
      fontSize: 12,
      color: cs.onSurface.withValues(alpha: 0.6),
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
    fillColor: Colors.white,
    border: border(Color(0xFFD1D5DB)), // gray-300
    enabledBorder: border(Color(0xFFD1D5DB)),
    disabledBorder: border(Color(0xFFE5E7EB)),
    focusedBorder: border(cs.primary, width: 2),
    errorBorder: border(cs.error.withValues(alpha: 0.4)),
    focusedErrorBorder: border(cs.error, width: 2),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    hintStyle: GoogleFonts.inter(
      color: Color(0xFF9CA3AF), // gray-400
      fontSize: 14,
    ),
    labelStyle: GoogleFonts.inter(
      color: Color(0xFF6B7280), // gray-500
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
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.md), // 16px per rounded-2xl
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
        minimumSize: const Size.fromHeight(48), // height-12
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        side: BorderSide(color: Color(0xFFD1D5DB)),
        foregroundColor: Color(0xFF111827),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: colorScheme.primary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
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
      height: 80,
      backgroundColor: colorScheme.surface,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.4),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.4),
          size: 26,
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
