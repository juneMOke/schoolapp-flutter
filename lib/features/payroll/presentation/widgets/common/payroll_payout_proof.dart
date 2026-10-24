import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_payout_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mode d'un versement et la preuve qu'il exige : l'émargement en
/// espèces, l'opérateur, le numéro et la référence en mobile money, la
/// banque et la référence en virement. Partagé par le versement d'un salaire
/// et celui d'arriérés.
class PayrollPayoutProof extends StatelessWidget {
  final PayoutMode mode;
  final ValueChanged<PayoutMode> onMode;
  final MobileMoneyOperator? operator;
  final ValueChanged<MobileMoneyOperator> onOperator;
  final bool signed;
  final ValueChanged<bool> onSigned;
  final PayrollPayoutControllers controllers;
  final VoidCallback onChanged;

  const PayrollPayoutProof({
    super.key,
    required this.mode,
    required this.onMode,
    required this.operator,
    required this.onOperator,
    required this.signed,
    required this.onSigned,
    required this.controllers,
    required this.onChanged,
  });

  static IconData iconOf(PayoutMode mode) => switch (mode) {
    PayoutMode.cash => Icons.payments_outlined,
    PayoutMode.mobileMoney => Icons.phone_android,
    PayoutMode.bank => Icons.account_balance_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PayrollChoiceChips<PayoutMode>(
          values: PayoutMode.values,
          selected: mode,
          label: (mode) => PayrollLabels.mode(l10n, mode),
          icon: iconOf,
          onSelected: onMode,
        ),
        if (mode == PayoutMode.cash) ...[
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: signed,
            onChanged: (value) => onSigned(value ?? false),
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
          mode: mode,
          operator: operator,
          onOperator: onOperator,
          controllers: controllers,
          withReference: true,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
