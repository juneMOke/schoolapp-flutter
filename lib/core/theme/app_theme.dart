import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color backgroundColor = Color(0xFFF7F9FF);
  static const Color surfaceColor = Colors.white;
  static const Color sidebarColor = Color(0xFF2E3B4E);
  static const Color activeMenuColor = Color(0xFF1A73E8);
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);

  // Dimensions
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 70.0;
  static const double topBarHeight = 64.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 1,
      iconTheme: IconThemeData(color: textPrimaryColor),
    ),
  );
}