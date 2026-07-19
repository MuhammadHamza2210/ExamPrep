import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color primarySoft = Color(0xFFEDEBFF);

  static const Color accent = Color(0xFF22C55E); // "high priority" emerald

  static const Color background = Color(0xFFF5F6FB);
  static const Color backgroundDark = Color(0xFF0E0E15);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF191924);

  static const Color textPrimary = Color(0xFF16161F);
  // Mid-gray chosen to stay legible on BOTH light and dark backgrounds, since
  // many widgets use this single constant regardless of theme brightness.
  static const Color textSecondary = Color(0xFF78788A);
  static const Color textPrimaryDark = Color(0xFFF3F3F7);
  static const Color textSecondaryDark = Color(0xFFAEAEC0);

  static const Color danger = Color(0xFFEF4444);
  static const Color star = Color(0xFFFBBF24);

  /// Background gradient used behind glass surfaces.
  static const List<Color> heroGradient = [Color(0xFF6C63FF), Color(0xFF9C7BFF)];
}

class AppTheme {
  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
    );

    final baseText = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final body = GoogleFonts.interTextTheme(baseText);
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    final textTheme = body.copyWith(
      displaySmall: GoogleFonts.poppins(textStyle: body.displaySmall, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.poppins(textStyle: body.headlineMedium, fontWeight: FontWeight.w700, color: textColor),
      headlineSmall: GoogleFonts.poppins(textStyle: body.headlineSmall, fontWeight: FontWeight.w700, color: textColor),
      titleLarge: GoogleFonts.poppins(textStyle: body.titleLarge, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.poppins(textStyle: body.titleMedium, fontWeight: FontWeight.w600, color: textColor),
    ).apply(bodyColor: textColor, displayColor: textColor);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6E6EF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6E6EF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECECF2),
        thickness: 1,
      ),
    );
  }
}
