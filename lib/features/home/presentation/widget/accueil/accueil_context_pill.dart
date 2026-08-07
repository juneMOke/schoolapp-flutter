import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Pastille de contexte du bandeau de marque (spec Accueil §02 composant).
///
/// Capsule translucide portant une information de contexte (date du jour,
/// année scolaire). Purement décorative : elle n'est pas cliquable et reste
/// hors de l'ordre de tabulation — le lecteur d'écran lit simplement son texte.
class AccueilContextPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const AccueilContextPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AccueilUiTokens.pillPaddingH,
        vertical: AccueilUiTokens.pillPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.blancCasse.withValues(
          alpha: AccueilUiTokens.pillFillOpacity,
        ),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: AppColors.blancCasse.withValues(
            alpha: AccueilUiTokens.pillBorderOpacity,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AccueilUiTokens.pillIconSize,
            color: AppColors.orDoux,
          ),
          const SizedBox(width: AccueilUiTokens.pillIconGap),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: AccueilUiTokens.pillFontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.blancCasse.withValues(
                  alpha: AccueilUiTokens.pillTextOpacity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
