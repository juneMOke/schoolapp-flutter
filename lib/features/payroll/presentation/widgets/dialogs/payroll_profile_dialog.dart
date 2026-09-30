import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_fields.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_stepper.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le profil de paie d'un agent : enfants à charge, mode préféré et ses
/// coordonnées — ce qui préremplit ses éléments variables et son versement.
class PayrollProfileDialog extends StatefulWidget {
  final String name;
  final StaffPayProfile profile;

  const PayrollProfileDialog({
    super.key,
    required this.name,
    required this.profile,
  });

  static Future<StaffPayProfile?> show(
    BuildContext context,
    PayrollProfileDialog dialog,
  ) => StaffDialog.show<StaffPayProfile>(context, dialog);

  @override
  State<PayrollProfileDialog> createState() => _PayrollProfileDialogState();
}

class _PayrollProfileDialogState extends State<PayrollProfileDialog> {
  static const int _maxChildren = 12;

  late int _children = widget.profile.dependentChildren;
  late PayoutMode _mode = widget.profile.preferredMode ?? PayoutMode.cash;
  late MobileMoneyOperator? _operator = widget.profile.operator;
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

  StaffPayProfile get _profile => StaffPayProfile(
    staffMemberId: widget.profile.staffMemberId,
    dependentChildren: _children,
    preferredMode: _mode,
    operator: _operator,
    payoutPhone: _fields.phone.text,
    bankName: _fields.bankName.text,
    bankAccount: _fields.bankAccount.text,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StaffDialog(
      eyebrow: widget.name,
      title: l10n.payrollProfileTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.payrollProfileChildren, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: PayrollStepper(
              value: _children,
              max: _maxChildren,
              format: (value) => '$value',
              decreaseLabel: l10n.payrollDecrease,
              increaseLabel: l10n.payrollIncrease,
              onChanged: (value) => setState(() => _children = value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.payrollProfileMode, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          PayrollChoiceChips<PayoutMode>(
            values: PayoutMode.values,
            selected: _mode,
            label: (mode) => PayrollLabels.mode(l10n, mode),
            onSelected: (mode) => setState(() => _mode = mode),
          ),
          PayrollPayoutFields(
            mode: _mode,
            operator: _operator,
            onOperator: (op) => setState(() => _operator = op),
            controllers: _fields,
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
          onPressed: () => Navigator.of(context).pop(_profile),
          fullWidth: false,
        ),
      ],
    );
  }
}
