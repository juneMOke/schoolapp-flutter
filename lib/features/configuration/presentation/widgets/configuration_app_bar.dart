import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre de titre de l'assistant : bande Bleu Profond de 68 dp, texturée kuba,
/// avec le compteur d'étapes à droite et la sortie à l'extrémité.
///
/// Quitter ne demande **aucune confirmation** : tout est enregistré. Une
/// confirmation ici ferait croire à un risque qui n'existe pas, et apprendrait
/// à l'agent à cliquer sans lire.
class ConfigurationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int stepNumber;
  final int stepCount;
  final VoidCallback onExit;

  const ConfigurationAppBar({
    super.key,
    required this.stepNumber,
    required this.stepCount,
    required this.onExit,
  });

  static const double height = 68;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
                ),
              ),
            ),
          ),
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.configurationTitle,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                      Text(
                        l10n.configurationSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.configurationStepCounter(stepNumber, stepCount),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.72),
                    // Chiffres tabulaires : le compteur ne doit pas se dandiner
                    // d'une étape à l'autre.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.textOnDark.withValues(alpha: 0.10),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: IconButton(
                    onPressed: onExit,
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    color: AppColors.textOnDark,
                    tooltip: l10n.configurationExitTooltip,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
