import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_allocation_editor.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_footer_actions.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationCreatePaymentPageScaffold extends StatelessWidget {
  final FacturationCreatePaymentIntent intent;
  final GlobalKey<FormState> formKey;
  final TextEditingController payerLastNameController;
  final TextEditingController payerFirstNameController;
  final TextEditingController payerMiddleNameController;
  final List<StudentCharge?> selectedCharges;
  final List<TextEditingController> amountControllers;
  final int allocatedAmountInCents;
  final String trackerCurrency;
  final bool isLoading;
  final bool isSubmitted;
  final bool canSubmit;
  final VoidCallback onAddDraft;
  final VoidCallback onAmountChanged;
  final ValueChanged<int> onRemoveDraft;
  final void Function(int, StudentCharge?) onChargeSelected;
  final VoidCallback onCancelPressed;
  final VoidCallback onSubmitPressed;
  final VoidCallback onPrintReceiptPressed;
  final AppLocalizations l10n;

  const FacturationCreatePaymentPageScaffold({
    super.key,
    required this.intent,
    required this.formKey,
    required this.payerLastNameController,
    required this.payerFirstNameController,
    required this.payerMiddleNameController,
    required this.selectedCharges,
    required this.amountControllers,
    required this.allocatedAmountInCents,
    required this.trackerCurrency,
    required this.isLoading,
    required this.isSubmitted,
    required this.canSubmit,
    required this.onAddDraft,
    required this.onAmountChanged,
    required this.onRemoveDraft,
    required this.onChargeSelected,
    required this.onCancelPressed,
    required this.onSubmitPressed,
    required this.onPrintReceiptPressed,
    required this.l10n,
  });

  String _studentFullName() {
    final fullName = [
      intent.lastName,
      intent.firstName,
      intent.surname,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
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
      bottomNavigationBar: isSubmitted
          ? _PrintReceiptFooter(
              label: l10n.facturationPrintReceiptLabel,
              onPressed: onPrintReceiptPressed,
            )
          : (intent.hasDisplayContext && intent.studentCharges.isNotEmpty)
          ? FacturationCreatePaymentFooterActions(
              allocatedAmountInCents: allocatedAmountInCents,
              currency: trackerCurrency,
              canSubmit: canSubmit,
              isLoading: isLoading,
              onCancel: onCancelPressed,
              onSubmit: onSubmitPressed,
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
                    selectedCharges: selectedCharges,
                    amountControllers: amountControllers,
                    allocatedAmountInCents: allocatedAmountInCents,
                    trackerCurrency: trackerCurrency,
                    onAddAllocation: onAddDraft,
                    onAmountChanged: onAmountChanged,
                    onRemoveAllocation: onRemoveDraft,
                    onChargeSelected: onChargeSelected,
                    readOnly: isSubmitted,
                  ),
                  SizedBox(height: blockSpacing),
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

class _PrintReceiptFooter extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrintReceiptFooter({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(
              top: BorderSide(
                color: AppColors.borderStrong.withValues(alpha: 0.2),
              ),
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