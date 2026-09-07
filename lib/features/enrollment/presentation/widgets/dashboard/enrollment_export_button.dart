import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Un bouton de sortie : icône **et** libellé, contour, cible tactile 44 dp.
///
/// Le libellé n'est pas décoratif — une icône seule laisse deviner ce qui va
/// se produire, et deux icônes voisines (imprimer, tableur) se confondent.
/// C'est ce qui permet au PDF de porter un glyphe de téléchargement sans se
/// confondre avec le CSV : les deux s'appellent par leur nom.
class EnrollmentExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const EnrollmentExportButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
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
                    Icon(
                      icon,
                      size: AppDimensions.detailMiniIconSize,
                      color: AppColors.bleuArdoise,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      label,
                      style: AppTextStyles.action.copyWith(
                        color: AppColors.bleuArdoise,
                      ),
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
