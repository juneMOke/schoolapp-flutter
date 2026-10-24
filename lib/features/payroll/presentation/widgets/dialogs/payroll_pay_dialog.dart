import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_proof.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_settlement_band.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tranche_list.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_pay_amount.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_fields.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale : un versement à poser, ou un versement reçu à
/// ouvrir (détail, annulation).
typedef PayrollPayOutcome = ({
  PayrollDisbursementDraft? draft,
  PayrollDisbursement? open,
});

/// Le règlement d'un salaire (B3) : le solde progressif, les versements
/// reçus, puis — s'il reste dû et que le compte peut verser — un montant, un
/// mode, et la preuve que ce mode exige : l'émargement en espèces,
/// l'opérateur, le numéro et la référence en mobile money, la banque et la
/// référence en virement.
class PayrollPayDialog extends StatefulWidget {
  final String name;
  final PayrollMonthView view;
  final PayrollLine line;
  final StaffPayProfile profile;
  final bool canWrite;

  const PayrollPayDialog({
    super.key,
    required this.name,
    required this.view,
    required this.line,
    required this.profile,
    this.canWrite = true,
  });

  static Future<PayrollPayOutcome?> show(
    BuildContext context,
    PayrollPayDialog dialog,
  ) => EteeloFormDialog.show<PayrollPayOutcome>(context, dialog);

  @override
  State<PayrollPayDialog> createState() => _PayrollPayDialogState();
}

class _PayrollPayDialogState extends State<PayrollPayDialog> {
  late final PayrollSettlement _settlement = widget.view.settlementOf(
    widget.line,
  );

  /// Le mode du dernier versement, sinon le mode préféré de l'agent.
  late PayoutMode _mode =
      _settlement.last?.mode ?? widget.profile.preferredMode ?? PayoutMode.cash;
  late MobileMoneyOperator? _operator =
      _settlement.last?.operator ?? widget.profile.operator;
  late final TextEditingController _amount = TextEditingController(
    text: PayrollPayAmount.format(
      PayrollPayAmount.initialOf(_settlement),
      widget.line.currency,
    ),
  );
  bool _signed = false;
  bool _tried = false;
  late final PayrollPayoutControllers _fields = PayrollPayoutControllers(
    phone: widget.profile.payoutPhone,
    bankName: widget.profile.bankName,
    bankAccount: widget.profile.bankAccount,
  );

  @override
  void dispose() {
    _fields.dispose();
    _amount.dispose();
    super.dispose();
  }

  PayrollDisbursementDraft get _draft => PayrollDisbursementDraft(
    month: widget.view.month,
    staffMemberId: widget.line.staffMemberId,
    validationGestureId: widget.view.header?.validationGestureId ?? '',
    amount: Money(AmountInput.toCents(_amount.text) ?? 0, widget.line.currency),
    netInCents: widget.line.netInCents,
    mode: _mode,
    operator: _operator,
    payoutPhone: _fields.phone.text,
    reference: _fields.reference.text,
    bankName: _fields.bankName.text,
    bankAccount: _fields.bankAccount.text,
    signedRegister: _signed,
  );

  void _submit() {
    final refusal = DisbursePayrollUseCase.refusalOf(widget.view, _draft);
    if (refusal != null) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop((draft: _draft, open: null));
  }

  bool get _canPay =>
      widget.canWrite && widget.view.canPay && _settlement.remainingInCents > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refusal = _tried
        ? DisbursePayrollUseCase.refusalOf(widget.view, _draft)
        : null;
    return EteeloFormDialog(
      onSubmit: _canPay ? _submit : null,
      eyebrow: widget.name,
      title: l10n.payrollPayTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PayrollSettlementBand(settlement: _settlement),
          if (_settlement.disbursements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PayrollTrancheList(
              disbursements: _settlement.disbursements,
              onOpen: (d) => Navigator.of(context).pop((draft: null, open: d)),
            ),
          ],
          if (_canPay) ...[
            const SizedBox(height: AppSpacing.lg),
            PayrollPayAmount(
              settlement: _settlement,
              controller: _amount,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            PayrollPayoutProof(
              mode: _mode,
              onMode: (mode) => setState(() => _mode = mode),
              operator: _operator,
              onOperator: (op) => setState(() => _operator = op),
              signed: _signed,
              onSigned: (value) => setState(() => _signed = value),
              controllers: _fields,
              onChanged: () => setState(() {}),
            ),
            if (refusal != null) ...[
              const SizedBox(height: AppSpacing.md),
              PayrollTone.alert.notice(
                PayrollLabels.rule(l10n, refusal),
                icon: Icons.error_outline,
              ),
            ],
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: _canPay ? l10n.payrollCancel : l10n.payrollClose,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        if (_canPay)
          EteeloButton.primary(
            label: l10n.payrollPay,
            icon: PayrollPayoutProof.iconOf(_mode),
            onPressed: _submit,
            fullWidth: false,
          ),
      ],
    );
  }
}
