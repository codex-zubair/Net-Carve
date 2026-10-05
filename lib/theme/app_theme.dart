import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// NetCarve design system.
///
/// Philosophy: precise, technical, calm. A dark instrument panel that reads
/// clearly in a data centre, with a single cyan accent reserved for the
/// "answer" values an engineer actually needs.
class AppColors {
  static const bg = Color(0xFF0B1120);
  static const bgDeep = Color(0xFF070B15);
  static const surface = Color(0xFF141B2E);
  static const surfaceHi = Color(0xFF1C2540);
  static const surfaceTop = Color(0xFF232E4C);

  static const accent = Color(0xFF2DD4BF);
  static const accentDim = Color(0xFF14B8A6);
  static const accentSoft = Color(0xFF5EEAD4);
  static const blue = Color(0xFF60A5FA);
  static const violet = Color(0xFFA78BFA);
  static const amber = Color(0xFFFBBF24);

  static const text = Color(0xFFE8EEF9);
  static const textMuted = Color(0xFF94A3B8);
  static const textFaint = Color(0xFF64748B);

  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFF87171);
  static const divider = Color(0xFF23304D);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.bg,
          primary: AppColors.accent,
          secondary: AppColors.blue,
          error: AppColors.danger,
        );

    final mono = GoogleFonts.jetBrainsMonoTextTheme(base.textTheme);
    final body = GoogleFonts.interTextTheme(mono);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: body.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.bg,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.textFaint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHi,
        side: const BorderSide(color: AppColors.divider),
        labelStyle: const TextStyle(color: AppColors.text, fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: Color(0x552DD4BF),
        selectionHandleColor: AppColors.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }

  /// Monospace text style for addresses and numbers.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  static const double screenPadding = 18;
}
