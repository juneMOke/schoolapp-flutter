import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_draft.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_inputs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Paie ▸ Configuration — les cinq retenues du modèle, une à une. Ce que
/// l'école coupe disparaît de la saisie et du bulletin. La PC/E suit le barème
/// élargi : montrée seulement quand le serveur la sert.
class PayrollModelDeductionsCard extends StatelessWidget {
  final PayrollSettingsDraft draft;
  final bool readOnly;

  const PayrollModelDeductionsCard({
    super.key,
    required this.draft,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget toggle(String label, bool selected, VoidCallback onTap) =>
        PayrollSettingsToggle(
          label: label,
          selected: selected,
          onTap: readOnly ? null : onTap,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: BiToneSectionCard(
        title: l10n.payrollSettingsModelTitle,
        subtitle: l10n.payrollSettingsModelSubtitle,
        icon: Icons.tune_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toggle(
              l10n.payrollSettingsLegalToggle,
              draft.legal,
              draft.toggleLegal,
            ),
            toggle(
              l10n.payrollSettingsAbsenceDeduction,
              draft.absence,
              draft.toggleAbsence,
            ),
            toggle(
              l10n.payrollSettingsAdvancesToggle,
              draft.advances,
              draft.toggleAdvances,
            ),
            toggle(
              l10n.payrollSettingsLoansToggle,
              draft.loans,
              draft.toggleLoans,
            ),
            if (draft.showsWide)
              toggle(
                l10n.payrollSettingsChildcare,
                draft.wide.childcare,
                draft.toggleChildcare,
              ),
          ],
        ),
      ),
    );
  }
}
