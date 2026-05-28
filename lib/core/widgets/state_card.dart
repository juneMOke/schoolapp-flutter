import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Carte d'état générique (chargement / vide / erreur) avec action optionnelle.
///
/// Utilisée par tous les modules pour afficher un état transitoire ou vide
/// avec message personnalisé, icône et couleurs.
class StateCard extends StatelessWidget {
  /// Message principal à afficher
  final String message;

  /// Icône à afficher en haut à gauche
  final IconData icon;

  /// Couleur de base pour le texte et l'icône
  final Color accent;

  /// Couleur de fond adoucie pour la carte
  final Color accentSoft;

  /// Libellé du bouton d'action optionnel
  final String? actionLabel;

  /// Callback exécuté à la pression du bouton d'action
  final VoidCallback? onAction;

  /// Widget optionnel affiché après le message (ex: LinearProgressIndicator)
  final Widget? child;

  const StateCard({
    super.key,
    required this.message,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.outCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: AppDimensions.detailHeaderIconSize,
                color: accent,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: accent,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            child!,
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
