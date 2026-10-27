import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_inputs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cartes du barème élargi (spec CFG 1, servi par le back en Q8) : PC/E
/// et avances, charges patronales, bulletin. Absentes tant que le serveur ne
/// les sert pas : la tablette n'impose pas des réglages qu'il ne connaît pas.
class PayrollWideSettingsCards extends StatelessWidget {
  final PayrollSettingsDraft draft;
  final bool readOnly;

  const PayrollWideSettingsCards({
    super.key,
    required this.draft,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = draft.wide;
    Widget number(
      TextEditingController controller,
      String label,
      PayrollSettingsFieldError? error,
    ) => PayrollSettingsNumberField(
      controller: controller,
      label: label,
      error: error,
      readOnly: readOnly,
    );
    Widget caption(
      TextEditingController controller,
      String fieldLabel,
      String hint,
    ) => EteeloTextInput(
      controller: controller,
      label: fieldLabel,
      placeholder: hint,
      capitalization: EteeloTextCapitalization.sentence,
      enabled: !readOnly,
      errorText: payrollSettingsErrorText(l10n, wide.errorOfLabel(controller)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollSettingsCard(
          title: l10n.payrollSettingsAdvancesTitle,
          subtitle: l10n.payrollSettingsAdvancesSubtitle,
          icon: Icons.volunteer_activism_outlined,
          fields: [
            number(
              wide.advanceMax,
              l10n.payrollSettingsAdvanceMax,
              wide.errorOfAdvanceMax(),
            ),
            number(
              wide.loanMax,
              l10n.payrollSettingsLoanMax,
              wide.errorOfLoanMax(),
            ),
          ],
          footer: PayrollSettingsToggle(
            label: l10n.payrollSettingsChildcare,
            selected: wide.childcare,
            onTap: readOnly ? null : draft.toggleChildcare,
          ),
        ),
        PayrollSettingsCard(
          title: l10n.payrollSettingsEmployerTitle,
          subtitle: l10n.payrollSettingsEmployerSubtitle,
          icon: Icons.business_outlined,
          fields: [
            number(
              wide.cnssEmployer,
              l10n.payrollSettingsCnssEmployer,
              wide.errorOfPermille(wide.cnssEmployer),
            ),
            number(
              wide.inpp,
              l10n.payrollSettingsInpp,
              wide.errorOfPermille(wide.inpp),
            ),
            number(
              wide.onem,
              l10n.payrollSettingsOnem,
              wide.errorOfPermille(wide.onem),
            ),
          ],
        ),
        PayrollSettingsCard(
          title: l10n.payrollSettingsPayslipTitle,
          subtitle: l10n.payrollSettingsPayslipSubtitle,
          icon: Icons.draw_outlined,
          fields: [
            caption(
              wide.beneficiaryLabel,
              l10n.payrollSettingsSignBeneficiary,
              l10n.payrollPayslipSignAgent,
            ),
            caption(
              wide.directorLabel,
              l10n.payrollSettingsSignDirector,
              l10n.payrollPayslipSignHead,
            ),
            caption(
              wide.cashierLabel,
              l10n.payrollSettingsSignCashier,
              l10n.payrollPayslipSignBursar,
            ),
          ],
        ),
      ],
    );
  }
}
