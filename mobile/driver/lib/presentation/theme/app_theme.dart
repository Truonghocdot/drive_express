import 'package:flutter/material.dart';

@immutable
class DriverTokens extends ThemeExtension<DriverTokens> {
  const DriverTokens({
    required this.canvas,
    required this.surfaceLow,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.primary,
    required this.secondary,
    required this.warning,
    required this.danger,
    required this.muted,
    required this.divider,
  });

  final Color canvas;
  final Color surfaceLow;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color primary;
  final Color secondary;
  final Color warning;
  final Color danger;
  final Color muted;
  final Color divider;

  @override
  DriverTokens copyWith({
    Color? canvas,
    Color? surfaceLow,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? primary,
    Color? secondary,
    Color? warning,
    Color? danger,
    Color? muted,
    Color? divider,
  }) {
    return DriverTokens(
      canvas: canvas ?? this.canvas,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      muted: muted ?? this.muted,
      divider: divider ?? this.divider,
    );
  }

  @override
  DriverTokens lerp(ThemeExtension<DriverTokens>? other, double t) {
    if (other is! DriverTokens) return this;
    return DriverTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension DriverThemeContext on BuildContext {
  DriverTokens get driverTokens => Theme.of(this).extension<DriverTokens>()!;
}

abstract final class DriverTheme {
  static const _canvas = Color(0xFF0B111E);
  static const _surfaceLow = Color(0xFF111A2E);
  static const _surface = Color(0xFF18233C);
  static const _surfaceHigh = Color(0xFF233354);
  static const _surfaceHighest = Color(0xFF2B3C5D);
  static const _primary = Color(0xFF10B981);
  static const _secondary = Color(0xFF06B6D4);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFEF4444);
  static const _muted = Color(0xFF94A3B8);
  static const _divider = Color(0x3347556B);

  static ThemeData light() => _theme(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B8F68),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF087A59),
      onPrimary: Colors.white,
      secondary: const Color(0xFF087E98),
      error: const Color(0xFFB42318),
      surface: const Color(0xFFF4F7FA),
      onSurface: const Color(0xFF142033),
    ),
    isDark: false,
  );

  static ThemeData dark() => _theme(
    const ColorScheme.dark(
      primary: _primary,
      onPrimary: Color(0xFF002117),
      secondary: _secondary,
      onSecondary: Color(0xFF00242B),
      tertiary: _warning,
      onTertiary: Color(0xFF281500),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: _canvas,
      onSurface: Color(0xFFF8FAFC),
    ),
    isDark: true,
  );

  static ThemeData _theme(ColorScheme scheme, {required bool isDark}) {
    final tokens = isDark
        ? const DriverTokens(
            canvas: _canvas,
            surfaceLow: _surfaceLow,
            surface: _surface,
            surfaceHigh: _surfaceHigh,
            surfaceHighest: _surfaceHighest,
            primary: _primary,
            secondary: _secondary,
            warning: _warning,
            danger: _danger,
            muted: _muted,
            divider: _divider,
          )
        : const DriverTokens(
            canvas: Color(0xFFF4F7FA),
            surfaceLow: Colors.white,
            surface: Color(0xFFEAF1F5),
            surfaceHigh: Color(0xFFD9E6EC),
            surfaceHighest: Color(0xFFC9DCE3),
            primary: Color(0xFF087A59),
            secondary: Color(0xFF087E98),
            warning: Color(0xFFB26A00),
            danger: Color(0xFFB42318),
            muted: Color(0xFF526579),
            divider: Color(0x334B6370),
          );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      useMaterial3: true,
      extensions: [tokens],
      textTheme: ThemeData(brightness: scheme.brightness).textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
        bodySmall: const TextStyle(fontSize: 12, height: 1.35),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: tokens.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: tokens.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: tokens.secondary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: tokens.surfaceLow,
        indicatorColor: tokens.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, color: scheme.onSurface),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceLow,
        modalBackgroundColor: tokens.surfaceLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
