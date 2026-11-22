import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Situation recherchée** (spec v2, §4.6 B ; maquette `RecControleTab`) :
/// cinq segments de 48 dp — icône, mot, compteur —, exclusifs, qui filtrent
/// à l'instant. Le cinquième, « A payé au moins… », ouvre son champ de
/// montant dans le segment même ; il est **désactivé** quand la classe porte
/// deux devises, avec sa raison en info-bulle.
class FeeControlSituationCard extends StatelessWidget {
  final FeeControlPaymentFilter selected;
  final FeeControlBreakdown counts;

  /// L'unique devise de la classe, ou `null` (mixte).
  final String? currency;
  final bool atLeastAvailable;
  final TextEditingController thresholdController;
  final ValueChanged<FeeControlPaymentFilter> onChanged;
  final ValueChanged<String> onThresholdChanged;

  const FeeControlSituationCard({
    super.key,
    required this.selected,
    required this.counts,
    required this.currency,
    required this.atLeastAvailable,
    required this.thresholdController,
    required this.onChanged,
    required this.onThresholdChanged,
  });

  static const order = [
    FeeControlPaymentFilter.all,
    FeeControlPaymentFilter.none,
    FeeControlPaymentFilter.partial,
    FeeControlPaymentFilter.settled,
    FeeControlPaymentFilter.threshold,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gridGap,
        AppSpacing.md,
        AppSpacing.gridGap,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feeControlSituationLabel.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: AppDimensions.recoveryOverlineLetterSpacing,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: l10n.feeControlSituationLabel,
            child: Wrap(
              spacing: AppDimensions.recoverySpace6,
              runSpacing: AppDimensions.recoverySpace6,
              children: [for (final filter in order) _segment(context, filter)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, FeeControlPaymentFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    final on = selected == filter;
    final disabled = filter.needsThreshold && !atLeastAvailable;
    final (color, soft) = RecouvrementV2Tones.situation(filter.targetStatus);
    final count = switch (filter) {
      FeeControlPaymentFilter.all => counts.total,
      FeeControlPaymentFilter.none => counts.none,
      FeeControlPaymentFilter.partial => counts.partial,
      FeeControlPaymentFilter.settled => counts.settled,
      FeeControlPaymentFilter.threshold => null,
    };
    final icon = switch (filter) {
      FeeControlPaymentFilter.all => Icons.people_alt_outlined,
      FeeControlPaymentFilter.none => Icons.cancel_outlined,
      FeeControlPaymentFilter.partial => Icons.schedule,
      FeeControlPaymentFilter.settled => Icons.check_circle_outline,
      FeeControlPaymentFilter.threshold => Icons.toll_outlined,
    };
    final ink = on ? color : AppColors.textSecondary;

    final segment = Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      enabled: !disabled,
      button: true,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: on ? soft : AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brPill,
            side: BorderSide(
              color: on ? color : AppColors.border,
              width: on
                  ? AppDimensions.selectedTileBorderWidth
                  : AppDimensions.tileBorderWidth,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: disabled ? null : () => onChanged(filter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.recouvrementSegmentHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppDimensions.recoverySpace13,
                  right: filter.needsThreshold && on
                      ? AppSpacing.xs
                      : AppDimensions.recoverySpace13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: AppDimensions.recoveryIconSize14,
                      color: ink,
                    ),
                    const SizedBox(width: AppDimensions.recoverySpace7),
                    Flexible(
                      child: Text(
                        FeeControlPageHelpers.paymentFilterLabel(filter, l10n),
                        style: AppTypography.labelLarge.copyWith(color: ink),
                      ),
                    ),
                    if (filter.needsThreshold && on) ...[
                      const SizedBox(width: AppDimensions.recoverySpace7),
                      _AmountInput(
                        controller: thresholdController,
                        currency: currency,
                        label: l10n.recouvrementThresholdLabel,
                        onChanged: onThresholdChanged,
                      ),
                    ],
                    if (count != null) ...[
                      const SizedBox(width: AppDimensions.recoverySpace7),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth:
                              AppDimensions.recouvrementSegmentCountMinWidth,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.recoverySpace6,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.surfaceRaised
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: on ? color : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return disabled
        ? Tooltip(message: l10n.recouvrementAtLeastMixed, child: segment)
        : segment;
  }
}

/// Le montant saisi dans le segment (`RecAmountInput`) : chiffres seuls,
/// alignés à droite, symbole de la devise à côté.
class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? currency;
  final String label;
  final ValueChanged<String> onChanged;

  const _AmountInput({
    required this.controller,
    required this.currency,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.recouvrementAmountInputHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.recoverySpace10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.recouvrementAmountInputRadius),
        ),
        border: Border.all(
          color: AppColors.bleuArdoise,
          width: AppDimensions.recoveryControlBorderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppDimensions.recouvrementAmountInputWidth,
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              onChanged: onChanged,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.bleuProfond,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: currency == 'CDF'
                    ? AppLocalizations.of(context)!.recouvrementAmountHintFrancs
                    : AppLocalizations.of(
                        context,
                      )!.recouvrementAmountHintDollars,
                semanticCounterText: label,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            currency == null ? '' : MoneyFormat.symbolOf(currency!),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
