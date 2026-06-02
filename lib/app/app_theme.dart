import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color icyBlue = Color(0xFFADD7F6);
  static const Color babyBlueIce = Color(0xFF87BFFF);
  static const Color blueEnergy = Color(0xFF3F8EFC);
  static const Color electricSapphire = Color(0xFF2667FF);
  static const Color ultrasonicBlue = Color(0xFF3B28CC);

  static const Color background = Color(0xFFF5FAFF);
  static const Color surface = Color(0xFFFCFDFF);
  static const Color surfaceBlue = Color(0xFFEAF5FF);
  static const Color ink = Color(0xFF12213A);
  static const Color muted = Color(0xFF63728A);
  static const Color line = Color(0xFFD7E8F8);

  static const Color green = Color(0xFF18A66A);
  static const Color greenSoft = Color(0xFFE7F8EF);
  static const Color warm = Color(0xFFF4A340);
  static const Color warmSoft = Color(0xFFFFF1D8);
  static const Color error = Color(0xFFE5484D);
  static const Color errorSoft = Color(0xFFFFE9EA);

  static const Color violet = electricSapphire;
  static const Color violetDark = ultrasonicBlue;
  static const Color violetSoft = surfaceBlue;
  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color lightInk = ink;
  static const Color lightMuted = muted;

  static LinearGradient get brandGradient => const LinearGradient(
    colors: [babyBlueIce, blueEnergy, electricSapphire],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get deepBrandGradient => const LinearGradient(
    colors: [blueEnergy, electricSapphire, ultrasonicBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: electricSapphire,
      primary: electricSapphire,
      secondary: blueEnergy,
      tertiary: babyBlueIce,
      surface: background,
      onSurface: ink,
      error: error,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: icyBlue.withValues(alpha: 0.42),
        shadowColor: electricSapphire.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? electricSapphire : muted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? electricSapphire : muted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: electricSapphire, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricSapphire,
          foregroundColor: surface,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricSapphire,
          foregroundColor: surface,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricSapphire,
          side: const BorderSide(color: line),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricSapphire,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData dark() => light();
}
