import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les chiffres d'une classe sur un frais (O2) : le taux en pavé sombre
/// (deux colonnes), puis reste dû, rien payé, partiel, soldé.
///
/// Les montants sont ceux de la ligne du classement — une devise ; les
/// comptes, ceux de la réponse de la liste ([counts]).
class RecoveryClassSheetFigures extends StatelessWidget {
  final RecoveryClassFeeRow row;
  final RecoverySituationCounts counts;

  const RecoveryClassSheetFigures({
    super.key,
    required this.row,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = row.ratePercent;
    final tiles = <Widget>[
      _SmallTile(
        label: l10n.recoveryClassSheetOutstanding,
        value: MoneyFormat.compact(row.outstanding),
        status: StudentChargeStatus.due,
      ),
      _SmallTile(
        label: l10n.recoveryClassSheetNoPayment,
        value: '${counts.noPayment}',
        status: StudentChargeStatus.due,
      ),
      _SmallTile(
        label: l10n.recoveryClassSheetPartial,
        value: '${counts.partial}',
        status: StudentChargeStatus.partial,
      ),
      _SmallTile(
        label: l10n.recoveryClassSheetSettled,
        value: '${counts.settled}',
        status: StudentChargeStatus.paid,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final perRow =
            ((constraints.maxWidth + gap) /
                    (AppDimensions.recoveryClassSheetTileMinWidth + gap))
                .floor()
                .clamp(2, 6);
        final cell = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        final hero = _RateTile(
          rateText: rate == null
              ? l10n.recoveryClassesRateNone
              : l10n.recoveryClassesRate(rate),
          percent: rate ?? 0,
          dueText: l10n.recoveryClassSheetDueOf(MoneyFormat.compact(row.due)),
        );
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(width: cell * 2 + gap, child: hero),
            for (final t in tiles) SizedBox(width: cell, child: t),
          ],
        );
      },
    );
  }
}

class _RateTile extends StatelessWidget {
  final String rateText;
  final int percent;
  final String dueText;

  const _RateTile({
    required this.rateText,
    required this.percent,
    required this.dueText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gridGap,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.gridGap)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.treasuryUsdDeep,
            AppColors.treasuryUsdMid,
            AppColors.treasuryUsdEnd,
          ],
          stops: [0, 0.7, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.recoveryClassSheetRate.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDark,
              letterSpacing: AppTypography.capsLetterSpacing,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppDimensions.recoverySpace10,
            children: [
              Text(
                rateText,
                style: AppTypography.headlineLarge.copyWith(
                  fontSize: AppDimensions.recoveryClassSheetRateSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceRaised,
                ),
              ),
              Text(
                dueText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RecoveryRateBar(
            percent: percent,
            color: AppColors.orDoux,
            track: AppColors.surfaceRaised.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  final String label;
  final String value;
  final StudentChargeStatus status;

  const _SmallTile({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (ink, soft) = RecouvrementV2Tones.situation(status);
    final text = status == StudentChargeStatus.partial
        ? AppColors.feeStatusPartialInk
        : ink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppDimensions.recoverySpace10,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.gridGap),
        ),
        border: Border.all(color: ColorMix.tint(soft, ink, 22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: text,
              letterSpacing: AppTypography.capsLetterSpacing,
            ),
          ),
          const SizedBox(height: AppDimensions.recoverySpace2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                fontSize: AppDimensions.recoveryClassSheetCountSize,
                fontWeight: FontWeight.w700,
                color: text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
