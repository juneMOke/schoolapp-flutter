import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_form_state.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_model.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_outcome.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_dialog_header.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_amount_fields.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_declaration_section.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_fields.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_footer.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_mode_switch.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Obtient la photo du bon (la feuille commune de capture), ou `null`.
typedef ExpenseVoucherCapture =
    Future<CapturedDocument?> Function(BuildContext context);

/// Ouvre le formulaire ; rend la saisie validée, ou `null` si l'on renonce.
///
/// Le scrim ne ferme pas : une saisie est du travail non enregistré.
Future<ExpenseFormOutcome?> showExpenseFormDialog(
  BuildContext context, {
  required ExpenseFormSeed seed,
  required List<ExpenseType> types,
  required ExchangeRate? rate,
  required DateTime today,
  String? recordedByName,
  String? staffAdvanceTypeId,
  VoidCallback? onStaffAdvance,
  ExpenseVoucherCapture? captureVoucher,
  bool visaOnDeclare = false,
}) => showEteeloAdaptiveDialog<ExpenseFormOutcome>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ExpenseFormDialog(
    seed: seed,
    types: types,
    rate: rate,
    today: today,
    recordedByName: recordedByName,
    staffAdvanceTypeId: staffAdvanceTypeId,
    onStaffAdvance: onStaffAdvance,
    captureVoucher: captureVoucher,
    visaOnDeclare: visaOnDeclare,
  ),
);

/// Créer, modifier, dupliquer (spec §7) — un seul formulaire, et depuis la
/// v3 deux façons de créer : **déclarer** une dépense déjà payée, ou la
/// demander **pour autorisation**. Rien ne devient rouge pendant la frappe :
/// la validation se joue à la soumission.
class ExpenseFormDialog extends StatefulWidget {
  final ExpenseFormSeed seed;
  final List<ExpenseType> types;
  final ExchangeRate? rate;
  final DateTime today;
  final String? recordedByName;

  /// Le type « Avance / prêt au personnel » : le choisir ferme ce formulaire
  /// et passe la main à la Paie ([onStaffAdvance]), qui saisit le bloc R.H.
  /// Il ne se déclare jamais (`DECLARATION_NOT_ALLOWED`).
  final String? staffAdvanceTypeId;
  final VoidCallback? onStaffAdvance;

  /// Non nul quand la session a `expense.declare` : c'est l'interrupteur de
  /// la déclaration (F35). Sans lui, le formulaire reste celui de la v2.
  final ExpenseVoucherCapture? captureVoucher;

  /// La session a `expense.decide` : la déclaration naîtra visée (F41).
  final bool visaOnDeclare;

  const ExpenseFormDialog({
    super.key,
    required this.seed,
    required this.types,
    required this.rate,
    required this.today,
    this.recordedByName,
    this.staffAdvanceTypeId,
    this.onStaffAdvance,
    this.captureVoucher,
    this.visaOnDeclare = false,
  });

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  late final _form = ExpenseFormModel(widget.seed, types: widget.types);
  late final _declaration = ExpenseDeclarationFormState(now: DateTime.now());
  bool _touched = false;

  /// Le choix par défaut reste la demande d'autorisation : déclarer fait
  /// sortir l'argent sans accord dans l'application, c'est un geste qu'on
  /// choisit.
  ExpenseMode _mode = ExpenseMode.authorization;

  bool get _canDeclare => widget.captureVoucher != null && !widget.seed.isEdit;

  bool get _declaring => _canDeclare && _mode == ExpenseMode.declaration;

  @override
  void dispose() {
    _form.dispose();
    _declaration.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _touched = true);
    final content = _form.draft(recordedByName: widget.recordedByName);
    if (content == null) return;
    if (!_declaring) {
      Navigator.of(context).pop(ExpenseFormRequest(content));
      return;
    }
    _declaration.clampTo(DateTime.now());
    final declaration = _declaration.draft(
      content,
      visaOnDeclare: widget.visaOnDeclare,
    );
    if (declaration != null) {
      Navigator.of(context).pop(ExpenseFormDeclaration(declaration));
    }
  }

  Future<void> _captureVoucher() async {
    final capture = widget.captureVoucher;
    if (capture == null) return;
    final document = await capture(context);
    if (!mounted || document == null) return;
    setState(() => _declaration.voucher = document);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final edit = widget.seed.isEdit;
    final onSubmit = widget.types.isEmpty ? null : _submit;
    return EteeloAdaptiveDialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      maxWidth: AppDimensions.expenseFormDialogMaxWidth,
      child: EteeloSubmitShortcut(
        onSubmit: onSubmit,
        onCancel: () => Navigator.of(context).pop(),
        child: EteeloDialogBody(
          header: ExpenseDialogHeader(
            eyebrow: edit ? l10n.expenseFormEditEyebrow : l10n.expenseNewAction,
            title: edit
                ? widget.seed.title
                : _declaring
                ? l10n.expenseFormDeclareTitle
                : l10n.expenseFormCreateTitle,
            subtitle: edit
                ? l10n.expenseFormEditSubtitle(
                    widget.seed.number ?? l10n.expenseNumberPending,
                  )
                : _declaring
                ? l10n.expenseFormDeclareSubtitle
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
              onSubmit: onSubmit,
              submitLabel: _declaring ? l10n.expenseFormDeclareSubmit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(AppLocalizations l10n) {
    const gap = SizedBox(height: AppDimensions.spacingM);
    final types = _declaring
        ? [
            for (final type in widget.types)
              if (type.id != widget.staffAdvanceTypeId) type,
          ]
        : widget.types;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canDeclare) ...[
          ExpenseModeSwitch(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          gap,
        ],
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
          types: types,
          typeId: _form.typeId,
          date: _form.date,
          today: widget.today,
          showDate: !_declaring,
          onTypeChanged: (id) {
            if (id == null) return;
            if (id == widget.staffAdvanceTypeId) {
              Navigator.of(context).pop();
              widget.onStaffAdvance?.call();
              return;
            }
            setState(() => _form.selectType(id));
          },
          onDateChanged: (value) {
            if (value != null) setState(() => _form.date = value);
          },
        ),
        if (_declaring) ...[
          gap,
          ExpenseDeclarationSection(
            state: _declaration,
            today: widget.today,
            touched: _touched,
            onCaptureVoucher: _captureVoucher,
            onChanged: () => setState(() {}),
          ),
        ],
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
        // L'encart « la source de fonds ne débite rien » serait faux pour
        // une déclaration en espèces : elle sort bien de la caisse.
        if (!_declaring) ...[gap, const ExpenseFundingNote()],
      ],
    );
  }
}
