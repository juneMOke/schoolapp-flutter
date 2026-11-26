import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_form_state.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_disbursement_notice.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_voucher_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le bon de sortie demande **en plus** pour déclarer : la photo du
/// bon, et la trace de l'accord reçu hors de
/// l'application.
class ExpenseDeclarationSection extends StatelessWidget {
  final ExpenseDeclarationFormState state;
  final bool touched;
  final VoidCallback onCaptureVoucher;

  const ExpenseDeclarationSection({
    super.key,
    required this.state,
    required this.touched,
    required this.onCaptureVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const gap = SizedBox(height: AppDimensions.spacingM);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseDisbursementNotice(redeclaredAt: state.redeclaredAt),
        gap,
        ExpenseVoucherField(
          voucher: state.voucher,
          touched: touched,
          onCapture: onCaptureVoucher,
        ),
        gap,
        EteeloTextInput(
          controller: state.note,
          label: l10n.expenseDeclarationNoteLabel,
          placeholder: l10n.expenseDeclarationNotePlaceholder,
          capitalization: EteeloTextCapitalization.sentence,
        ),
      ],
    );
  }
}
