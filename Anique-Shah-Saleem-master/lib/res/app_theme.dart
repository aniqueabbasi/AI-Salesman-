import 'package:flutter/material.dart';

class AppTheme {
  // Modern Fashion E-Commerce Color Palette
  static const Color brandPrimary = Color(0xFF6200EA);    // Deep Purple
  static const Color brandSecondary = Color(0xFF00BFA5);  // Vibrant Teal
  static const Color accentColor = Color(0xFFFFA000);     // Gold/Amber accent for CTAs
  static const Color accentSecondary = Color(0xFFFF5252); // Coral Red secondary accent
  
  // Legacy colors (keeping for compatibility)
  static const Color primaryPurple = Color(0xFF6A11CB);
  static const Color primaryBlue = Color(0xFF2575FC);
  static const Color accentPink = Color(0xFFFF416C);
  static const Color accentOrange = Color(0xFFFF4B2B);
  
  // Enhanced Neutral colors
  static const Color textDark = Color(0xFF212121);       // Almost black for text
  static const Color textMedium = Color(0xFF616161);     // Medium gray for secondary text
  static const Color textLight = Color(0xFF9E9E9E);      // Light gray for tertiary text
  static const Color background = Color(0xFFF8F9FC);     // Subtle blue-white background
  static const Color surfaceLight = Color(0xFFFFFFFF);   // White surface
  static const Color surfaceMedium = Color(0xFFF5F7FA);  // Light blue-gray surface
  static const Color divider = Color(0xFFE0E0E0);        // Light gray for dividers
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // Feedback states with more vibrant colors
  static const Color success = Color(0xFF00C853);       // Bright green for success
  static const Color error = Color(0xFFFF1744);         // Vibrant red for errors
  static const Color warning = Color(0xFFFFAB00);       // Bright amber for warnings
  static const Color info = Color(0xFF2196F3);          // Bright blue for info
  
  // Premium gradient combinations
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandPrimary, Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [white, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Fancy gradient combinations
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFFBF953F), Color(0xFFFCF6BA), Color(0xFFB38728)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF0288D1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Modern Typography styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: -0.2,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textMedium,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMedium,
    letterSpacing: 0.2,
    height: 1.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: 0.4,
  );
  
  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLight,
    letterSpacing: 0.2,
  );
  
  // Enhanced decorations with more depth and style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 12,
        spreadRadius: 0,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: brandGradient,
    boxShadow: [
      BoxShadow(
        color: brandPrimary.withValues(alpha: 0.3),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration accentButtonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: accentGradient,
    boxShadow: [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.3),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration luxuryButtonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: luxuryGradient,
    boxShadow: [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.3),
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration glassmorphicDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Colors.white.withValues(alpha: 0.1),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );
  
  // Button styles with modern look
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: brandPrimary,
    foregroundColor: white,
    textStyle: buttonText,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(0, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: brandSecondary,
    foregroundColor: white,
    textStyle: buttonText,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(0, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  );
  
  static ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: white,
    textStyle: buttonText,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(0, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  );
  
  static ButtonStyle gradientButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    foregroundColor: white,
    textStyle: buttonText,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(0, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: brandPrimary,
    textStyle: buttonText.copyWith(color: brandPrimary),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(0, 50),
    side: const BorderSide(color: brandPrimary, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // App theme
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: brandPrimary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: accentColor,
        // ColorScheme.background is gone; the page colour is carried by
        // scaffoldBackgroundColor above.
        surface: white,
        error: error,
      ),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        displaySmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: buttonText,
        labelSmall: captionText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark, 
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: brandPrimary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlinedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          textStyle: buttonText.copyWith(color: brandPrimary),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandPrimary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandPrimary;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandPrimary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandPrimary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPrimary,
        circularTrackColor: surfaceMedium,
        linearTrackColor: surfaceMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMedium,
        disabledColor: surfaceMedium.withValues(alpha: 0.5),
        selectedColor: brandPrimary,
        secondarySelectedColor: brandSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: bodyMedium,
        secondaryLabelStyle: bodyMedium.copyWith(color: white),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      useMaterial3: true,
    );
  }

  // Dark theme option (for future implementation)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: brandPrimary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: accentColor,
        // ColorScheme.background is gone; the page colour is carried by
        // scaffoldBackgroundColor above.
        surface: const Color(0xFF1E1E1E),
        error: error,
      ),
      // Other theme settings would be defined here
      useMaterial3: true,
    );
  }
} 