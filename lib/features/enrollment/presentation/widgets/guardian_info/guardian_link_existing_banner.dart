import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Appel à rattacher une fiche parent DÉJÀ connue, posé en tête du corps de la
/// carte tuteur — juste avant les champs.
///
/// Il remplace l'ancienne loupe de l'en-tête de l'étape : une icône que
/// personne ne cherchait, à l'autre bout de l'écran, alors que le geste se
/// décide au moment exact où l'on s'apprête à taper un nom. Posé ici, il
/// désigne SA carte sans ambiguïté — la fiche choisie remplace celle-ci, et
/// aucun autre tuteur du dossier n'est touché.
///
/// Disparaît dès que la carte porte une fiche existante (identité verrouillée)
/// : l'appel n'aurait plus rien à proposer.
class GuardianLinkExistingBanner extends StatelessWidget {
  final VoidCallback? onPressed;

  const GuardianLinkExistingBanner({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.bleuArdoise.withValues(alpha: 0.20),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack =
              constraints.maxWidth < AppBreakpoints.guardianHeaderRowMin;
          final button = EteeloButton.secondary(
            onPressed: onPressed,
            label: l10n.guardianLinkExistingAction,
            icon: Icons.person_search_rounded,
            fullWidth: stack,
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildText(l10n),
                const SizedBox(height: AppSpacing.md),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildText(l10n)),
              const SizedBox(width: AppSpacing.md),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildText(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.badge_outlined,
            size: 20,
            color: AppColors.bleuArdoise,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.guardianLinkExistingBannerTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.guardianLinkExistingBannerDescription,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
