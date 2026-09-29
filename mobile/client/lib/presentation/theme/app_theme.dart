import 'package:flutter/material.dart';

abstract final class ClientTheme {
  static const primary = Color(0xFF054A3E);
  static const mint = Color(0xFF10B981);
  static const canvas = Color(0xFFF8F9FF);
  static const ink = Color(0xFF0B1C30);

  static ThemeData light() => _theme(
    ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6F7F2),
      onPrimaryContainer: primary,
      secondary: mint,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB2EFDE),
      onSecondaryContainer: const Color(0xFF005236),
      surface: canvas,
      onSurface: ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFEFF4FF),
      surfaceContainer: const Color(0xFFE5EEFF),
      outlineVariant: const Color(0xFFBFC9C4),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    ),
  );

  static ThemeData dark() => _theme(
    ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF8CDAB9),
      onPrimary: const Color(0xFF00382A),
      primaryContainer: const Color(0xFF145642),
      onPrimaryContainer: const Color(0xFFF0FFF7),
      secondary: const Color(0xFF6CF8BB),
      onSecondary: const Color(0xFF002113),
      surface: const Color(0xFF101B17),
      onSurface: const Color(0xFFE0E9E3),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    ),
  );

  static ThemeData _theme(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    useMaterial3: true,
    textTheme: ThemeData(brightness: scheme.brightness).textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
      bodySmall: const TextStyle(fontSize: 12, height: 1.35),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: .92),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? scheme.primary : scheme.outline);
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
      ),
    ),
  );
}
