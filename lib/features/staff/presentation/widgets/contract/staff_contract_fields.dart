import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_day_field.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_synced_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les champs d'un contrat qui dépendent de son statut : mode de paie et
/// montant d'un vacataire, salaire d'un permanent, matricule SECOPE et prime
/// d'un conventionné — puis les dates.
class StaffContractFields extends StatelessWidget {
  final StaffContractDraft draft;
  final Map<StaffContractField, String> errors;
  final ValueChanged<StaffContractDraft Function(StaffContractDraft)> onChanged;

  const StaffContractFields({
    super.key,
    required this.draft,
    required this.errors,
    required this.onChanged,
  });

  static const List<String> currencies = [
    CurrencyCode.usd,
    CurrencyCode.cdf,
    CurrencyCode.eur,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountLabel = switch ((draft.kind, draft.payMode)) {
      (StaffContractKind.vacataire, StaffPayMode.hourly) =>
        l10n.staffFieldHourlyRate,
      (StaffContractKind.vacataire, _) => l10n.staffFieldMonthlyFlat,
      _ => l10n.staffFieldSalary,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draft.isVacataire) ...[
          Text(l10n.staffFieldPayMode, style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          SegmentedTabFilter<String>(
            semanticsLabel: l10n.staffFieldPayMode,
            selected: draft.payMode?.wire ?? '',
            onSelected: (wire) => onChanged(
              (d) => d.copyWith(payMode: () => StaffPayMode.fromWire(wire)),
            ),
            options: [
              SegmentedTabOption(
                label: l10n.staffPayModeHourly,
                value: StaffPayMode.hourly.wire,
              ),
              SegmentedTabOption(
                label: l10n.staffPayModeFlat,
                value: StaffPayMode.monthlyFlat.wire,
              ),
            ],
          ),
          if (errors[StaffContractField.payMode] case final error?)
            Text(
              error,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (draft.needsAmount)
          StaffFieldRow(
            children: [
              StaffSyncedTextInput(
                value: draft.amount,
                label: amountLabel,
                required: true,
                keyboardType: EteeloTextInputType.number,
                capitalization: EteeloTextCapitalization.none,
                errorText: errors[StaffContractField.amount],
                onChanged: (v) => onChanged((d) => d.copyWith(amount: v)),
              ),
              _CurrencyField(
                selected: draft.currency,
                onChanged: (c) => onChanged((d) => d.copyWith(currency: c)),
              ),
            ],
          ),
        if (draft.isConventionne)
          StaffFieldRow(
            children: [
              StaffSyncedTextInput(
                value: draft.secopeNumber,
                label: l10n.staffFieldSecope,
                required: true,
                capitalization: EteeloTextCapitalization.none,
                errorText: errors[StaffContractField.secope],
                onChanged: (v) => onChanged((d) => d.copyWith(secopeNumber: v)),
              ),
              StaffSyncedTextInput(
                value: draft.bonus,
                label: l10n.staffFieldBonus,
                keyboardType: EteeloTextInputType.number,
                capitalization: EteeloTextCapitalization.none,
                errorText: errors[StaffContractField.bonus],
                onChanged: (v) => onChanged((d) => d.copyWith(bonus: v)),
              ),
              _CurrencyField(
                selected: draft.bonusCurrency,
                onChanged: (c) =>
                    onChanged((d) => d.copyWith(bonusCurrency: c)),
              ),
            ],
          ),
        StaffFieldRow(
          children: [
            StaffDayField(
              label: l10n.staffFieldEffectiveFrom,
              value: draft.effectiveFrom,
              required: true,
              errorText: errors[StaffContractField.effectiveFrom],
              onChanged: (v) =>
                  onChanged((d) => d.copyWith(effectiveFrom: () => v)),
            ),
            StaffDayField(
              label: l10n.staffFieldEndsOn,
              value: draft.endsOn,
              errorText: errors[StaffContractField.endsOn],
              onChanged: (v) => onChanged((d) => d.copyWith(endsOn: () => v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrencyField extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CurrencyField({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.staffFieldCurrency, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabFilter<String>(
          semanticsLabel: l10n.staffFieldCurrency,
          selected: selected,
          onSelected: onChanged,
          options: [
            for (final code in StaffContractFields.currencies)
              SegmentedTabOption(label: code, value: code),
          ],
        ),
      ],
    );
  }
}
