import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La tuile « + Nouvelle caisse », au bout de la grille. Le promoteur seul la
/// voit, et seulement tant qu'une devise n'a pas sa caisse.
class NewRegisterTile extends StatelessWidget {
  final VoidCallback onTap;

  const NewRegisterTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.treasuryNewRegister,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.terreCuiteSoft,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: AppColors.borderStrong, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.treasuryNewRegisterMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: AppSpacing.xl + 2,
                    backgroundColor: AppColors.terreCuite,
                    child: Icon(Icons.add, color: AppColors.textOnDark),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.treasuryNewRegister,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall,
                  ),
                  Text(
                    l10n.treasuryNewRegisterHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La note « Bon à savoir », sur toute la largeur, sous la grille.
class GoodToKnowNote extends StatelessWidget {
  const GoodToKnowNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.financeCrossedSurface,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.terreCuite),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.treasuryGoodToKnow,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
