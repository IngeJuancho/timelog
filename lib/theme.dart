import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00BFA5);

  static final ThemeData amoledTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.dark,
      surface: const Color(0xFF000000), // AMOLED black
    ).copyWith(
      surface: const Color(0xFF000000), 
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF151515), 
    dividerColor: Colors.white10,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      prefixIconColor: primaryTeal,
      labelStyle: const TextStyle(color: Colors.white60),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.light,
      surface: Colors.white,
    ).copyWith(
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black54),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: primaryTeal, width: 2),
      ),
      prefixIconColor: primaryTeal,
      labelStyle: TextStyle(color: Colors.black54),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: Colors.grey.shade100,
    ),
    iconTheme: const IconThemeData(color: Colors.black54),
  );

  /// Devuelve el verde/teal acento adecuado según el modo (oscuro o claro)
  /// para garantizar alto contraste y legibilidad.
  static Color getTealAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF00796B) // Teal 700 de alto contraste para modo claro
        : Colors.tealAccent;      // Neon verde para AMOLED/modo oscuro
  }

  static Color getTealFill(BuildContext context, {double darkAlpha = 0.15, double lightAlpha = 0.18}) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF00796B).withValues(alpha: lightAlpha)
        : Colors.tealAccent.withValues(alpha: darkAlpha);
  }

  static Color getTealBorder(BuildContext context, {double darkAlpha = 0.5, double lightAlpha = 0.7}) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF00796B).withValues(alpha: lightAlpha)
        : Colors.tealAccent.withValues(alpha: darkAlpha);
  }

  static Color getGreenAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF2E7D32) // Verde oscuro legible para modo claro
        : Colors.greenAccent;
  }
}

