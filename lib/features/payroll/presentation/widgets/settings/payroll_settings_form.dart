import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_inputs.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le barème en quatre cartes : le mois de salaire, les retenues légales, les
/// heures supplémentaires, les allocations familiales. [readOnly] : l'économe
/// consulte, champs grisés.
class PayrollSettingsForm extends StatelessWidget {
  final PayrollSettingsDraft draft;
  final bool readOnly;

  const PayrollSettingsForm({
    super.key,
    required this.draft,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget field(
      TextEditingController controller,
      String label,
      PayrollSettingsFieldError? fieldError,
    ) => PayrollSettingsNumberField(
      controller: controller,
      label: label,
      error: fieldError,
      readOnly: readOnly,
    );
    Widget amount(String currency, PayrollCurrencyField which, String label) =>
        field(
          draft.amounts[currency]![which]!,
          l10n.payrollSettingsInCurrency(label, currency),
          draft.errorOfAmount(currency, which),
        );
    final currencies = draft.currencies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollSettingsCard(
          title: l10n.payrollSettingsMonthTitle,
          subtitle: l10n.payrollSettingsMonthSubtitle,
          icon: Icons.calendar_month_outlined,
          fields: [
            field(
              draft.hours,
              l10n.payrollSettingsDivisor,
              draft.errorOfHours(),
            ),
            field(
              draft.days,
              l10n.payrollSettingsWorkDays,
              draft.errorOfDays(),
            ),
          ],
          footer: PayrollSettingsToggle(
            label: l10n.payrollSettingsAbsenceDeduction,
            selected: draft.absence,
            onTap: readOnly ? null : draft.toggleAbsence,
          ),
        ),
        PayrollSettingsCard(
          title: l10n.payrollSettingsLegalTitle,
          subtitle: l10n.payrollSettingsLegalSubtitle,
          icon: Icons.account_balance_outlined,
          fields: [
            for (final currency in currencies) ...[
              amount(
                currency,
                PayrollCurrencyField.ipr,
                l10n.payrollSettingsIpr,
              ),
              field(
                draft.cnss[currency]!,
                l10n.payrollSettingsInCurrency(
                  l10n.payrollSettingsCnss,
                  currency,
                ),
                draft.errorOfCnss(currency),
              ),
            ],
          ],
        ),
        PayrollSettingsCard(
          title: l10n.payrollSettingsOvertimeTitle,
          subtitle: l10n.payrollSettingsOvertimeSubtitle,
          icon: Icons.more_time_outlined,
          fields: [
            field(
              draft.premium,
              l10n.payrollSettingsMultiplier,
              draft.errorOfPremium(),
            ),
            for (final currency in currencies) ...[
              amount(
                currency,
                PayrollCurrencyField.defaultRate,
                l10n.payrollSettingsDefaultRate,
              ),
              amount(
                currency,
                PayrollCurrencyField.step,
                l10n.payrollSettingsStep,
              ),
            ],
          ],
        ),
        PayrollSettingsCard(
          title: l10n.payrollSettingsAllowanceTitle,
          subtitle: l10n.payrollSettingsAllowanceSubtitle,
          icon: Icons.family_restroom_outlined,
          fields: [
            for (final currency in currencies)
              amount(
                currency,
                PayrollCurrencyField.allowance,
                l10n.payrollSettingsAllowance,
              ),
          ],
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payrollSettingsEligible,
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final kind in StaffContractKind.values)
                    EteeloFilterChip(
                      label: StaffLabels.contract(l10n, kind),
                      selected: draft.eligible.contains(kind),
                      color: StaffContractTone.of(kind).color,
                      soft: StaffContractTone.of(kind).soft,
                      ink: StaffContractTone.of(kind).ink,
                      onTap: readOnly ? null : () => draft.toggleEligible(kind),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
