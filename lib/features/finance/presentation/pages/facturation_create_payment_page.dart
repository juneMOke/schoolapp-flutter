import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_allocation_editor.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_submit_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

// ---------------------------------------------------------------------------
// Modèle local représentant un brouillon d'allocation (UI-only)
// ---------------------------------------------------------------------------
class _AllocationDraft {
  StudentCharge? selectedCharge;
  final TextEditingController amountController;

  _AllocationDraft() : amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

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

  final List<_AllocationDraft> _drafts = [];
  bool _isSubmitted = false;

  // ----------- listenWhen / buildWhen extraits pour la lisibilité -----------
  bool _listenCreateStatus(PaymentsState prev, PaymentsState curr) =>
      prev.createStatus != curr.createStatus ||
      prev.createErrorType != curr.createErrorType;

  bool _buildCreateStatus(PaymentsState prev, PaymentsState curr) =>
      prev.createStatus != curr.createStatus;

  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _payerLastNameController.dispose();
    _payerFirstNameController.dispose();
    _payerMiddleNameController.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDraft() {
    setState(() => _drafts.add(_AllocationDraft()));
  }

  void _removeDraft(int index) {
    final draft = _drafts[index];
    setState(() => _drafts.removeAt(index));
    draft.dispose();
  }

  Future<void> _onRemoveDraftRequested(int index) async {
    if (index < 0 || index >= _drafts.length) return;

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
    );

    if (!mounted || !confirmed) return;
    if (index < 0 || index >= _drafts.length) return;

    _removeDraft(index);
  }

  void _onChargeSelected(int index, StudentCharge? charge) {
    setState(() {
      _drafts[index].selectedCharge = charge;
      _drafts[index].amountController.clear();
    });
  }

  Future<void> _onSubmitPressed(BuildContext context, AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Stocker le BLoC avant l'await pour éviter l'utilisation d'un context obsolète
    final bloc = context.read<PaymentsBloc>();

    final confirmed = await showCreatePaymentConfirmDialog(context);
    if (!mounted) return;
    if (!confirmed) return;

    final totalAmountInCents = _drafts.fold<int>(
      0,
      (sum, d) => sum + ((double.tryParse(d.amountController.text) ?? 0) * 100).round(),
    );

    final allocations = _drafts
        .where((d) => d.selectedCharge != null)
        .map(
          (d) => CreatePaymentAllocationInput(
            studentChargeId: d.selectedCharge!.id,
            feeCode: d.selectedCharge!.feeCode,
            studentChargeLabel: d.selectedCharge!.label,
            amountInCents:
                ((double.tryParse(d.amountController.text) ?? 0) * 100).round(),
            currency: d.selectedCharge!.currency,
          ),
        )
        .toList();

    final currency = _drafts
        .firstWhere((d) => d.selectedCharge != null)
        .selectedCharge!
        .currency;

    bloc.add(
      PaymentsCreateRequested(
        studentId: widget.intent.studentId,
        academicYearId: widget.intent.academicYearId,
        amountInCents: totalAmountInCents,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pageUnderConstruction)),
    );
  }

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
        buildWhen: _buildCreateStatus,
        builder: (context, state) {
          final isLoading = state.createStatus == PaymentsStatus.loading;

          return _PageScaffold(
            intent: widget.intent,
            formKey: _formKey,
            payerLastNameController: _payerLastNameController,
            payerFirstNameController: _payerFirstNameController,
            payerMiddleNameController: _payerMiddleNameController,
            drafts: _drafts,
            isLoading: isLoading,
            isSubmitted: _isSubmitted,
            onAddDraft: _addDraft,
            onRemoveDraft: _onRemoveDraftRequested,
            onChargeSelected: _onChargeSelected,
            onSubmitPressed: () => _onSubmitPressed(context, l10n),
            onPrintReceiptPressed: () => _onPrintReceiptRequested(context, l10n),
            l10n: l10n,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold de la page (mince — délègue à sous-widgets)
// ---------------------------------------------------------------------------
class _PageScaffold extends StatelessWidget {
  final FacturationCreatePaymentIntent intent;
  final GlobalKey<FormState> formKey;
  final TextEditingController payerLastNameController;
  final TextEditingController payerFirstNameController;
  final TextEditingController payerMiddleNameController;
  final List<_AllocationDraft> drafts;
  final bool isLoading;
  final bool isSubmitted;
  final VoidCallback onAddDraft;
  final ValueChanged<int> onRemoveDraft;
  final void Function(int, StudentCharge?) onChargeSelected;
  final VoidCallback onSubmitPressed;
  final VoidCallback onPrintReceiptPressed;
  final AppLocalizations l10n;

  const _PageScaffold({
    required this.intent,
    required this.formKey,
    required this.payerLastNameController,
    required this.payerFirstNameController,
    required this.payerMiddleNameController,
    required this.drafts,
    required this.isLoading,
    required this.isSubmitted,
    required this.onAddDraft,
    required this.onRemoveDraft,
    required this.onChargeSelected,
    required this.onSubmitPressed,
    required this.onPrintReceiptPressed,
    required this.l10n,
  });

  String _studentFullName() {
    final fullName = [intent.lastName, intent.firstName, intent.surname]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  String _studentSubtitle() {
    final subtitle = [intent.levelName, intent.levelGroupName]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return subtitle.isEmpty ? l10n.facturationDetailUnknownValue : subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = intent.unpaidCharges;

    return AppPageBackground(
      appBar: FinanceDetailAppBar(
        title: l10n.facturationCreatePaymentHeroTitle,
        subtitle: '${_studentFullName()} · ${_studentSubtitle()}',
        fallbackRoute: AppRoutesNames.facturations,
      ),
      // Footer sticky "Imprimer le reçu" affiché uniquement après soumission réussie
      bottomNavigationBar: isSubmitted
          ? _PrintReceiptFooter(
              label: l10n.facturationPrintReceiptLabel,
              onPressed: onPrintReceiptPressed,
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
          final blockSpacing = compact
              ? AppDimensions.spacingM - AppDimensions.spacingXS
              : AppDimensions.detailSectionSpacing;

          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!intent.hasDisplayContext)
                  FinanceContextErrorCard(
                    title: l10n.facturationDetailContextErrorTitle,
                    message: l10n.facturationDetailContextErrorMessage,
                    icon: Icons.report_problem_outlined,
                    accent: AppColors.warning,
                    accentSoft: AppColors.warning.withValues(alpha: 0.14),
                    borderColor: AppColors.warning.withValues(alpha: 0.2),
                  )
                else if (intent.studentCharges.isEmpty)
                  FinanceContextErrorCard(
                    title: l10n.facturationCreatePaymentChargesUnavailable,
                    message: l10n.facturationCreatePaymentChargesUnavailable,
                    icon: Icons.receipt_long_outlined,
                    accent: AppColors.bleuArdoise,
                    accentSoft: AppColors.surfaceAlt,
                    borderColor: AppColors.border,
                  )
                else ...[
                  FacturationCreatePaymentPayerSection(
                    lastNameController: payerLastNameController,
                    firstNameController: payerFirstNameController,
                    middleNameController: payerMiddleNameController,
                    readOnly: isSubmitted,
                  ),
                  SizedBox(height: blockSpacing),
                  FacturationCreatePaymentAllocationEditor(
                    allUnpaidCharges: unpaid,
                    selectedCharges: drafts.map((d) => d.selectedCharge).toList(),
                    amountControllers:
                        drafts.map((d) => d.amountController).toList(),
                    onAddAllocation: onAddDraft,
                    onRemoveAllocation: onRemoveDraft,
                    onChargeSelected: onChargeSelected,
                    readOnly: isSubmitted,
                  ),
                  SizedBox(height: blockSpacing),
                  if (!isSubmitted)
                    FacturationCreatePaymentSubmitSection(
                      hasAllocations:
                          drafts.isNotEmpty && drafts.any((d) => d.selectedCharge != null),
                      isLoading: isLoading,
                      isSubmitted: isSubmitted,
                      onSubmit: onSubmitPressed,
                    ),
                  if (isSubmitted)
                    const SizedBox(height: AppDimensions.fabListBottomPadding),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer sticky post-soumission : "Imprimer le reçu"
// ---------------------------------------------------------------------------
class _PrintReceiptFooter extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrintReceiptFooter({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(
              top: BorderSide(color: AppColors.borderStrong.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: SecondaryButton(
                label: label,
                icon: compact ? null : Icons.print_outlined,
                onPressed: onPressed,
              ),
            ),
          ),
        );
      },
    );
  }
}