import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_allocation_item.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section gérant la liste des allocations (ajout / suppression / sélection).
///
/// [allUnpaidCharges] : toutes les charges non-PAID.
/// [selectedCharges] : celles déjà choisies dans les items existants (pour exclusion).
class FacturationCreatePaymentAllocationEditor extends StatelessWidget {
  final List<StudentCharge> allUnpaidCharges;
  final List<StudentCharge?> selectedCharges;
  final List<TextEditingController> amountControllers;
  final bool readOnly;
  final VoidCallback onAddAllocation;
  final ValueChanged<int> onRemoveAllocation;
  final void Function(int index, StudentCharge? charge) onChargeSelected;

  const FacturationCreatePaymentAllocationEditor({
    super.key,
    required this.allUnpaidCharges,
    required this.selectedCharges,
    required this.amountControllers,
    required this.onAddAllocation,
    required this.onRemoveAllocation,
    required this.onChargeSelected,
    this.readOnly = false,
  });

  bool get _allPaid => allUnpaidCharges.isEmpty;

  /// Charges disponibles pour l'item à [index] :
  /// toutes les non-PAID sauf celles déjà sélectionnées dans un autre item.
  List<StudentCharge> _availableFor(int index) {
    final otherSelected = [
      for (int i = 0; i < selectedCharges.length; i++)
        if (i != index && selectedCharges[i] != null) selectedCharges[i]!,
    ];
    return allUnpaidCharges
        .where((c) => !otherSelected.any((s) => s.id == c.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceSectionCard(
      gradientColors: const [
        AppColors.financeDetailPaymentsSurface,
        AppColors.financeDetailPaymentsSurfaceAlt,
      ],
      borderColor: AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.payments_outlined,
            title: l10n.facturationCreatePaymentAllocationSectionTitle,
            subtitle: l10n.facturationCreatePaymentAllocationSectionSubtitle,
            accent: AppColors.financeDetailPaymentsAccent,
            accentSoft: AppColors.financeDetailPaymentsAccentSoft,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          AnimatedSwitcher(
            duration: FinanceMotion.standard,
            switchInCurve: FinanceMotion.outCurve,
            switchOutCurve: FinanceMotion.inCurve,
            child: _allPaid
                ? _AllPaidMessage(
                    key: const ValueKey('all_paid'),
                    message: l10n.facturationCreatePaymentAllChargesPaid,
                  )
                : AnimatedSize(
                    key: const ValueKey('allocation_list'),
                    duration: FinanceMotion.standard,
                    curve: FinanceMotion.outCurve,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < selectedCharges.length; i++) ...[
                          FacturationCreatePaymentAllocationItem(
                            key: ValueKey(
                              'allocation_${i}_${selectedCharges[i]?.id ?? ''}',
                            ),
                            index: i,
                            selectedCharge: selectedCharges[i],
                            availableCharges: _availableFor(i),
                            amountController: amountControllers[i],
                            onChargeSelected: (c) => onChargeSelected(i, c),
                            onRemove: () => onRemoveAllocation(i),
                            readOnly: readOnly,
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                        ],
                        if (!readOnly)
                          _AddAllocationButton(
                            label: l10n.facturationCreatePaymentAddAllocationLabel,
                            onPressed: onAddAllocation,
                            disabled:
                                selectedCharges.length >= allUnpaidCharges.length,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AllPaidMessage extends StatelessWidget {
  final String message;

  const _AllPaidMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.financeDetailSuccessSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.spacingXL,
            height: AppDimensions.spacingXL,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.success,
              size: AppDimensions.detailMiniIconSize + 2,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAllocationButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool disabled;

  const _AddAllocationButton({
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: disabled
              ? AppColors.border
              : AppColors.financeDetailPaymentsAccent,
        ),
        foregroundColor: disabled
            ? AppColors.textSecondary
            : AppColors.financeDetailPaymentsAccent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        ),
      ),
      onPressed: disabled ? null : onPressed,
      icon: const Icon(Icons.add),
      label: Text(label, style: AppTextStyles.action),
    );
  }
}
