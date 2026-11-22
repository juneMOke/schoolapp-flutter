import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/exports/recovery_export_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La pastille « Sur {frais} ▾ » de l'en-tête de carte, qui ouvre O1.
class RecoveryFeesPill extends StatelessWidget {
  final String feesLabel;
  final VoidCallback onTap;

  const RecoveryFeesPill({
    super.key,
    required this.feesLabel,
    required this.onTap,
  });

  /// Bord : terre cuite à 50 % dans la bordure.
  static const _borderPercent = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // L'en-tête de carte peut imposer sa largeur : la pastille garde la
    // sienne, calée à droite.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      widthFactor: 1,
      heightFactor: 1,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terreCuite,
          backgroundColor: AppColors.surfaceRaised,
          side: BorderSide(
            color: ColorMix.tint(
              AppColors.border,
              AppColors.terreCuite,
              _borderPercent,
            ),
            width: AppDimensions.recoveryControlBorderWidth,
          ),
          shape: const StadiumBorder(),
          // ⚠️ Le thème donne aux boutons une largeur minimale infinie.
          minimumSize: const Size(0, AppDimensions.treasuryFormatButtonHeight),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.xs,
            AppDimensions.recoverySpace10,
            AppSpacing.xs,
          ),
          textStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppDimensions.recoverySpace7,
          children: [
            const Icon(
              Icons.payments_outlined,
              size: AppDimensions.recoveryIconSize14,
            ),
            Flexible(
              child: Text(
                l10n.recoveryStudentsFeesPill(feesLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: AppDimensions.recoveryIconSize13,
            ),
          ],
        ),
      ),
    );
  }
}

/// Le pied de la liste : « Exporter ces {n} élèves — une section par classe,
/// vert en ordre, rouge à relancer », puis PDF et Excel. [count] est celui de
/// l'onglet : la recherche ne restreint pas l'export (Q5).
class RecoveryStudentsFooter extends StatelessWidget {
  final int count;
  final String title;
  final RecoveryStudentsQuery query;
  final bool enabled;
  final String? disabledReason;

  const RecoveryStudentsFooter({
    super.key,
    required this.count,
    required this.title,
    required this.query,
    required this.enabled,
    required this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppDimensions.recoverySpace10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppDimensions.recoverySpace10,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppDimensions.recoverySpace10,
            children: [
              const Icon(
                Icons.download_outlined,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.terreCuite,
              ),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.recoveryStudentsExportLead(count),
                        style: style.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bleuProfond,
                        ),
                      ),
                      TextSpan(text: l10n.recoveryStudentsExportRest),
                    ],
                  ),
                  style: style,
                ),
              ),
            ],
          ),
          RecoveryExportButtons(
            query: query,
            title: title,
            enabled: enabled,
            disabledReason: disabledReason,
          ),
        ],
      ),
    );
  }
}
