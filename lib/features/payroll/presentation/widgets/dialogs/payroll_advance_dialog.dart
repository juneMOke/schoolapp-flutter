import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_advance_preview.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Accorder une avance : l'agent, le montant dans la devise de son contrat,
/// le motif, et l'échéancier. La première échéance tombe sur le mois en
/// cours s'il est encore en brouillon, sinon le suivant. Rend l'avance.
class PayrollAdvanceDialog extends StatefulWidget {
  final PayrollSnapshot snapshot;
  final String today;

  const PayrollAdvanceDialog({
    super.key,
    required this.snapshot,
    required this.today,
  });

  static Future<SalaryAdvanceDraft?> show(
    BuildContext context,
    PayrollAdvanceDialog dialog,
  ) => StaffDialog.show<SalaryAdvanceDraft>(context, dialog);

  @override
  State<PayrollAdvanceDialog> createState() => _PayrollAdvanceDialogState();
}

class _PayrollAdvanceDialogState extends State<PayrollAdvanceDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _detail = TextEditingController();
  String? _memberId;
  PayoutMode _mode = PayoutMode.cash;
  SalaryAdvanceReason? _reason;
  int _installments = 1;
  bool _tried = false;

  late final String _firstMonth = PayrollAdvanceRules.defaultFirstMonth(
    widget.snapshot,
    widget.today,
  );

  @override
  void dispose() {
    _amount.dispose();
    _detail.dispose();
    super.dispose();
  }

  /// La devise du contrat qui paiera l'agent au mois de départ.
  String? get _currency {
    final memberId = _memberId;
    if (memberId == null) return null;
    final contract = PayrollAdvanceRules.contractFor(
      widget.snapshot,
      memberId,
      _firstMonth,
    );
    return contract == null
        ? null
        : PayrollEngine.currencyOf(
            contract,
            fallback: widget.snapshot.settings.firstCurrency,
          );
  }

  SalaryAdvanceDraft? get _draft {
    final memberId = _memberId;
    final currency = _currency;
    final cents = AmountInput.toCents(_amount.text);
    final reason = _reason;
    if (memberId == null ||
        currency == null ||
        cents == null ||
        reason == null) {
      return null;
    }
    return SalaryAdvanceDraft(
      staffMemberId: memberId,
      amount: Money(cents, currency),
      installments: _installments,
      firstMonth: _firstMonth,
      reason: reason,
      reasonDetail: _detail.text,
      mode: _mode,
      grantedOn: widget.today,
    );
  }

  void _submit() {
    final draft = _draft;
    if (draft == null ||
        PayrollAdvanceRules.refusalOf(widget.snapshot, draft) != null) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft;
    final refusal = draft == null
        ? null
        : PayrollAdvanceRules.refusalOf(widget.snapshot, draft);
    final currentMonth = widget.today.substring(0, 7);
    final members = [
      for (final member in widget.snapshot.members)
        if (PayrollAdvanceRules.contractFor(
              widget.snapshot,
              member.id,
              _firstMonth,
            ) !=
            null)
          member,
    ];
    return StaffDialog(
      title: l10n.payrollAdvanceTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloSelectInput<String>(
            label: l10n.payrollAdvanceAgent,
            required: true,
            value: _memberId,
            items: [
              for (final member in members)
                EteeloSelectItem(value: member.id, label: member.fullName),
            ],
            onChanged: (id) => setState(() => _memberId = id),
          ),
          const SizedBox(height: AppSpacing.md),
          EteeloTextInput(
            controller: _amount,
            label: _currency == null
                ? l10n.payrollAdvanceAmount
                : l10n.payrollAdvanceAmountIn(MoneyFormat.symbolOf(_currency!)),
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.payrollAdvanceMode, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          PayrollChoiceChips<PayoutMode>(
            values: const [PayoutMode.cash, PayoutMode.mobileMoney],
            selected: _mode,
            label: (mode) => PayrollLabels.mode(l10n, mode),
            onSelected: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.payrollAdvanceReason, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          PayrollChoiceChips<SalaryAdvanceReason>(
            values: SalaryAdvanceReason.values,
            selected: _reason,
            label: (reason) => PayrollLabels.reason(l10n, reason),
            onSelected: (reason) => setState(() => _reason = reason),
          ),
          if (_reason == SalaryAdvanceReason.other) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloTextInput(
              controller: _detail,
              label: l10n.payrollAdvanceReasonDetail,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.payrollAdvanceInstallments,
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          PayrollChoiceChips<int>(
            values: const [1, 2, 3, PayrollAdvanceRules.maxInstallments],
            selected: _installments,
            label: (n) =>
                n == 1 ? l10n.payrollAdvanceOnce : l10n.payrollAdvanceOver(n),
            onSelected: (n) => setState(() => _installments = n),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.payrollAdvanceFirstMonth(
              PayrollLabels.month(context, _firstMonth),
            ),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_firstMonth != currentMonth)
            Text(
              l10n.payrollAdvanceFirstMonthNext(
                PayrollLabels.month(context, currentMonth),
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          if (draft != null)
            PayrollAdvancePreview(snapshot: widget.snapshot, draft: draft),
          if (_tried && (draft == null || refusal != null)) ...[
            const SizedBox(height: AppSpacing.md),
            PayrollTone.alert.notice(
              refusal != null
                  ? PayrollLabels.rule(l10n, refusal)
                  : _memberId == null
                  ? l10n.payrollAdvanceNeedAgent
                  : _reason == null
                  ? l10n.payrollAdvanceNeedReason
                  : l10n.payrollRuleInvalidAmount,
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
          label: l10n.payrollAdvanceTitle,
          onPressed: _submit,
          fullWidth: false,
        ),
      ],
    );
  }
}
