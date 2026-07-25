import 'package:flutter/material.dart';
// Removed google_fonts dependency to avoid missing package error.

/// GlobeTrotter design system — "Seven Hills at Golden Hour".
///
/// Yaoundé is nicknamed "la ville aux sept collines" (the city of seven
/// hills). Instead of a generic travel-app palette, this system is built
/// from that: deep forest green (the hills), marigold gold (sunset light
/// hitting them), and a warm papaya red (market energy, echoing the
/// national flag without being literal). The hill silhouette itself
/// becomes the app's one signature shape (see HillClipper).
class AppColors {
  // The hills, at different times of day.
  static const Color forest = Color(0xFF15352A); // primary dark surface
  static const Color forestDeep = Color(0xFF0B211A); // gradient depth
  static const Color forestMid = Color(0xFF285443); // mid-tone accents

  // Golden hour.
  static const Color marigold = Color(0xFFF0A93D); // primary action color
  static const Color marigoldLight = Color(0xFFF8D48A);

  // Market energy.
  static const Color papaya = Color(0xFFE4573F); // secondary accent / alerts

  // Content surfaces — a sage-tinted white, not the generic warm cream.
  static const Color mist = Color(0xFFF5F8F2);
  static const Color surface = Color(0xFFFFFFFF);

  // Text.
  static const Color ink = Color(0xFF16241D);
  static const Color inkMuted = Color(0xFF5B6B62);
  static const Color cream = Color(0xFFFAF6EC); // text/icons on dark surfaces

  static const Color error = Color(0xFFC1432B);
  static const Color border = Color(0xFFE1E8DE);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double card = 20;
  static const double button = 14;
  static const double input = 14;
}

class AppTheme {
  static TextTheme get _textTheme {
    final display = GoogleFonts.bricolageGrotesqueTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    return TextTheme(
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 15, color: AppColors.ink),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, color: AppColors.inkMuted),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.cream,
      ),
    );
  }

  static ThemeData get light {
    final textTheme = _textTheme;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.mist,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.marigold,
        tertiary: AppColors.papaya,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mist,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.marigold,
          foregroundColor: AppColors.forestDeep,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.forest, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.marigold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.manrope(color: AppColors.inkMuted),
        labelStyle: GoogleFonts.manrope(color: AppColors.inkMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.marigold.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forest),
        ),
      ),
    );
  }
  
  static get GoogleFonts => null;
}
