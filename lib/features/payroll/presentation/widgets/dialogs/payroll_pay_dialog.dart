import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_net_banner.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_fields.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Verser un salaire : le net figé, un mode, et la preuve que ce mode exige —
/// l'émargement en espèces, l'opérateur, le numéro et la référence en mobile
/// money, la banque et la référence en virement. Rend le versement saisi.
class PayrollPayDialog extends StatefulWidget {
  final String name;
  final PayrollMonthView view;
  final PayrollLine line;
  final StaffPayProfile profile;

  const PayrollPayDialog({
    super.key,
    required this.name,
    required this.view,
    required this.line,
    required this.profile,
  });

  static Future<PayrollDisbursementDraft?> show(
    BuildContext context,
    PayrollPayDialog dialog,
  ) => StaffDialog.show<PayrollDisbursementDraft>(context, dialog);

  @override
  State<PayrollPayDialog> createState() => _PayrollPayDialogState();
}

class _PayrollPayDialogState extends State<PayrollPayDialog> {
  late PayoutMode _mode = widget.profile.preferredMode ?? PayoutMode.cash;
  late MobileMoneyOperator? _operator = widget.profile.operator;
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
    super.dispose();
  }

  PayrollDisbursementDraft get _draft => PayrollDisbursementDraft(
    month: widget.view.month,
    staffMemberId: widget.line.staffMemberId,
    validationGestureId: widget.view.header?.validationGestureId ?? '',
    amount: Money(widget.line.netInCents, widget.line.currency),
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
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refusal = _tried
        ? DisbursePayrollUseCase.refusalOf(widget.view, _draft)
        : null;
    return StaffDialog(
      eyebrow: widget.name,
      title: l10n.payrollPayTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PayrollNetBanner(
            label: l10n.payrollPayNet,
            amount: PayrollLabels.money(
              widget.line.netInCents,
              widget.line.currency,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PayrollChoiceChips<PayoutMode>(
            values: PayoutMode.values,
            selected: _mode,
            label: (mode) => PayrollLabels.mode(l10n, mode),
            icon: _icon,
            onSelected: (mode) => setState(() => _mode = mode),
          ),
          if (_mode == PayoutMode.cash) ...[
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _signed,
              onChanged: (value) => setState(() => _signed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.payrollPaySigned),
              subtitle: Text(
                l10n.payrollPayCashHelp,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          PayrollPayoutFields(
            mode: _mode,
            operator: _operator,
            onOperator: (op) => setState(() => _operator = op),
            controllers: _fields,
            withReference: true,
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
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.payrollPay,
          icon: _icon(_mode),
          onPressed: _submit,
          fullWidth: false,
        ),
      ],
    );
  }

  static IconData _icon(PayoutMode mode) => switch (mode) {
    PayoutMode.cash => Icons.payments_outlined,
    PayoutMode.mobileMoney => Icons.phone_android,
    PayoutMode.bank => Icons.account_balance_outlined,
  };
}
