import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_referential.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mode « Retards de paiement » : quels frais (une nature, ou une tranche
/// de cette nature), échus depuis combien de temps. La liste se recalcule à
/// l'envoi : une famille qui a payé entre-temps ne reçoit rien.
class OverdueSelector extends StatelessWidget {
  /// Les anciennetés offertes, en jours (0 = toute créance échue).
  static const thresholds = [0, 30, 60];

  /// La valeur « tous les frais » du sélecteur.
  static const _all = '';

  final AudienceSelections selections;
  final List<OverdueFeeNature> fees;
  final FeeSectionTitlesState titles;
  final void Function(String? feeCode, {String? tariffCode})? onFee;
  final ValueChanged<int>? onDays;

  const OverdueSelector({
    super.key,
    required this.selections,
    required this.fees,
    required this.titles,
    required this.onFee,
    required this.onDays,
  });

  String _natureLabel(AppLocalizations l10n, OverdueFeeNature nature) =>
      titles.titleOf(nature.feeCode) ??
      nature.singleLabel ??
      nature.feeCode.localizedFeeLabel(l10n);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedNature = [
      for (final nature in fees)
        if (nature.feeCode == selections.feeCode) nature,
    ].firstOrNull;
    final onFee = this.onFee;
    final onDays = this.onDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: AppDimensions.communicationOverdueFeeWidth,
              child: EteeloSelectInput<String>(
                label: l10n.communicationOverdueFee,
                value: selections.feeCode ?? _all,
                enabled: onFee != null,
                items: [
                  EteeloSelectItem(
                    value: _all,
                    label: l10n.communicationOverdueAllFees,
                  ),
                  for (final nature in fees)
                    EteeloSelectItem(
                      value: nature.feeCode,
                      label: _natureLabel(l10n, nature),
                    ),
                ],
                onChanged: (code) =>
                    onFee?.call(code == null || code == _all ? null : code),
              ),
            ),
            if (selectedNature != null && selectedNature.tranches.isNotEmpty)
              SizedBox(
                width: AppDimensions.communicationOverdueTrancheWidth,
                child: EteeloSelectInput<String>(
                  label: l10n.communicationOverdueTranche,
                  value: selections.tariffCode ?? _all,
                  enabled: onFee != null,
                  items: [
                    EteeloSelectItem(
                      value: _all,
                      label: l10n.communicationOverdueAllTranches,
                    ),
                    for (final tranche in selectedNature.tranches)
                      EteeloSelectItem(
                        value: tranche.code,
                        label: tranche.label,
                        subtitle: tranche.code,
                      ),
                  ],
                  onChanged: (code) => onFee?.call(
                    selectedNature.feeCode,
                    tariffCode: code == null || code == _all ? null : code,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.communicationOverdueSince,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedTabFilter<int>(
            enabled: onDays != null,
            semanticsLabel: l10n.communicationOverdueSince,
            options: [
              for (final days in thresholds)
                SegmentedTabOption(
                  label: days == 0
                      ? l10n.communicationOverdueAnyAge
                      : l10n.communicationOverdueMoreThan(days),
                  value: days,
                ),
            ],
            selected: thresholds.contains(selections.overdueDays)
                ? selections.overdueDays
                : 0,
            onSelected: (days) => onDays?.call(days),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.communicationOverdueRecomputed,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
