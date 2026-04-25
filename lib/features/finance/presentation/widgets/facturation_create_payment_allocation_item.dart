import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_snapshot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un item d'allocation : DropDown charge + montant + snapshot avant/après.
///
/// [availableCharges] = charges non-PAID et non déjà sélectionnées par d'autres items.
/// Gère en local l'écoute du controller pour reconstruire la projection.
class FacturationCreatePaymentAllocationItem extends StatefulWidget {
  final int index;
  final StudentCharge? selectedCharge;
  final List<StudentCharge> availableCharges;
  final TextEditingController amountController;
  final ValueChanged<StudentCharge?> onChargeSelected;
  final VoidCallback onRemove;
  final bool readOnly;

  const FacturationCreatePaymentAllocationItem({
    super.key,
    required this.index,
    required this.selectedCharge,
    required this.availableCharges,
    required this.amountController,
    required this.onChargeSelected,
    required this.onRemove,
    this.readOnly = false,
  });

  @override
  State<FacturationCreatePaymentAllocationItem> createState() =>
      _FacturationCreatePaymentAllocationItemState();
}

class _FacturationCreatePaymentAllocationItemState
    extends State<FacturationCreatePaymentAllocationItem> {
  @override
  void initState() {
    super.initState();
    widget.amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  double? get _parsedAmount => double.tryParse(widget.amountController.text);

  double? _projectedPaid(StudentCharge charge) {
    final input = _parsedAmount;
    if (input == null || input <= 0) return null;
    return charge.amountPaidInCents + (input * 100);
  }

  StudentChargeStatus _projectedStatus(StudentCharge charge) {
    final projected = _projectedPaid(charge);
    if (projected == null) return charge.status;
    final remaining = charge.expectedAmountInCents - projected;
    if (remaining <= 0) return StudentChargeStatus.paid;
    return StudentChargeStatus.partial;
  }

  String? _amountValidator(String? value, AppLocalizations l10n, double remaining) {
    if (value == null || value.trim().isEmpty) {
      return l10n.facturationCreatePaymentAmountRequired;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return l10n.facturationCreatePaymentAmountInvalid;
    if (parsed <= 0) return l10n.facturationCreatePaymentAmountMustBePositive;
    if (parsed * 100 > remaining) {
      return l10n.facturationCreatePaymentAmountExceedsRemaining;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final charge = widget.selectedCharge;
    final remaining = charge != null
        ? charge.expectedAmountInCents - charge.amountPaidInCents
        : 0.0;
    final projected = charge != null ? _projectedPaid(charge) : null;

    return FinanceSectionCard(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      borderColor: AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.22),
      withShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemHeader(
            index: widget.index,
            readOnly: widget.readOnly,
            onRemove: widget.onRemove,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _ChargeDropdown(
            selectedCharge: widget.selectedCharge,
            availableCharges: widget.availableCharges.toList()
              ..addAll(charge != null && !widget.availableCharges.contains(charge)
                  ? [charge]
                  : []),
            onChanged: widget.readOnly ? null : widget.onChargeSelected,
            hint: l10n.facturationCreatePaymentChargeDropdownHint,
          ),
          AnimatedSwitcher(
            duration: FinanceMotion.standard,
            switchInCurve: FinanceMotion.outCurve,
            switchOutCurve: FinanceMotion.inCurve,
            child: charge == null
                ? const SizedBox.shrink(key: ValueKey('no_charge'))
                : Column(
                    key: ValueKey('charge_${charge.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.spacingM),
                      FacturationCreatePaymentChargeSnapshot(
                        title: l10n.facturationCreatePaymentBeforeLabel,
                        expectedAmountInCents: charge.expectedAmountInCents,
                        amountPaidInCents: charge.amountPaidInCents,
                        currency: charge.currency,
                        status: charge.status,
                        accentColor: AppColors.financeDetailChargeInfoAccent,
                        accentSoftColor: AppColors.financeDetailChargeInfoSurface,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      FinanceTextFormField(
                        controller: widget.amountController,
                        readOnly: widget.readOnly,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        label: l10n.facturationCreatePaymentAmountLabel,
                        hint: l10n.facturationCreatePaymentAmountHint,
                        accentColor: AppColors.financeDetailPaymentsAccent,
                        validator: (v) => _amountValidator(v, l10n, remaining),
                      ),
                    ],
                  ),
          ),
          AnimatedSwitcher(
            duration: FinanceMotion.medium,
            child: (charge != null && projected != null)
                ? Column(
                    key: ValueKey('projection_${charge.id}_${projected.round()}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.spacingM),
                      FacturationCreatePaymentChargeSnapshot(
                        title: l10n.facturationCreatePaymentAfterLabel,
                        expectedAmountInCents: charge.expectedAmountInCents,
                        amountPaidInCents:
                            projected.clamp(0, charge.expectedAmountInCents),
                        currency: charge.currency,
                        status: _projectedStatus(charge),
                        accentColor: AppColors.financeDetailPaymentsAccent,
                        accentSoftColor: AppColors.financeDetailPaymentsAccentSoft,
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('no_projection')),
          ),
        ],
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  final int index;
  final bool readOnly;
  final VoidCallback onRemove;

  const _ItemHeader({
    required this.index,
    required this.readOnly,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.financeDetailPaymentsAccentSoft,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: Text(
            '${index + 1}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.financeDetailPaymentsAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (!readOnly)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.danger,
            iconSize: AppDimensions.detailMiniIconSize + 4,
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

class _ChargeDropdown extends StatelessWidget {
  final StudentCharge? selectedCharge;
  final List<StudentCharge> availableCharges;
  final ValueChanged<StudentCharge?>? onChanged;
  final String hint;

  const _ChargeDropdown({
    required this.selectedCharge,
    required this.availableCharges,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<StudentCharge>(
      initialValue: selectedCharge,
      isExpanded: true,
      decoration: financeInputDecoration(
        label: hint,
        hint: hint,
        accentColor: AppColors.financeDetailPaymentsAccent,
        readOnly: onChanged == null,
      ),
      items: availableCharges
          .map(
            (c) => DropdownMenuItem<StudentCharge>(
              value: c,
              child: Text(
                c.label,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null
          ? AppLocalizations.of(context)!.facturationCreatePaymentChargeDropdownHint
          : null,
    );
  }
}
