import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_custom.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_deductions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_earnings.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_payout.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_net_banner.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale rend : les éléments, et les saisies qui ont changé.
class PayrollVariablesResult {
  final PayrollVariables variables;
  final List<PayrollDeductionEntry> entries;

  const PayrollVariablesResult(this.variables, this.entries);
}

/// Les éléments variables d'un agent pour le mois : heures supplémentaires,
/// taux, enfants à charge, jours prestés, prise en charge des enfants, et le
/// versement du mois, et les rubriques de l'école. Le net se recalcule en
/// direct, par le même moteur. Rend ce qu'il faut enregistrer, ou `null`.
class PayrollVariablesDialog extends StatefulWidget {
  final String name;
  final PayrollLine line;
  final PayrollVariables current;
  final PayrollSettings settings;

  /// Le taux de versement du mois, en %.
  final int monthRate;

  /// Le catalogue de l'école, archivées comprises, et les saisies de l'agent.
  final List<PayrollDeductionType> deductionTypes;
  final List<PayrollDeductionEntry> entries;

  /// La ligne qu'auraient ces éléments et ces saisies.
  final PayrollLine? Function(
    PayrollVariables variables,
    List<PayrollDeductionEntry> entries,
  )
  preview;

  const PayrollVariablesDialog({
    super.key,
    required this.name,
    required this.line,
    required this.current,
    required this.settings,
    required this.preview,
    this.monthRate = 100,
    this.deductionTypes = const [],
    this.entries = const [],
  });

  static Future<PayrollVariablesResult?> show(
    BuildContext context,
    PayrollVariablesDialog dialog,
  ) => EteeloFormDialog.show<PayrollVariablesResult>(context, dialog);

  @override
  State<PayrollVariablesDialog> createState() => _PayrollVariablesDialogState();
}

class _PayrollVariablesDialogState extends State<PayrollVariablesDialog> {
  late final List<PayrollCustomField> _custom = [
    for (final type in widget.deductionTypes)
      if (_entryOf(type) case final entry
          when !type.archived || (entry?.amountInCents ?? 0) > 0)
        PayrollCustomField.of(type, entry, widget.line.currency),
  ];

  PayrollDeductionEntry? _entryOf(PayrollDeductionType type) => widget.entries
      .where((entry) => entry.deductionTypeId == type.id)
      .firstOrNull;

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
    for (final field in _custom) {
      field.controller.dispose();
    }
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

  String get _memberId => widget.current.staffMemberId;

  /// Les saisies de l'aperçu : celles que la modale ne montre pas restent.
  List<PayrollDeductionEntry> get _previewEntries {
    final shown = {for (final field in _custom) field.type.id};
    return [
      for (final entry in widget.entries)
        if (!shown.contains(entry.deductionTypeId) &&
            entry.syncState != RecordSyncState.failed)
          entry,
      for (final field in _custom) ?field.preview(_memberId),
    ];
  }

  PayrollVariablesResult get _result => PayrollVariablesResult(_variables, [
    for (final field in _custom) ?field.changed(_memberId),
  ]);

  /// Un montant fixe part avec un montant et un motif, ou pas du tout ; un
  /// montant de rubrique illisible ne part pas.
  bool get _complete =>
      (!_fixed ||
          (AmountInput.toCents(_fixedAmount.text) != null &&
              _fixedReason.text.trim().length >= minPayoutReasonLength)) &&
      !_custom.any((field) => field.invalid);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = widget.line;
    final currency = line.currency;
    final preview = widget.preview(_variables, _previewEntries) ?? line;
    final unit = widget.settings.of(currency).childAllowanceInCents;
    String money(int cents) => PayrollLabels.money(cents, currency);
    void submit() {
      if (_complete) Navigator.of(context).pop(_result);
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
          if (_custom.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PayrollVariablesCustom(
              fields: _custom,
              preview: preview,
              onChanged: () => setState(() {}),
            ),
          ],
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
