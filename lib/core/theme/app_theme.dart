import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Paleta ──────────────────────────────────────────────
  static const Color accent      = Color(0xFF9E7C5E);
  static const Color accentLight = Color(0xFFD4A76A);
  static const Color accentDark  = Color(0xFF1A1A1A);

  // Neutros light
  static const Color bgLight        = Color(0xFFFEFBF7);
  static const Color surfaceLight   = Color(0xFFF5F3F0);
  static const Color borderLight    = Color(0xFFE0E0E0);
  static const Color textPrimary    = Color(0xFF2C2C2C);
  static const Color textSecondary  = Color(0xFF5A5A5A);
  static const Color textTertiary   = Color(0xFF64748B);

  // Neutros dark
  static const Color bgDark       = Color(0xFF111111);
  static const Color surfaceDark  = Color(0xFF1C1C1C);
  static const Color borderDark   = Color(0xFF2A2A2A);

  // Semánticos
  static const Color success = Color(0xFF9E7C5E);
  static const Color warning = Color(0xFFC68B2C);
  static const Color danger  = Color(0xFFD85A30);
  static const Color info    = Color(0xFF3B82F6);

  // ── Tokens de diseño ────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 14.0;
  static const double radiusLg  = 20.0;
  static const double radiusXl  = 24.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ── LIGHT THEME ─────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD4A76A),
      onPrimaryContainer: const Color(0xFF1A1A1A),
      secondary: const Color(0xFF5A5A5A),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEFBF7),
      onSecondaryContainer: const Color(0xFF2C2C2C),
      tertiary: info,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: borderLight,
      outlineVariant: const Color(0xFFF0F0EE),
      
    ),

    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: bgLight,

    // Cards — Premium con profundidad sutil
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // Divider sutil
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 0,
    ),

    // Inputs Modernos
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: danger, width: 1),
      ),
      hintStyle: TextStyle(color: textTertiary, fontSize: 14),
      labelStyle: TextStyle(color: textSecondary, fontSize: 14),
    ),

    // Botones Primarios
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE0E0E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.1,
        ),
      ),
    ),

    // Botones Secundarios (Outline)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
      foregroundColor: const Color(0xFF2D3748),
      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // FAB Premium
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // AppBar Limpia y Elegante
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: const Color(0xFFFEFBF7),
      foregroundColor: const Color(0xFF2C2C2C),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2C2C2C),
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF5A5A5A), size: 22),
    ),

    // NavigationBar (Móvil)
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: const Color(0xFFF5F3F0),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFF0F7E8),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? accent : const Color(0xFF5A5A5A),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? accent : const Color(0xFF5A5A5A),
        );
      }),
    ),

    // NavigationRail (Sidebar Web)
    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: const Color(0xFFF5F3F0),
      indicatorColor: const Color(0xFFF0F7E8),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      selectedIconTheme: const IconThemeData(color: accent, size: 24),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF5A5A5A), size: 24),
      selectedLabelTextStyle: TextStyle(
        color: accent,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: const Color(0xFF5A5A5A),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: const Color(0xFF5A5A5A),
      textColor: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      elevation: 0,
      backgroundColor: const Color(0xFFF5F3F0),
      selectedColor: const Color(0xFFD4A76A),
      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    ),

    // Text Theme Refinado
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge:  const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: Color(0xFF2C2C2C)),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: Color(0xFF2C2C2C)),
        headlineLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: Color(0xFF2C2C2C)),
        headlineMedium:const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Color(0xFF2C2C2C)),
        titleLarge:    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Color(0xFF2C2C2C)),
        titleMedium:   const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C)),
        titleSmall:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C)),
        bodyLarge:     const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF2C2C2C)),
        bodyMedium:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF5A5A5A)),
        bodySmall:     const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
        labelLarge:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C)),
        labelMedium:   const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5A5A5A), letterSpacing: 0.3),
        labelSmall:    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B), letterSpacing: 0.4),
      ),
    ),
  );

  // ── DARK THEME ──────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF3D3226),
      onPrimaryContainer: const Color(0xFFD4A76A),
      secondary: const Color(0xFFB4B2A9),
      onSecondary: const Color(0xFF1A1A1A),
      secondaryContainer: const Color(0xFF2C2C2A),
      onSecondaryContainer: const Color(0xFFD3D1C7),
      tertiary: info,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surfaceDark,
      onSurface: const Color(0xFFEEEEEC),
      onSurfaceVariant: const Color(0xFF9A9A98),
      outline: borderDark,
      outlineVariant: const Color(0xFF222222),
      
    ),

    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: bgDark,

    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A2A),
      thickness: 1,
      space: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: accent, width: 1.8),
      ),
      hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 14),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: const Color(0xFFEEEEEC),
        side: const BorderSide(color: borderDark, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: bgDark,
      foregroundColor: const Color(0xFFEEEEEC),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFEEEEEC),
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF9A9A98), size: 22),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: surfaceDark,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFF0A3D2E),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? accent : const Color(0xFF9A9A98),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: active ? accent : const Color(0xFF9A9A98),
        );
      }),
    ),

    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: surfaceDark,
      indicatorColor: const Color(0xFF0A3D2E),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      selectedIconTheme: const IconThemeData(color: accent, size: 24),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF9A9A98), size: 24),
      selectedLabelTextStyle: const TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: const TextStyle(color: Color(0xFF9A9A98), fontSize: 13, fontWeight: FontWeight.w500),
    ),

    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      iconColor: const Color(0xFF9A9A98),
      textColor: const Color(0xFFEEEEEC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    chipTheme: ChipThemeData(
      elevation: 0,
      backgroundColor: surfaceDark,
      selectedColor: const Color(0xFF0A3D2E),
      side: const BorderSide(color: borderDark, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    ),

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: Color(0xFFEEEEEC)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: Color(0xFFEEEEEC)),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: Color(0xFFEEEEEC)),
        headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Color(0xFFEEEEEC)),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Color(0xFFEEEEEC)),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFEEEEEC)),
        titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEEEEEC)),
        bodyLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFFEEEEEC)),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9A9A98)),
        bodySmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF9A9A98)),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEEEEEC)),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9A9A98), letterSpacing: 0.3),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF777777), letterSpacing: 0.4),
      ),
    ),
  );
}