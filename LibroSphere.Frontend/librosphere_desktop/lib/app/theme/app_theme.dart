import 'package:flutter/material.dart';

const desktopPrimary = Color(0xFF2F87F5);
const desktopPrimaryLight = Color(0xFF69A3F5);
const desktopBackground = Color(0xFFF4F4F4);
const desktopMutedForeground = Color(0xB7D6E7FF);

ThemeData buildDesktopAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: desktopPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: desktopPrimary,
    surface: desktopBackground,
  );

  return ThemeData(
    useMaterial3: false,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: desktopBackground,
    colorScheme: colorScheme,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
