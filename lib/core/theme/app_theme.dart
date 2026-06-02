import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/extensions/status_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

class AppTheme {
  AppTheme._();

  // Compat legacy - a migrer progressivement vers les tokens AppColors/AppSpacing
  static const Color primaryColor = AppColors.bleuArdoise;
  static const Color secondaryColor = AppColors.terreCuite;
  static const Color backgroundColor = AppColors.surface;
  static const Color surfaceColor = AppColors.surface;
  static const Color sidebarColor = AppColors.surfaceDark;
  static const Color sidebarGradientTop = AppColors.bleuProfond;
  static const Color sidebarGradientBottom = AppColors.bleuArdoise;
  static const Color accentBlue = AppColors.bleuArdoise;
  static const Color accentIndigo = AppColors.info;
  static const Color activeMenuColor = AppColors.bleuArdoise;
  static const Color textPrimaryColor = AppColors.textPrimary;
  static const Color textSecondaryColor = AppColors.textSecondary;

  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 84;
  static const double topBarHeight = 68;
  static const double defaultPadding = AppSpacing.lg;
  static const double largePadding = AppSpacing.xl;

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.bleuArdoise,
    onPrimary: AppColors.blancCasse,
    secondary: AppColors.terreCuite,
    onSecondary: AppColors.blancCasse,
    tertiary: AppColors.orDoux,
    onTertiary: AppColors.noirChaud,
    error: AppColors.error,
    onError: AppColors.blancCasse,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    splashFactory: NoSplash.splashFactory,
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.surfaceAlt,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.terreCuite,
        foregroundColor: AppColors.blancCasse,
        minimumSize: const Size(double.infinity, 56),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.bleuArdoise,
        side: const BorderSide(color: AppColors.bleuArdoise, width: 1.5),
        minimumSize: const Size(double.infinity, 56),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.bleuArdoise,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: AppColors.bleuArdoise, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    extensions: const [StatusColors.light],
  );

  static ThemeData get dark => light;

  static ThemeData get theme => light;
}
