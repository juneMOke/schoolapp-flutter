import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Un bouton de sortie : icône **et** libellé, contour, cible tactile 44 dp.
///
/// Le libellé n'est pas décoratif — une icône seule laisse deviner ce qui va
/// se produire, et deux icônes voisines se confondent. C'est ce qui permet au
/// PDF de porter un glyphe de téléchargement sans ambiguïté : chaque bouton
/// s'appelle par son nom.
///
/// ## Un bouton qui attend le dit
///
/// Le registre des inscrits est composé par le serveur, un document long à la
/// fois : le bouton se **désarme** ([onPressed] nul) pendant le rendu et
/// pendant l'attente d'un 429, et son libellé dit lequel des deux.
class EnrollmentExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  /// `null` désarme le bouton — un rendu en cours, une attente imposée.
  final VoidCallback? onPressed;

  /// Remplace l'icône par un indicateur d'activité, à la même place et à la
  /// même taille : le libellé dit ce qui se passe, l'indicateur montre que ça
  /// avance.
  final bool busy;

  const EnrollmentExportButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? AppColors.bleuArdoise : AppColors.textMuted;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.enrollmentDashboardTabMinHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                ),
                // Variante « outlined » de la spec : le contour donne au
                // bouton son assise dans l'en-tête de carte, où un libellé nu
                // se lirait comme une légende de plus.
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy)
                      SizedBox.square(
                        dimension: AppDimensions.detailMiniIconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppDimensions
                              .enrollmentDashboardExportSpinnerStroke,
                          color: color,
                        ),
                      )
                    else
                      Icon(
                        icon,
                        size: AppDimensions.detailMiniIconSize,
                        color: color,
                      ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      label,
                      style: AppTextStyles.action.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
