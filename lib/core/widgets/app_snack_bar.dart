import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Helpers centralisés pour afficher des [SnackBar] cohérents dans l'application.
abstract final class AppSnackBar {
  /// Affiche un [SnackBar] de succès.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, variant: _AppSnackBarVariant.success);
  }

  /// Affiche un [SnackBar] d'erreur.
  static void showError(BuildContext context, String message) {
    _show(context, message: message, variant: _AppSnackBarVariant.error);
  }

  /// Affiche un [SnackBar] d'avertissement.
  static void showWarning(BuildContext context, String message) {
    _show(context, message: message, variant: _AppSnackBarVariant.warning);
  }

  /// Affiche un [SnackBar] d'information.
  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, variant: _AppSnackBarVariant.info);
  }

  /// Affiche un [SnackBar] listant les erreurs de validation.
  ///
  /// [title] : libellé introductif (ex. « Veuillez corriger les champs suivants : »).
  /// [reasons] : liste des messages d'erreur individuels.
  static void showValidationErrors(
    BuildContext context, {
    required String title,
    required List<String> reasons,
  }) {
    final details = reasons
        .where((reason) => reason.trim().isNotEmpty)
        .map((reason) => '• ${reason.trim()}')
        .join('\n');
    final message = details.isEmpty ? title : '$title\n$details';

    _show(
      context,
      message: message,
      variant: _AppSnackBarVariant.warning,
      duration: const Duration(seconds: 6),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _AppSnackBarVariant variant,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final style = switch (variant) {
      _AppSnackBarVariant.success => (
        icon: Icons.check_circle_rounded,
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
      ),
      _AppSnackBarVariant.error => (
        icon: Icons.error_rounded,
        background: colors.errorContainer,
        foreground: colors.onErrorContainer,
      ),
      _AppSnackBarVariant.warning => (
        icon: Icons.warning_rounded,
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
      ),
      _AppSnackBarVariant.info => (
        icon: Icons.info_rounded,
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: style.background,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 20, color: style.foreground),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

enum _AppSnackBarVariant { success, error, warning, info }
