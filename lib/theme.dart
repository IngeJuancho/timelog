import 'package:flutter/material.dart';

class AppTheme {
  // --- DESIGN TOKENS 2.0: PRECISION INDUSTRIAL ---
  static const Color emeraldLaser = Color(0xFF00E599); // Acento primario hiper-legible
  static const Color emeraldDark = Color(0xFF059669);  // Modo claro alto contraste
  static const Color primaryTeal = emeraldLaser;       // Compatibilidad hacia atrás

  // Semántica
  static const Color skyPrecision = Color(0xFF38BDF8);
  static const Color amberIndustrial = Color(0xFFF59E0B);
  static const Color crimsonOutlier = Color(0xFFEF4444);

  // Superficies AMOLED
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0F1115);
  static const Color amoledSurfaceContainer = Color(0xFF161920);
  static const Color amoledSurfaceContainerHighest = Color(0xFF1D222B);
  static const Color amoledBorder = Color(0xFF262C36);

  // Superficies Modo Claro
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);

  static final ThemeData amoledTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: emeraldLaser,
      brightness: Brightness.dark,
      surface: amoledBackground,
    ).copyWith(
      surface: amoledBackground,
      surfaceContainer: amoledSurface,
      surfaceContainerHigh: amoledSurfaceContainer,
      surfaceContainerHighest: amoledSurfaceContainerHighest,
      outline: amoledBorder,
      outlineVariant: amoledBorder.withValues(alpha: 0.5),
      onSurface: const Color(0xFFF1F5F9),
      primary: emeraldLaser,
      onPrimary: Colors.black,
      secondary: skyPrecision,
      error: crimsonOutlier,
    ),
    scaffoldBackgroundColor: amoledBackground,
    cardColor: amoledSurface,
    dividerColor: amoledBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
      titleTextStyle: TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: amoledSurfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: amoledBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: amoledBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: emeraldLaser, width: 1.5),
      ),
      prefixIconColor: emeraldLaser,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF12141A),
      elevation: 16,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF14171E),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: amoledBorder, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 14,
        height: 1.4,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF8FAFC)),
      bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
      bodySmall: TextStyle(color: Color(0xFF94A3B8)),
      titleMedium: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: emeraldDark,
      brightness: Brightness.light,
      surface: lightBackground,
    ).copyWith(
      surface: lightBackground,
      surfaceContainer: lightSurface,
      surfaceContainerHigh: lightSurfaceContainer,
      surfaceContainerHighest: lightSurfaceContainerHighest,
      outline: lightBorder,
      outlineVariant: lightBorder.withValues(alpha: 0.6),
      onSurface: const Color(0xFF0F172A),
      primary: emeraldDark,
      onPrimary: Colors.white,
      secondary: const Color(0xFF0284C7),
      error: const Color(0xFFDC2626),
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightSurface,
    dividerColor: lightBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF334155)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: emeraldDark, width: 1.5),
      ),
      prefixIconColor: emeraldDark,
      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      labelStyle: TextStyle(color: Color(0xFF475569), fontSize: 13),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFFF1F5F9),
      elevation: 16,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 14,
        height: 1.4,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF475569)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0F172A)),
      bodyMedium: TextStyle(color: Color(0xFF1E293B)),
      bodySmall: TextStyle(color: Color(0xFF64748B)),
      titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFF020617), fontWeight: FontWeight.bold),
    ),
  );

  /// Devuelve el verde esmeralda acento adecuado según el modo (oscuro o claro)
  static Color getTealAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? emeraldDark   // Esmeralda 600 de alto contraste para fondo blanco
        : emeraldLaser;  // Láser esmeralda vibrante para fondo negro puro
  }

  static Color getTealFill(BuildContext context, {double darkAlpha = 0.14, double lightAlpha = 0.12}) {
    return Theme.of(context).brightness == Brightness.light
        ? emeraldDark.withValues(alpha: lightAlpha)
        : emeraldLaser.withValues(alpha: darkAlpha);
  }

  static Color getTealBorder(BuildContext context, {double darkAlpha = 0.45, double lightAlpha = 0.6}) {
    return Theme.of(context).brightness == Brightness.light
        ? emeraldDark.withValues(alpha: lightAlpha)
        : emeraldLaser.withValues(alpha: darkAlpha);
  }

  static Color getGreenAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF15803D) // Verde esmeralda bosque
        : emeraldLaser;
  }
}
