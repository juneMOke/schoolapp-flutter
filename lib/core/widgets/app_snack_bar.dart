import 'package:flutter/material.dart';

/// Helpers centralisés pour afficher des [SnackBar] cohérents dans l'application.
abstract final class AppSnackBar {
  /// Affiche un [SnackBar] de succès (fond vert).
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Affiche un [SnackBar] d'erreur (fond rouge).
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title\n- ${reasons.join('\n- ')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
