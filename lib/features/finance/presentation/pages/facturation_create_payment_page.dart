import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/models/facturation_create_payment_allocation_draft.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_create_payment_form_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_page_scaffold.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class FacturationCreatePaymentPage extends StatefulWidget {
  final FacturationCreatePaymentIntent intent;

  const FacturationCreatePaymentPage({super.key, required this.intent});

  @override
  State<FacturationCreatePaymentPage> createState() =>
      _FacturationCreatePaymentPageState();
}

class _FacturationCreatePaymentPageState
    extends State<FacturationCreatePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _payerLastNameController = TextEditingController();
  final _payerFirstNameController = TextEditingController();
  final _payerMiddleNameController = TextEditingController();

  final List<FacturationCreatePaymentAllocationDraft> _drafts = [];
  bool _isSubmitted = false;

  List<StudentCharge?> get _selectedCharges =>
      _drafts.map((draft) => draft.selectedCharge).toList(growable: false);

  List<TextEditingController> get _amountControllers =>
      _drafts.map((draft) => draft.amountController).toList(growable: false);

  int get _allocatedAmountInCents =>
      computeAllocatedAmountInCents(_amountControllers);

  String get _effectiveCurrency => resolveCreatePaymentCurrency(
    selectedCurrency: null,
    selectedCharges: _selectedCharges,
    unpaidCharges: widget.intent.unpaidCharges,
  );

  // ----------- listenWhen / buildWhen extraits pour la lisibilité -----------
  bool _listenCreateStatus(PaymentsState prev, PaymentsState curr) =>
      prev.createStatus != curr.createStatus ||
      prev.createErrorType != curr.createErrorType;

  bool _canSubmit(PaymentsState state) => canSubmitCreatePayment(
    state: state,
    isSubmitted: _isSubmitted,
    selectedCharges: _selectedCharges,
    allocatedAmountInCents: _allocatedAmountInCents,
    currency: _effectiveCurrency,
  );

  // -------------------------------------------------------------------------

  void _onDraftAmountChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _attachDraftAmountListener(
    FacturationCreatePaymentAllocationDraft draft,
  ) {
    draft.amountController.addListener(_onDraftAmountChanged);
  }

  void _detachDraftAmountListener(
    FacturationCreatePaymentAllocationDraft draft,
  ) {
    draft.amountController.removeListener(_onDraftAmountChanged);
  }

  @override
  void dispose() {
    _payerLastNameController.dispose();
    _payerFirstNameController.dispose();
    _payerMiddleNameController.dispose();
    for (final draft in _drafts) {
      _detachDraftAmountListener(draft);
      draft.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    final draft = FacturationCreatePaymentAllocationDraft();
    _attachDraftAmountListener(draft);
    setState(() => _drafts.add(draft));
  }

  void _removeDraft(int index) {
    final draft = _drafts[index];
    _detachDraftAmountListener(draft);
    setState(() => _drafts.removeAt(index));
    draft.dispose();
  }

  Future<void> _onRemoveDraftRequested(int index) async {
    if (!isCreatePaymentDraftIndexValid(
      index: index,
      draftsLength: _drafts.length,
    )) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: l10n.facturationCreatePaymentRemoveAllocationConfirmTitle,
      message: l10n.facturationCreatePaymentRemoveAllocationConfirmMessage(
        index + 1,
      ),
      confirmLabel: l10n.facturationCreatePaymentRemoveAllocationConfirmAction,
      cancelLabel: l10n.cancel,
      isDestructive: true,
      headerIcon: Icons.delete_sweep_outlined,
      headerIconColor: AppColors.danger,
      headerIconBackgroundColor: AppColors.financeDetailDangerSoft,
      confirmIcon: Icons.delete_forever_outlined,
    );

    if (!mounted || !confirmed) {
      return;
    }
    if (!isCreatePaymentDraftIndexValid(
      index: index,
      draftsLength: _drafts.length,
    )) {
      return;
    }

    _removeDraft(index);
  }

  void _onChargeSelected(int index, StudentCharge? charge) {
    setState(() {
      _drafts[index].selectedCharge = charge;
      _drafts[index].amountController.clear();
    });
  }

  Future<void> _onSubmitPressed(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final bloc = context.read<PaymentsBloc>();
    if (!_canSubmit(bloc.state)) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final confirmed = await showCreatePaymentConfirmDialog(context);
    if (!mounted || !confirmed) {
      return;
    }

    final currency = _effectiveCurrency;
    if (currency.isEmpty) {
      return;
    }

    final allocations = buildCreatePaymentAllocations(_drafts);

    bloc.add(
      PaymentsCreateRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        amountInCents: _allocatedAmountInCents,
        currency: currency,
        payerFirstName: _payerFirstNameController.text.trim(),
        payerLastName: _payerLastNameController.text.trim(),
        payerMiddleName: _payerMiddleNameController.text.trim().isEmpty
            ? null
            : _payerMiddleNameController.text.trim(),
        allocations: allocations,
      ),
    );
  }

  void _onPrintReceiptRequested(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.pageUnderConstruction)));
  }

  void _onCancelRequested() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<PaymentsBloc>(
      create: (_) => getIt<PaymentsBloc>(),
      child: BlocConsumer<PaymentsBloc, PaymentsState>(
        listenWhen: _listenCreateStatus,
        listener: (context, state) {
          if (state.createStatus == PaymentsStatus.success) {
            setState(() => _isSubmitted = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.facturationCreatePaymentSuccessMessage),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.createStatus == PaymentsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.createErrorType.localizedCreateMessage(l10n),
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) => FacturationCreatePaymentPageScaffold(
          intent: widget.intent,
          formKey: _formKey,
          payerLastNameController: _payerLastNameController,
          payerFirstNameController: _payerFirstNameController,
          payerMiddleNameController: _payerMiddleNameController,
          selectedCharges: _selectedCharges,
          amountControllers: _amountControllers,
          allocatedAmountInCents: _allocatedAmountInCents,
          trackerCurrency: _effectiveCurrency,
          isLoading: state.createStatus == PaymentsStatus.loading,
          isSubmitted: _isSubmitted,
          canSubmit: _canSubmit(state),
          onAddDraft: _addDraft,
          onAmountChanged: _onDraftAmountChanged,
          onRemoveDraft: _onRemoveDraftRequested,
          onChargeSelected: _onChargeSelected,
          onCancelPressed: _onCancelRequested,
          onSubmitPressed: () => _onSubmitPressed(context, l10n),
          onPrintReceiptPressed: () => _onPrintReceiptRequested(context, l10n),
          l10n: l10n,
        ),
      ),
    );
  }
}
