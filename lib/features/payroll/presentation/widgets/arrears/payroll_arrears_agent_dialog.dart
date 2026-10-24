import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_arrears_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_months.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_fields.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_proof.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la fiche : un versement d'arriérés à poser, ou le drapeau
/// « priorité » à lever ou baisser sur tous les mois de l'agent.
typedef PayrollArrearsOutcome = ({
  String currency,
  int amountInCents,
  PayrollDisbursementDraft? proof,
  bool? prioritize,
});

/// La fiche d'arriérés d'un agent : une ligne par mois d'origine, puis —
/// pour l'économe — un montant réparti du plus ancien au plus récent, un
/// versement par mois, et le mode avec sa preuve.
class PayrollArrearsAgentDialog extends StatefulWidget {
  final String name;
  final PayrollSnapshot snapshot;
  final PayrollArrearsAgent agent;
  final StaffPayProfile profile;
  final String currentMonth;
  final bool canWrite;

  const PayrollArrearsAgentDialog({
    super.key,
    required this.name,
    required this.snapshot,
    required this.agent,
    required this.profile,
    required this.currentMonth,
    required this.canWrite,
  });

  static Future<PayrollArrearsOutcome?> show(
    BuildContext context,
    PayrollArrearsAgentDialog dialog,
  ) => EteeloFormDialog.show<PayrollArrearsOutcome>(context, dialog);

  @override
  State<PayrollArrearsAgentDialog> createState() =>
      _PayrollArrearsAgentDialogState();
}

class _PayrollArrearsAgentDialogState extends State<PayrollArrearsAgentDialog> {
  late String _currency = widget.agent.currencies.first;
  late final TextEditingController _amount = TextEditingController(
    text: _format(widget.agent.dueIn(_currency)),
  );
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
    _amount.dispose();
    _fields.dispose();
    super.dispose();
  }

  String _format(int cents) => MoneyFormat.amountOnly(Money(cents, _currency));

  int get _typed => AmountInput.toCents(_amount.text) ?? 0;

  PayrollDisbursementDraft get _proof => PayrollDisbursementDraft(
    month: '',
    staffMemberId: widget.agent.staffMemberId,
    validationGestureId: '',
    amount: Money(_typed, _currency),
    mode: _mode,
    operator: _operator,
    payoutPhone: _fields.phone.text,
    reference: _fields.reference.text,
    bankName: _fields.bankName.text,
    bankAccount: _fields.bankAccount.text,
    signedRegister: _signed,
  );

  void _pay() {
    final drafts = PayPayrollArrearsUseCase.draftsOf(
      widget.snapshot,
      widget.agent,
      currency: _currency,
      amountInCents: _typed,
      proof: _proof,
    );
    if (drafts.isLeft()) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop((
      currency: _currency,
      amountInCents: _typed,
      proof: _proof,
      prioritize: null,
    ));
  }

  void _pick(int cents) => setState(() => _amount.text = _format(cents));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final agent = widget.agent;
    final due = agent.dueIn(_currency);
    final refusal = _tried
        ? PayPayrollArrearsUseCase.draftsOf(
            widget.snapshot,
            agent,
            currency: _currency,
            amountInCents: _typed,
            proof: _proof,
          ).fold((rule) => rule, (_) => null)
        : null;
    final oldest = agent.months.firstWhere((a) => a.currency == _currency);
    return EteeloFormDialog(
      onSubmit: widget.canWrite ? _pay : null,
      eyebrow: l10n.payrollArrearsTitle,
      title: l10n.payrollArrearsAgentTitle(
        widget.name,
        PayrollLabels.money(due, _currency),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PayrollArrearsMonths(
            agent: agent,
            currentMonth: widget.currentMonth,
            split: widget.canWrite
                ? PayrollArrears.split(agent, _currency, _typed)
                : const [],
          ),
          if (widget.canWrite && due > 0) ...[
            const Divider(),
            if (agent.currencies.length > 1)
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final currency in agent.currencies)
                    EteeloFilterChip(
                      label: currency,
                      selected: currency == _currency,
                      color: AppColors.bleuArdoise,
                      soft: AppColors.bleuArdoiseSoft,
                      ink: AppColors.bleuProfond,
                      onTap: () => setState(() {
                        _currency = currency;
                        _amount.text = _format(agent.dueIn(currency));
                      }),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            EteeloTextInput(
              controller: _amount,
              label: l10n.payrollPayAmount(_currency),
              required: true,
              keyboardType: EteeloTextInputType.number,
              capitalization: EteeloTextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (label, cents) in [
                  (l10n.payrollArrearsPayAll, due),
                  (l10n.payrollArrearsPayOldest, oldest.dueInCents),
                  (l10n.payrollPayShare(50), due ~/ 2),
                ])
                  if (cents > 0)
                    EteeloFilterChip(
                      label: label,
                      selected: _typed == cents,
                      color: AppColors.terreCuite,
                      soft: AppColors.terreCuiteSoft,
                      ink: AppColors.terreCuiteDark,
                      onTap: () => _pick(cents),
                    ),
              ],
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
      leading: widget.canWrite
          ? EteeloButton.ghost(
              label: agent.prioritized
                  ? l10n.payrollArrearsUnprioritize
                  : l10n.payrollArrearsPrioritize,
              icon: Icons.flag_outlined,
              onPressed: () => Navigator.of(context).pop((
                currency: _currency,
                amountInCents: 0,
                proof: null,
                prioritize: !agent.prioritized,
              )),
              fullWidth: false,
            )
          : null,
      actions: [
        EteeloButton.ghost(
          label: widget.canWrite ? l10n.payrollCancel : l10n.payrollClose,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        if (widget.canWrite && due > 0)
          EteeloButton.primary(
            label: l10n.payrollArrearsPay(
              PayrollLabels.money(_typed, _currency),
            ),
            icon: PayrollPayoutProof.iconOf(_mode),
            onPressed: _pay,
            fullWidth: false,
          ),
      ],
    );
  }
}
