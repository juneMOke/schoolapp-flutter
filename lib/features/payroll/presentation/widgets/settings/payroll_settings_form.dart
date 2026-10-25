import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';
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
    String? error(PayrollSettingsFieldError? error) => switch (error) {
      null => null,
      PayrollSettingsOutOfRange(:final range) => l10n.payrollSettingsErrorRange(
        range.min,
        range.max,
      ),
      PayrollSettingsBadAmount() => l10n.payrollSettingsErrorAmount,
      PayrollSettingsBelowMin() => l10n.payrollSettingsErrorStep,
    };
    Widget field(
      TextEditingController controller,
      String label,
      PayrollSettingsFieldError? fieldError,
    ) => EteeloTextInput(
      controller: controller,
      label: label,
      keyboardType: EteeloTextInputType.number,
      capitalization: EteeloTextCapitalization.none,
      enabled: !readOnly,
      errorText: error(fieldError),
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
        _Card(
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
          footer: _Toggle(
            label: l10n.payrollSettingsAbsenceDeduction,
            selected: draft.absence,
            onTap: readOnly ? null : draft.toggleAbsence,
          ),
        ),
        _Card(
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
        _Card(
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
        _Card(
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

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> fields;
  final Widget? footer;

  const _Card({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: BiToneSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigurationFieldGrid(children: fields),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _Toggle({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: EteeloFilterChip(
      label: label,
      selected: selected,
      color: AppColors.terreCuite,
      soft: AppColors.terreCuiteSoft,
      ink: AppColors.terreCuiteDark,
      onTap: onTap,
    ),
  );
}
