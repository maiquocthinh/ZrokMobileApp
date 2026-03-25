import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- Colors (Zrok Obsidian) ---
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color background = Color(0xFF111125);
  static const Color surfaceContainerLowest = Color(0xFF0C0C1F);
  static const Color surfaceContainerLow = Color(0xFF1A1A2E);
  static const Color surfaceContainer = Color(0xFF1E1E32);
  static const Color surfaceContainerHigh = Color(0xFF28283D);
  static const Color surfaceContainerHighest = Color(0xFF333348);
  static const Color surfaceBright = Color(0xFF37374D);
  static const Color onSurface = Color(0xFFE2E0FC);
  static const Color onSurfaceVariant = Color(0xFFC7C4D8);
  static const Color outline = Color(0xFF918FA1);
  static const Color outlineVariant = Color(0xFF464555);
  static const Color teal = Color(0xFF03DAC6);
  static const Color tealBright = Color(0xFF46F5E0);
  static const Color error = Color(0xFFCF6679);
  static const Color errorLight = Color(0xFFFFB4AB);
  static const Color amber = Color(0xFFFFB74D);
  static const Color textSecondary = Color(0xFF787896);

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4C0FF), Color(0xFF8781FF)],
  );

  static ThemeData get darkTheme {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.bold, color: onSurface),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.bold, color: onSurface),
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.bold, color: onSurface),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w600, color: onSurface),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w600, color: onSurface),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w500, color: onSurface),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: onSurface),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSurface),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outlineVariant.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFC4C0FF),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? teal : outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? teal.withValues(alpha: 0.3) : surfaceContainerHigh),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? const Color(0xFFC4C0FF) : textSecondary,
          size: 22,
        )),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: outlineVariant.withValues(alpha: 0.15)),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceContainerHighest,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // --- Monospace style for terminal/code ---
  static TextStyle get mono => GoogleFonts.jetBrainsMono(fontSize: 13, color: onSurface);
  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(fontSize: 11, color: onSurfaceVariant);
  static TextStyle get monoTeal => GoogleFonts.jetBrainsMono(fontSize: 13, color: teal);
}
