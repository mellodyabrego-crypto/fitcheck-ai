import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // ── Base (80%) ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFEDE5DB); // main app background
  static const Color surface = Color(0xFFF5EDE6); // cards / overlays
  static const Color beige = Color(0xFFD9CAB8); // primary neutral
  static const Color beigeDeep = Color(0xFFC0A88C); // dividers / containers

  // ── Text / Icons ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2F2F2F); // body text
  static const Color textSecondary = Color(0xFF4A4A4A); // secondary text
  static const Color textHeader = Color(0xFF1F1F1F); // headers / strong

  // ── Accent (15%) — Deeper Blush Rose ──────────────────────────────────────
  static const Color primary = Color(
    0xFFC48A96,
  ); // main accent (one shade deeper)
  static const Color primaryLight = Color(0xFFD8A7B1); // hover / highlight
  static const Color primaryDeep = Color(0xFFA96E7A); // active states

  // ── Highlight (5%) — Deeper Matte Gold ────────────────────────────────────
  static const Color accent = Color(
    0xFFB89A5D,
  ); // primary gold (one shade deeper)
  static const Color accentDeep = Color(0xFF9E8248); // icons / accents
  static const Color accentLight = Color(0xFFC6A96B); // subtle glow

  // ── Legacy aliases (used by decorative_symbols.dart) ──────────────────────
  static const Color secondary = beigeDeep; // warm neutral
  static const Color lightPink = primaryLight; // light blush

  // ── Gradients ──────────────────────────────────────────────────────────────
  // Hero elements: blush → deep blush
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC48A96), Color(0xFFA96E7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cards / backgrounds: cream → warm beige
  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFEDE5DB), Color(0xFFD9CAB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextTheme get _textTheme => TextTheme(
        // Headlines — Dancing Script (feminine, readable cursive)
        displayLarge: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.dancingScript(
          color: textHeader,
          fontWeight: FontWeight.w700,
        ),
        // Titles — Dancing Script
        titleLarge: GoogleFonts.dancingScript(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.dancingScript(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: GoogleFonts.dancingScript(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        // Body / UI — Inter (stays clean and readable)
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textSecondary, fontSize: 12),
        labelLarge: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: GoogleFonts.inter(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelSmall: GoogleFonts.inter(color: textSecondary, fontSize: 11),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        textTheme: _textTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: beigeDeep,
          tertiary: accent,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.dancingScript(
            color: textHeader,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryDeep,
            side: const BorderSide(color: primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryDeep),
        ),
        inputDecorationTheme: InputDecorationTheme(
          // White-ish field so dark typed text has strong contrast on any device.
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: beigeDeep),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
          // Typed text — explicit dark color so system dark-mode overrides don't hide it.
          floatingLabelStyle: const TextStyle(color: primaryDeep),
          prefixIconColor: primary,
        ),
        chipTheme: ChipThemeData(
          selectedColor: primary.withValues(alpha: 0.18),
          side: const BorderSide(color: beigeDeep),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: surface,
        ),
        dividerTheme: const DividerThemeData(color: beigeDeep, thickness: 1),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primaryDeep,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: primary),
        iconTheme: const IconThemeData(color: textPrimary),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.playfairDisplayTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: primary,
          secondary: beigeDeep,
          tertiary: accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedItemColor: primaryLight,
          unselectedItemColor: Color(0xFF4A4A4A),
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
