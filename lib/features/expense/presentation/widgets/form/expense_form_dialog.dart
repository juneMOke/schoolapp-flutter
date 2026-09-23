import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_model.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_amount_fields.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_fields.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_footer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre le formulaire ; rend le brouillon validé, ou `null` si l'on renonce.
///
/// Le scrim ne ferme pas : une saisie est du travail non enregistré.
Future<ExpenseDraft?> showExpenseFormDialog(
  BuildContext context, {
  required ExpenseFormSeed seed,
  required List<ExpenseType> types,
  required ExchangeRate? rate,
  required DateTime today,
  String? recordedByName,
}) => showDialog<ExpenseDraft>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ExpenseFormDialog(
    seed: seed,
    types: types,
    rate: rate,
    today: today,
    recordedByName: recordedByName,
  ),
);

/// Créer, modifier, dupliquer (spec §7) — un seul formulaire. Rien ne devient
/// rouge pendant la frappe : la validation se joue à la soumission. Les
/// règles de saisie vivent dans [ExpenseFormModel].
class ExpenseFormDialog extends StatefulWidget {
  final ExpenseFormSeed seed;
  final List<ExpenseType> types;
  final ExchangeRate? rate;
  final DateTime today;
  final String? recordedByName;

  const ExpenseFormDialog({
    super.key,
    required this.seed,
    required this.types,
    required this.rate,
    required this.today,
    this.recordedByName,
  });

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  late final _form = ExpenseFormModel(widget.seed, types: widget.types);
  bool _touched = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _touched = true);
    final draft = _form.draft(recordedByName: widget.recordedByName);
    if (draft != null) Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final edit = widget.seed.isEdit;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.expenseFormDialogMaxWidth,
        ),
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: edit ? l10n.expenseFormEditEyebrow : l10n.expenseNewAction,
            title: edit ? widget.seed.title : l10n.expenseFormCreateTitle,
            subtitle: edit
                ? l10n.expenseFormEditSubtitle(
                    widget.seed.number ?? l10n.expenseNumberPending,
                  )
                : l10n.expenseFormCreateSubtitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingL,
              AppDimensions.spacingS,
              AppDimensions.spacingL,
              AppDimensions.spacingM,
            ),
            child: _fields(l10n),
          ),
          footer: [
            ExpenseFormFooter(
              isEdit: edit,
              onSubmit: widget.types.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(AppLocalizations l10n) {
    const gap = SizedBox(height: AppDimensions.spacingM);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.types.isEmpty) ...[
          Text(
            l10n.expenseFormNoTypes,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
          gap,
        ],
        EteeloTextInput(
          controller: _form.title,
          label: l10n.expenseFormTitle,
          placeholder: l10n.expenseFormTitlePlaceholder,
          required: true,
          capitalization: EteeloTextCapitalization.sentence,
          errorText: _touched && !_form.hasTitle
              ? l10n.expenseFormTitleRequired
              : null,
        ),
        gap,
        EteeloTextInput(
          controller: _form.description,
          label: l10n.expenseFormDescription,
          placeholder: l10n.expenseFormDescriptionPlaceholder,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 3,
          maxLines: 5,
        ),
        gap,
        ExpenseTypeDateFields(
          types: widget.types,
          typeId: _form.typeId,
          date: _form.date,
          today: widget.today,
          onTypeChanged: (id) {
            if (id != null) setState(() => _form.selectType(id));
          },
          onDateChanged: (value) {
            if (value != null) setState(() => _form.date = value);
          },
        ),
        gap,
        ExpenseAmountFields(
          controller: _form.amount,
          currency: _form.currency,
          currencies: _form.currencies,
          rate: widget.rate,
          touched: _touched,
          onCurrencyChanged: (value) =>
              setState(() => _form.chooseCurrency(value)),
          onAmountChanged: () => setState(() {}),
        ),
        gap,
        ExpenseFundingField(
          funding: _form.funding,
          onFundingChanged: (value) {
            if (value != null) setState(() => _form.funding = value);
          },
        ),
        gap,
        EteeloTextInput(
          controller: _form.supplier,
          label: l10n.expenseFormSupplier,
          placeholder: l10n.expenseFormSupplierPlaceholder,
        ),
        gap,
        const ExpenseFundingNote(),
      ],
    );
  }
}
