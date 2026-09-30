import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les contrôleurs des coordonnées d'un versement, partagés par le versement
/// et le profil de paie.
class PayrollPayoutControllers {
  final TextEditingController phone;
  final TextEditingController reference;
  final TextEditingController bankName;
  final TextEditingController bankAccount;

  PayrollPayoutControllers({
    String? phone,
    String? bankName,
    String? bankAccount,
  }) : phone = TextEditingController(text: phone ?? ''),
       reference = TextEditingController(),
       bankName = TextEditingController(text: bankName ?? ''),
       bankAccount = TextEditingController(text: bankAccount ?? '');

  void dispose() {
    phone.dispose();
    reference.dispose();
    bankName.dispose();
    bankAccount.dispose();
  }
}

/// Les champs propres au mode choisi : opérateur et numéro (et référence)
/// en mobile money, banque et compte (et référence) en virement ; rien en
/// espèces.
class PayrollPayoutFields extends StatelessWidget {
  final PayoutMode mode;
  final MobileMoneyOperator? operator;
  final ValueChanged<MobileMoneyOperator> onOperator;
  final PayrollPayoutControllers controllers;

  /// Le versement demande la référence de la transaction ; le profil non.
  final bool withReference;
  final VoidCallback? onChanged;

  const PayrollPayoutFields({
    super.key,
    required this.mode,
    required this.operator,
    required this.onOperator,
    required this.controllers,
    this.withReference = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void changed(String _) => onChanged?.call();
    Widget gap(Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: child,
    );
    return switch (mode) {
      PayoutMode.cash => const SizedBox.shrink(),
      PayoutMode.mobileMoney => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gap(
            PayrollChoiceChips<MobileMoneyOperator>(
              values: MobileMoneyOperator.values,
              selected: operator,
              label: (op) => PayrollLabels.operator(l10n, op),
              onSelected: onOperator,
            ),
          ),
          gap(
            EteeloPhoneInput(
              controller: controllers.phone,
              label: l10n.payrollPayPhone,
              required: true,
              onChanged: changed,
            ),
          ),
          if (withReference)
            gap(
              EteeloTextInput(
                controller: controllers.reference,
                label: l10n.payrollPayReference,
                required: true,
                capitalization: EteeloTextCapitalization.none,
                onChanged: changed,
              ),
            ),
        ],
      ),
      PayoutMode.bank => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gap(
            EteeloTextInput(
              controller: controllers.bankName,
              label: l10n.payrollPayBankName,
              required: withReference,
              onChanged: changed,
            ),
          ),
          gap(
            EteeloTextInput(
              controller: controllers.bankAccount,
              label: l10n.payrollPayBankAccount,
              capitalization: EteeloTextCapitalization.none,
              onChanged: changed,
            ),
          ),
          if (withReference)
            gap(
              EteeloTextInput(
                controller: controllers.reference,
                label: l10n.payrollPayBankReference,
                required: true,
                capitalization: EteeloTextCapitalization.none,
                onChanged: changed,
              ),
            ),
        ],
      ),
    };
  }
}
