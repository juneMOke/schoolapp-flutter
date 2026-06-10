import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Lien retour charté du flux de réinitialisation, coiffant la colonne
/// formulaire sur tous les paliers. Revient à l'écran précédent du flux, ou à
/// la connexion si la pile est vide (accès direct par lien profond).
class ResetBackLink extends StatelessWidget {
  const ResetBackLink({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // `TextButton.icon` expose déjà sa sémantique de bouton ; pas de wrapper
    // `Semantics` supplémentaire (qui ferait un nœud redondant).
    return Tooltip(
      message: l10n.resetBackToLogin,
      child: TextButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutesNames.login);
          }
        },
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: Text(l10n.resetBackToLogin),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.bleuProfond,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }
}
