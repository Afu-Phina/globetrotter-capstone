import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GlobeTrotter design system — "Seven Hills at Golden Hour", dark mode.
///
/// Same Yaoundé identity as before (forest green hills, marigold sunset,
/// papaya market energy), rebuilt as a dark theme: near-black backgrounds,
/// a brightened emerald accent for icons/text that stays legible against
/// them, and marigold/papaya doing the heavy lifting for pop -- rather
/// than switching to a generic navy+orange SaaS palette.
class AppColors {
  // Backgrounds.
  static const Color mist = Color(0xFF0A130F); // page background (was light, now near-black)
  static const Color surface = Color(0xFF142018); // card / elevated surface
  static const Color border = Color(0xFF2A3A30); // subtle seams on dark surfaces

  // The hills -- kept dark, used for hero gradients and banners.
  static const Color forestDeep = Color(0xFF07140F);
  static const Color forestMid = Color(0xFF23503F);

  // Brand accent green -- brightened from the light-theme version so it
  // stays legible as icon/text/border color against near-black surfaces.
  static const Color forest = Color(0xFF4FC790);

  // Golden hour.
  static const Color marigold = Color(0xFFF0A93D);
  static const Color marigoldLight = Color(0xFFF8D48A);

  // Market energy.
  static const Color papaya = Color(0xFFE86A50);

  // Text.
  static const Color ink = Color(0xFFF3F1EA); // primary text (was near-black, now cream)
  static const Color inkMuted = Color(0xFFA7BBAE); // secondary text
  static const Color cream = Color(0xFFFAF6EC); // text on the darkest hero surfaces

  static const Color error = Color(0xFFFF6E57);
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
  // Uses GoogleFonts.getFont(name, ...) rather than the generated
  // per-font convenience methods (e.g. bricolageGrotesqueTextTheme()),
  // since those vary by google_fonts package version and can throw
  // NoSuchMethodError. getFont() fetches by plain string name instead.
  static TextTheme get _textTheme {
    TextStyle display(double size, FontWeight weight, {double? letterSpacing, double? height}) {
      return GoogleFonts.getFont(
        'Bricolage Grotesque',
        fontSize: size,
        fontWeight: weight,
        color: AppColors.ink,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    TextStyle body(double size, FontWeight weight, Color color) {
      return GoogleFonts.getFont(
        'Manrope',
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
    }

    return TextTheme(
      headlineLarge: display(32, FontWeight.w700, letterSpacing: -0.5, height: 1.1),
      headlineMedium: display(24, FontWeight.w700, letterSpacing: -0.3),
      titleMedium: body(16, FontWeight.w700, AppColors.ink),
      bodyLarge: body(15, FontWeight.w500, AppColors.ink),
      bodyMedium: body(14, FontWeight.w500, AppColors.inkMuted),
      labelLarge: body(14, FontWeight.w700, AppColors.forestDeep),
    );
  }

  static ThemeData get theme {
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
        brightness: Brightness.dark,
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
          textStyle: GoogleFonts.getFont('Manrope', fontSize: 16, fontWeight: FontWeight.w700),
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
          textStyle: GoogleFonts.getFont('Manrope', fontSize: 16, fontWeight: FontWeight.w700),
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
        hintStyle: GoogleFonts.getFont('Manrope', color: AppColors.inkMuted),
        labelStyle: GoogleFonts.getFont('Manrope', color: AppColors.inkMuted),
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
        labelStyle: GoogleFonts.getFont('Manrope', fontSize: 13, color: AppColors.inkMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.marigold.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.getFont('Manrope', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forest),
        ),
      ),
    );
  }
}
