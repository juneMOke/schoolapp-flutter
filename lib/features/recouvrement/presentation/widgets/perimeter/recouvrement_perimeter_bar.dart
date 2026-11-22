import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre « Quels frais analyser ? » en tête de page (`RecFraisBar`) — le
/// sujet de toute la page, partagée par le tableau de bord et le contrôle.
///
/// À gauche le choix des frais ([fees]), à droite le périmètre ou la classe
/// ([scope]) ; sous 600 dp reçus, le second passe sous le premier (spec v2,
/// §4.6 A). [footer] porte la ligne « {n} élèves · tous les chiffres… ».
class RecouvrementPerimeterBar extends StatelessWidget {
  final Widget fees;
  final Widget scope;
  final Widget? footer;

  const RecouvrementPerimeterBar({
    super.key,
    required this.fees,
    required this.scope,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        final feesBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: AppDimensions.recouvrementPerimeterBadge,
                  height: AppDimensions.recouvrementPerimeterBadge,
                  decoration: const BoxDecoration(
                    color: AppColors.terreCuite,
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        AppDimensions.recouvrementPerimeterBadgeRadius,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.toll_outlined,
                    size: AppDimensions.recouvrementPerimeterBadgeIconSize,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.recouvrementFeesQuestion,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.bleuProfond,
                          ),
                        ),
                        TextSpan(
                          text: '  ${l10n.recouvrementFeesOneOrMore}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            fees,
          ],
        );

        return Container(
          padding: narrow
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gridGap,
                  vertical: AppSpacing.md,
                )
              : const EdgeInsets.symmetric(
                  horizontal: AppDimensions.recoverySpace18,
                  vertical: AppSpacing.gridGap,
                ),
          decoration: BoxDecoration(
            gradient: RecouvrementV2Tones.perimeterGradient,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppDimensions.recouvrementPerimeterBarRadius),
            ),
            border: Border.all(
              color: RecouvrementV2Tones.perimeterBorder,
              width: AppDimensions.recouvrementPerimeterBarBorderWidth,
            ),
            boxShadow: RecouvrementV2Tones.perimeterShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                feesBlock,
                const SizedBox(height: AppSpacing.md),
                scope,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: feesBlock),
                    const SizedBox(width: AppSpacing.gridGap),
                    SizedBox(
                      width: AppDimensions.recouvrementScopeSelectWidth,
                      child: scope,
                    ),
                  ],
                ),
              if (footer != null) ...[
                const SizedBox(height: AppDimensions.recoverySpace10),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}
