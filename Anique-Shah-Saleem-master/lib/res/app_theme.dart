import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AI Salesman design system.
///
/// Warm paper canvas, near-black ink, vermilion accent. Three typefaces do
/// distinct jobs and never swap roles:
///
///   Bricolage Grotesque - headlines and anything numeric (prices, totals)
///   Instrument Sans     - interface text, labels, controls, body copy
///   JetBrains Mono      - ids, ports, statuses, system labels
class AppTheme {
  // ===============================================================
  // Palette
  // ===============================================================

  /// App canvas behind everything.
  static const Color canvas = Color(0xFFEDE9E2);

  /// Default screen surface (slightly lighter than the canvas).
  static const Color surface = Color(0xFFFBF8F3);

  /// Raised cards sitting on [surface].
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Recessed wells, chips, muted fills.
  static const Color surfaceSunken = Color(0xFFF1ECE4);

  /// Near-black used for ink, dark screens and primary buttons.
  static const Color ink = Color(0xFF16181C);

  /// Vermilion. The only saturated colour in the light theme - reserve it for
  /// the single most important action on screen.
  static const Color accent = Color(0xFFE4552F);
  static const Color accentPressed = Color(0xFFB93D1C);
  static const Color accentWash = Color(0xFFFDEDE7);
  static const Color accentWashBorder = Color(0xFFF6C9B9);

  // Text
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF5F646C);
  static const Color textMuted = Color(0xFF8A8579);
  static const Color textDisabled = Color(0xFFA29C90);

  // Lines
  static const Color borderStrong = Color(0xFFDCD6CB);
  static const Color borderMedium = Color(0xFFE2DBD0);
  static const Color borderSoft = Color(0xFFEDE7DE);

  // Status
  static const Color positive = Color(0xFF16786E);
  static const Color positiveOnDark = Color(0xFF6FD3C7);
  static const Color negative = accentPressed;

  // Dark-screen surfaces (splash, order placed, assistant, reports)
  static const Color darkBg = ink;
  static const Color darkSurface = Color(0xFF22262E);
  static const Color darkSurfaceAlt = Color(0xFF1C2029);
  static const Color darkBorder = Color(0xFF2A2E36);
  static const Color darkBorderStrong = Color(0xFF3A3F49);
  static const Color darkTextMuted = Color(0xFF767C86);
  static const Color darkTextSecondary = Color(0xFF9BA1AA);
  static const Color darkTextPrimary = Color(0xFFE8E6E1);
  static const Color darkTextBright = surface;

  // ---------------------------------------------------------------
  // Backwards-compatible aliases.
  // Older screens reference these names directly; they now resolve to the
  // new palette so nothing renders off-brand while screens are migrated.
  // ---------------------------------------------------------------
  static const Color brandPrimary = accent;
  static const Color brandSecondary = positive;
  static const Color accentColor = accent;
  static const Color accentSecondary = accentPressed;
  static const Color primaryPurple = ink;
  static const Color primaryBlue = ink;
  static const Color accentPink = accent;
  static const Color accentOrange = accent;
  static const Color textDark = textPrimary;
  static const Color textMedium = textSecondary;
  static const Color textLight = textMuted;
  static const Color background = canvas;
  static const Color surfaceLight = surfaceRaised;
  static const Color surfaceMedium = surfaceSunken;
  static const Color divider = borderSoft;
  static const Color white = Colors.white;
  static const Color black = ink;
  static const Color success = positive;
  static const Color error = accentPressed;
  static const Color warning = accent;
  static const Color info = ink;

  // ===============================================================
  // Radii & spacing
  // ===============================================================
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;
  static const double radiusPill = 999;

  static const double spaceXs = 6;
  static const double spaceSm = 10;
  static const double spaceMd = 16;
  static const double spaceLg = 22;
  static const double spaceXl = 32;

  // ===============================================================
  // Typography
  // ===============================================================

  /// Display / numeric face. Tight tracking, used for headlines, prices and
  /// any figure the eye should land on first.
  static TextStyle display(
    double size, {
    Color color = textPrimary,
    FontWeight weight = FontWeight.w700,
    double height = 1.02,
  }) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: -size * 0.03,
      );

  /// Interface face. Labels, body copy, buttons.
  static TextStyle ui(
    double size, {
    Color color = textPrimary,
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
  }) =>
      GoogleFonts.instrumentSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// System face. Ids, ports, statuses, eyebrow labels. Wide tracking and
  /// upper case are part of the look.
  static TextStyle mono(
    double size, {
    Color color = textMuted,
    FontWeight weight = FontWeight.w700,
    double tracking = 0.14,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: size * tracking,
      );

  // Convenience roles
  static TextStyle get headingLarge => display(44);
  static TextStyle get headingMedium => display(30);
  static TextStyle get headingSmall => display(22);
  static TextStyle get price => display(21);
  static TextStyle get bodyLarge => ui(17, color: textSecondary);
  static TextStyle get bodyMedium => ui(15, color: textSecondary);
  static TextStyle get label => ui(15, weight: FontWeight.w500);
  static TextStyle get buttonText =>
      ui(17, color: Colors.white, weight: FontWeight.w600, height: 1.0);
  static TextStyle get captionText => ui(13, color: textMuted);

  /// Small uppercase eyebrow above a section or field.
  static TextStyle get eyebrow => mono(12);

  // ===============================================================
  // Gradients (kept for screens that still reference them)
  // ===============================================================
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accent, accentPressed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = brandGradient;
  static const LinearGradient sunsetGradient = brandGradient;
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [ink, darkSurface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===============================================================
  // Shadows
  // ===============================================================
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.38),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  // ===============================================================
  // ThemeData
  // ===============================================================
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      primaryColor: accent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        onPrimary: Colors.white,
        secondary: ink,
        onSecondary: surface,
        surface: surface,
        onSurface: textPrimary,
        error: negative,
      ),
      textTheme: GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: display(26),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd + 2),
          ),
          textStyle: ui(17, weight: FontWeight.w600, height: 1.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: ink, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd + 2),
          ),
          textStyle: ui(17, weight: FontWeight.w500, height: 1.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: ui(15, weight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSoft),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintStyle: ui(17, color: textMuted),
        labelStyle: ui(15, color: textMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: borderStrong, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: negative, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceSunken,
        selectedColor: ink,
        side: BorderSide.none,
        labelStyle: ui(14, color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSoft, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: ui(15, color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: ink,
        unselectedItemColor: textMuted,
        selectedLabelStyle: ui(11, weight: FontWeight.w500),
        unselectedLabelStyle: ui(11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: accent,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: accent,
        primary: accent,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: accent,
      ),
      textTheme: GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextBright,
      ),
    );
  }
}
