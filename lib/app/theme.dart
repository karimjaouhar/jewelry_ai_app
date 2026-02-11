import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF15828A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDCEFEF),
      onPrimaryContainer: Color(0xFF15828A),
      secondary: Color(0xFF15828A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF1EFED),
      onSecondaryContainer: Color(0xFF1C1C1C),
      tertiary: Color(0xFF6B6B6B),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFF2F2F0),
      onTertiaryContainer: Color(0xFF1C1C1C),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      // ignore: deprecated_member_use
      background: Color(0xFFFAFAF9),
      // ignore: deprecated_member_use
      onBackground: Color(0xFF1C1C1C),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C1C1C),
      // ignore: deprecated_member_use
      surfaceVariant: Color(0xFFF7F7F5),
      surfaceContainerHighest: Color(0xFFF7F7F5),
      onSurfaceVariant: Color(0xFF6B6B6B),
      outline: Color(0xFFE5E5E3),
      outlineVariant: Color(0xFFE5E5E3),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1C1C1C),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF8AC6CB),
      surfaceTint: Color(0xFF15828A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      disabledColor: const Color(0xFF9A9A9A),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF15828A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDCEFEF),
      onPrimaryContainer: Color(0xFF15828A),
      secondary: Color(0xFF15828A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF2A2523),
      onSecondaryContainer: Color(0xFFF2F2F2),
      tertiary: Color(0xFFB5B5B5),
      onTertiary: Color(0xFF141414),
      tertiaryContainer: Color(0xFF222222),
      onTertiaryContainer: Color(0xFFF2F2F2),
      error: Color(0xFFCF6679),
      onError: Color(0xFF1C1C1C),
      errorContainer: Color(0xFF8C1D2A),
      onErrorContainer: Color(0xFFF2F2F2),
      // ignore: deprecated_member_use
      background: Color(0xFF141414),
      // ignore: deprecated_member_use
      onBackground: Color(0xFFF2F2F2),
      surface: Color(0xFF141414),
      onSurface: Color(0xFFF2F2F2),
      // ignore: deprecated_member_use
      surfaceVariant: Color(0xFF1C1C1C),
      surfaceContainerHighest: Color(0xFF1C1C1C),
      onSurfaceVariant: Color(0xFFB5B5B5),
      outline: Color(0xFF2A2A2A),
      outlineVariant: Color(0xFF2A2A2A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF2F2F2),
      onInverseSurface: Color(0xFF141414),
      inversePrimary: Color(0xFF8AC6CB),
      surfaceTint: Color(0xFF15828A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      disabledColor: const Color(0xFF7A7A7A),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
