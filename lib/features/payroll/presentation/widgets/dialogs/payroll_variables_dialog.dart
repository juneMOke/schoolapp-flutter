import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_deductions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_earnings.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_payout.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_net_banner.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les éléments variables d'un agent pour le mois : heures supplémentaires,
/// taux, enfants à charge, jours prestés, prise en charge des enfants, et le
/// versement du mois. Le net se recalcule en direct, par le même moteur.
/// Rend les éléments à enregistrer, ou `null`.
class PayrollVariablesDialog extends StatefulWidget {
  final String name;
  final PayrollLine line;
  final PayrollVariables current;
  final PayrollSettings settings;

  /// Le taux de versement du mois, en %.
  final int monthRate;

  /// La ligne qu'auraient ces éléments.
  final PayrollLine? Function(PayrollVariables variables) preview;

  const PayrollVariablesDialog({
    super.key,
    required this.name,
    required this.line,
    required this.current,
    required this.settings,
    required this.preview,
    this.monthRate = 100,
  });

  static Future<PayrollVariables?> show(
    BuildContext context,
    PayrollVariablesDialog dialog,
  ) => EteeloFormDialog.show<PayrollVariables>(context, dialog);

  @override
  State<PayrollVariablesDialog> createState() => _PayrollVariablesDialogState();
}

class _PayrollVariablesDialogState extends State<PayrollVariablesDialog> {
  late int _overtime = widget.current.overtimeMinutes ?? 0;
  late int _children = widget.current.dependentChildren ?? widget.line.children;
  late final TextEditingController _rate = TextEditingController(
    text: widget.current.overtimeRateInCents == null
        ? ''
        : MoneyFormat.amountOnly(
            Money(widget.current.overtimeRateInCents!, widget.line.currency),
          ),
  );

  late final TextEditingController _childcare = _cents(
    widget.current.childcareInCents,
  );
  late bool _fixed = widget.current.fixedPayoutInCents != null;
  late final TextEditingController _fixedAmount = _cents(
    widget.current.fixedPayoutInCents,
  );
  late final TextEditingController _fixedReason = TextEditingController(
    text: widget.current.fixedPayoutReason ?? '',
  );

  TextEditingController _cents(int? cents) => TextEditingController(
    text: cents == null
        ? ''
        : MoneyFormat.amountOnly(Money(cents, widget.line.currency)),
  );

  @override
  void dispose() {
    _rate.dispose();
    _childcare.dispose();
    _fixedAmount.dispose();
    _fixedReason.dispose();
    super.dispose();
  }

  PayrollVariables get _variables => PayrollVariables(
    staffMemberId: widget.current.staffMemberId,
    overtimeMinutes: widget.line.overtimeAllowed && _overtime > 0
        ? _overtime
        : null,
    overtimeRateInCents: widget.line.overtimeAllowed
        ? AmountInput.toCents(_rate.text)
        : null,
    dependentChildren: _children,
    childcareInCents: AmountInput.toCents(_childcare.text),
    fixedPayoutInCents: _fixed ? AmountInput.toCents(_fixedAmount.text) : null,
    fixedPayoutReason: _fixed ? _fixedReason.text.trim() : null,
  );

  /// Un montant fixe part avec un montant et un motif, ou pas du tout.
  bool get _complete =>
      !_fixed ||
      (AmountInput.toCents(_fixedAmount.text) != null &&
          _fixedReason.text.trim().length >= minPayoutReasonLength);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = widget.line;
    final currency = line.currency;
    final preview = widget.preview(_variables) ?? line;
    final unit = widget.settings.of(currency).childAllowanceInCents;
    String money(int cents) => PayrollLabels.money(cents, currency);
    void submit() {
      if (_complete) Navigator.of(context).pop(_variables);
    }

    return EteeloFormDialog(
      onSubmit: submit,
      eyebrow: widget.name,
      title: l10n.payrollVarsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PayrollAmountRow(l10n.payrollVarsBase, money(preview.baseInCents)),
          const Divider(),
          PayrollVariablesEarnings(
            line: line,
            preview: preview,
            overtime: _overtime,
            children: _children,
            rate: _rate,
            childUnitInCents: unit,
            onOvertime: (value) => setState(() => _overtime = value),
            onChildren: (value) => setState(() => _children = value),
            onChanged: () => setState(() {}),
          ),
          const Divider(),
          PayrollVariablesDeductions(
            preview: preview,
            childcare: _childcare,
            childcareEnabled: widget.settings.childcareEnabled,
            onChanged: () => setState(() {}),
          ),
          if (preview.advances.isNotEmpty) ...[
            const Divider(),
            PayrollAmountRow(
              l10n.payrollVarsAdvances,
              '− ${money(preview.advanceInCents)}',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PayrollNetBanner(
            label: l10n.payrollColNet,
            amount: money(preview.netInCents),
          ),
          const SizedBox(height: AppSpacing.md),
          PayrollVariablesPayout(
            preview: preview,
            monthRate: widget.monthRate,
            fixed: _fixed,
            amount: _fixedAmount,
            reason: _fixedReason,
            onFixed: (fixed) => setState(() => _fixed = fixed),
            onChanged: () => setState(() {}),
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
          onPressed: _complete ? submit : null,
          fullWidth: false,
        ),
      ],
    );
  }
}
