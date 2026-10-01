import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les réglages de paie de l'école : heures d'un mois, majoration, et par
/// devise l'allocation par enfant, le taux par défaut et son pas. Rend les
/// réglages saisis, ou `null`.
class PayrollSettingsDialog extends StatefulWidget {
  final PayrollSettings settings;

  const PayrollSettingsDialog({super.key, required this.settings});

  static Future<PayrollSettings?> show(
    BuildContext context,
    PayrollSettings settings,
  ) => EteeloFormDialog.show<PayrollSettings>(
    context,
    PayrollSettingsDialog(settings: settings),
  );

  @override
  State<PayrollSettingsDialog> createState() => _PayrollSettingsDialogState();
}

class _PayrollSettingsDialogState extends State<PayrollSettingsDialog> {
  static const List<String> _currencies = [CurrencyCode.usd, CurrencyCode.cdf];

  late final TextEditingController _divisor = TextEditingController(
    text: '${widget.settings.monthlyHoursDivisor}',
  );
  late final TextEditingController _premium = TextEditingController(
    text: '${(widget.settings.overtimeMultiplierPermille - 1000) ~/ 10}',
  );
  late final Map<String, List<TextEditingController>> _perCurrency = {
    for (final currency in _currencies)
      currency: [
        for (final cents in _amountsOf(widget.settings.of(currency)))
          TextEditingController(
            text: MoneyFormat.amountOnly(Money(cents, currency)),
          ),
      ],
  };
  late final Set<StaffContractKind> _eligible = {
    ...widget.settings.allowanceEligibleKinds,
  };

  static List<int> _amountsOf(PayrollCurrencySettings settings) => [
    settings.childAllowanceInCents,
    settings.defaultOvertimeRateInCents,
    settings.overtimeRateStepInCents,
  ];

  @override
  void dispose() {
    _divisor.dispose();
    _premium.dispose();
    for (final controllers in _perCurrency.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  PayrollSettings get _settings => widget.settings.copyWith(
    monthlyHoursDivisor: int.tryParse(_divisor.text.trim()) ?? 0,
    overtimeMultiplierPermille:
        1000 + (int.tryParse(_premium.text.trim()) ?? -1000) * 10,
    allowanceEligibleKinds: _eligible,
    byCurrency: {
      for (final entry in _perCurrency.entries)
        entry.key: PayrollCurrencySettings(
          childAllowanceInCents: _cents(entry.value[0]),
          defaultOvertimeRateInCents: _cents(entry.value[1]),
          overtimeRateStepInCents: _cents(entry.value[2]),
        ),
    },
  );

  /// Un champ vidé vaut zéro : rien n'est inventé.
  static int _cents(TextEditingController controller) =>
      AmountInput.toCents(controller.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget number(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: EteeloTextInput(
        controller: c,
        label: label,
        keyboardType: EteeloTextInputType.number,
        capitalization: EteeloTextCapitalization.none,
      ),
    );
    return EteeloFormDialog(
      title: l10n.payrollSettingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          number(_divisor, l10n.payrollSettingsDivisor),
          number(_premium, l10n.payrollSettingsMultiplier),
          for (final currency in _currencies) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.payrollSettingsCurrency(currency),
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            number(_perCurrency[currency]![0], l10n.payrollSettingsAllowance),
            number(_perCurrency[currency]![1], l10n.payrollSettingsDefaultRate),
            number(_perCurrency[currency]![2], l10n.payrollSettingsStep),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.payrollSettingsEligible, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final kind in StaffContractKind.values)
                EteeloFilterChip(
                  label: StaffLabels.contract(l10n, kind),
                  selected: _eligible.contains(kind),
                  color: StaffContractTone.of(kind).color,
                  soft: StaffContractTone.of(kind).soft,
                  ink: StaffContractTone.of(kind).ink,
                  onTap: () => setState(
                    () => _eligible.contains(kind)
                        ? _eligible.remove(kind)
                        : _eligible.add(kind),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.payrollSave,
          onPressed: () => Navigator.of(context).pop(_settings),
          fullWidth: false,
        ),
      ],
    );
  }
}
