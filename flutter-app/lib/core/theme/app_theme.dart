import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _lightScheme() {
  const p = MfPalette.primary;
  return ColorScheme(
    brightness: Brightness.light,
    primary: p,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE0E7FF),
    onPrimaryContainer: const Color(0xFF312E81),
    secondary: const Color(0xFF6366F1),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFEEF2FF),
    onSecondaryContainer: const Color(0xFF3730A3),
    tertiary: MfPalette.warningAmber,
    onTertiary: const Color(0xFF422006),
    tertiaryContainer: const Color(0xFFFFE7C2),
    onTertiaryContainer: const Color(0xFF713F12),
    error: MfPalette.expenseRed,
    onError: Colors.white,
    surface: MfPalette.lightBg,
    onSurface: const Color(0xFF0F172A),
    surfaceContainerLowest: MfPalette.lightBgElevated,
    surfaceContainerLow: const Color(0xFFF1F5F9),
    surfaceContainer: const Color(0xFFE2E8F0),
    surfaceContainerHigh: const Color(0xFFCBD5E1),
    surfaceContainerHighest: const Color(0xFF94A3B8),
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    shadow: const Color(0xFF0F172A),
    scrim: Colors.black54,
    inverseSurface: MfPalette.darkBg,
    onInverseSurface: const Color(0xFFF8FAFC),
    inversePrimary: const Color(0xFFC7D2FE),
    surfaceTint: p,
    surfaceDim: const Color(0xFFCBD5E1),
    surfaceBright: Colors.white,
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8),
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFA259FF),
    onSecondary: Color(0xFF1E1B4B),
    secondaryContainer: Color(0xFF2D1B69),
    onSecondaryContainer: Color(0xFFE9D5FF),
    tertiary: Color(0xFFFB923C),
    onTertiary: Color(0xFF431407),
    tertiaryContainer: Color(0xFF6B2D0B),
    onTertiaryContainer: Color(0xFFFFDBCC),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    surface: Color(0xFF0D1120),
    onSurface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFF0A0E1A),
    surfaceContainerLow: Color(0x14FFFFFF),
    surfaceContainer: Color(0x1FFFFFFF),
    surfaceContainerHigh: Color(0x29FFFFFF),
    surfaceContainerHighest: Color(0xFF334155),
    outline: Color(0x26FFFFFF),
    outlineVariant: Color(0x14FFFFFF),
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    inverseSurface: Color(0xFFF8FAFC),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF5B4CEC),
    surfaceTint: Color(0xFF5B4CEC),
    surfaceDim: Color(0xFF0A0E1A),
    surfaceBright: Color(0xFF1E293B),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness b) {
  final base = ThemeData(brightness: b, colorScheme: cs).textTheme;
  final dmSans = GoogleFonts.dmSansTextTheme(base);

  return dmSans.copyWith(
    displayLarge: GoogleFonts.dmSans(textStyle: dmSans.displayLarge, fontWeight: FontWeight.w700, color: cs.onSurface),
    displayMedium: GoogleFonts.dmSans(textStyle: dmSans.displayMedium, fontWeight: FontWeight.w700, color: cs.onSurface),
    displaySmall: GoogleFonts.dmSans(textStyle: dmSans.displaySmall, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineLarge: GoogleFonts.dmSans(textStyle: dmSans.headlineLarge, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineMedium: GoogleFonts.dmSans(textStyle: dmSans.headlineMedium, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineSmall: GoogleFonts.dmSans(textStyle: dmSans.headlineSmall, fontWeight: FontWeight.w600, color: cs.onSurface),
    titleLarge: GoogleFonts.dmSans(textStyle: dmSans.titleLarge, fontWeight: FontWeight.w600, color: cs.onSurface),
    titleMedium: GoogleFonts.dmSans(textStyle: dmSans.titleMedium, fontWeight: FontWeight.w600, color: cs.onSurface),
    titleSmall: GoogleFonts.dmSans(textStyle: dmSans.titleSmall, fontWeight: FontWeight.w500, color: cs.onSurface),
    bodyLarge: GoogleFonts.dmSans(textStyle: dmSans.bodyLarge, color: cs.onSurface),
    bodyMedium: GoogleFonts.dmSans(textStyle: dmSans.bodyMedium, color: cs.onSurface),
    bodySmall: GoogleFonts.dmSans(textStyle: dmSans.bodySmall, fontSize: 12, color: cs.onSurface.withValues(alpha: 0.65)),
    labelLarge: GoogleFonts.dmSans(textStyle: dmSans.labelLarge, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.dmMono(textStyle: dmSans.labelMedium, fontSize: 13, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.dmMono(textStyle: dmSans.labelSmall, fontSize: 11, fontWeight: FontWeight.w400),
  );
}

InputDecorationTheme _inputTheme(ColorScheme cs) {
  return InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.85), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error.withValues(alpha: 0.6)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: MfSpace.md + 2),
    labelStyle: GoogleFonts.dmSans(color: cs.onSurface.withValues(alpha: 0.65)),
    floatingLabelStyle: GoogleFonts.dmSans(color: cs.primary, fontWeight: FontWeight.w600),
  );
}

ThemeData _buildTheme(ColorScheme colorScheme, MoneyFlowThemeExtension mf) {
  final textTheme = _textTheme(colorScheme, colorScheme.brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [mf],
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: _inputTheme(colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      secondaryLabelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.md, vertical: MfSpace.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm + 4)),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      brightness: colorScheme.brightness,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: MfSpace.md + 2, horizontal: MfSpace.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: MfSpace.md + 2, horizontal: MfSpace.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 2,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.45),
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.fixed,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.dmSans(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
  );
}

ThemeData buildAppTheme() => _buildTheme(_lightScheme(), MoneyFlowThemeExtension.light);

ThemeData buildAppDarkTheme() {
  final cs = _darkScheme();
  final base = _buildTheme(cs, MoneyFlowThemeExtension.dark);
  return base.copyWith(
    scaffoldBackgroundColor: MfPalette.phoneBg,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: MfPalette.phoneBg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: MfPalette.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 60,
      backgroundColor: const Color(0xF00D1120),
      indicatorColor: const Color(0x335B4CEC),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
          size: 24,
        );
      }),
    ),
  );
}

List<BoxShadow> ledgerAmbientFabShadows(ColorScheme cs) => [
      BoxShadow(
        offset: const Offset(0, 10),
        blurRadius: 28,
        color: cs.shadow.withValues(alpha: 0.08),
      ),
    ];
