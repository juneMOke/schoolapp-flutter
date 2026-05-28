import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_impact_table.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
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
  final VoidCallback? onAmountChanged;
  final bool readOnly;

  const FacturationCreatePaymentAllocationItem({
    super.key,
    required this.index,
    required this.selectedCharge,
    required this.availableCharges,
    required this.amountController,
    required this.onChargeSelected,
    required this.onRemove,
    this.onAmountChanged,
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

  double? get _parsedAmount =>
      parseMonetaryAmount(widget.amountController.text);

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

  String? _amountValidator(
    String? value,
    AppLocalizations l10n,
    double remaining,
  ) {
    if (value == null || value.trim().isEmpty) {
      return l10n.facturationCreatePaymentAmountRequired;
    }
    final parsed = parseMonetaryAmount(value.trim());
    if (parsed == null) return l10n.facturationCreatePaymentAmountInvalid;
    if (parsed <= 0) return l10n.facturationCreatePaymentAmountMustBePositive;
    if (parsed * 100 > remaining) {
      return l10n.facturationCreatePaymentAmountExceedsRemaining;
    }
    return null;
  }

  void _fillRemainingAmount(StudentCharge charge) {
    final remainingInCents =
        (charge.expectedAmountInCents - charge.amountPaidInCents).clamp(
          0,
          double.infinity,
        );
    final remainingAmount = remainingInCents / 100;
    final isInteger = remainingAmount == remainingAmount.roundToDouble();
    widget.amountController.text = isInteger
        ? remainingAmount.toStringAsFixed(0)
        : remainingAmount.toStringAsFixed(2);
    widget.onAmountChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final charge = widget.selectedCharge;
    final selectedChargeLabel = charge?.feeCode.localizedFeeLabel(l10n);
    final remaining = charge != null
        ? charge.expectedAmountInCents - charge.amountPaidInCents
        : 0.0;
    final projected = charge != null ? _projectedPaid(charge) : null;

    return FinanceSectionCard(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      borderColor: AppColors.bleuArdoise.withValues(alpha: 0.22),
      withShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemHeader(
            index: widget.index,
            selectedChargeLabel: selectedChargeLabel,
            readOnly: widget.readOnly,
            onRemove: widget.onRemove,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _ChargeDropdown(
            selectedCharge: widget.selectedCharge,
            availableCharges: widget.availableCharges.toList()
              ..addAll(
                charge != null && !widget.availableCharges.contains(charge)
                    ? [charge]
                    : [],
              ),
            onChanged: widget.readOnly ? null : widget.onChargeSelected,
            hint: l10n.facturationCreatePaymentChargeDropdownHint,
            l10n: l10n,
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
                      TextFormField(
                        controller: widget.amountController,
                        onChanged: (_) => widget.onAmountChanged?.call(),
                        readOnly: widget.readOnly,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTextStyles.moneyTabular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: financeInputDecoration(
                          label: l10n.facturationCreatePaymentAmountLabel,
                          hint: l10n.facturationCreatePaymentAmountHint,
                          accentColor: AppColors.bleuArdoise,
                          readOnly: widget.readOnly,
                        ).copyWith(suffixText: charge.currency),
                        validator: (v) => _amountValidator(v, l10n, remaining),
                      ),
                      if (!widget.readOnly)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.spacingXS,
                          ),
                          child: Wrap(
                            spacing: AppDimensions.spacingXS,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l10n.facturationCreatePaymentChargeRemainingHelper(
                                  formatMonetaryAmountWithCurrency(
                                    amount: remaining / 100,
                                    currency: charge.currency,
                                  ),
                                ),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _fillRemainingAmount(charge),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.facturationCreatePaymentPayAllAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          AnimatedSwitcher(
            duration: FinanceMotion.medium,
            switchInCurve: FinanceMotion.outCurve,
            switchOutCurve: FinanceMotion.inCurve,
            layoutBuilder: (currentChild, previousChildren) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...previousChildren,
                ...switch (currentChild) {
                  null => const <Widget>[],
                  final child => <Widget>[child],
                },
              ],
            ),
            child: (charge != null && projected != null)
                ? Column(
                    key: ValueKey(
                      'projection_${charge.id}_${projected.round()}',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.spacingM),
                      FacturationCreatePaymentChargeImpactTable(
                        expectedAmountInCents: charge.expectedAmountInCents,
                        beforePaidInCents: charge.amountPaidInCents,
                        afterPaidInCents: projected.clamp(
                          0,
                          charge.expectedAmountInCents,
                        ),
                        currency: charge.currency,
                        beforeStatus: charge.status,
                        afterStatus: _projectedStatus(charge),
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
  final String? selectedChargeLabel;
  final bool readOnly;
  final VoidCallback onRemove;

  const _ItemHeader({
    required this.index,
    required this.selectedChargeLabel,
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
            color: AppColors.bleuArdoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: Text(
            '${index + 1}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.bleuArdoise,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            selectedChargeLabel ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
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
  final AppLocalizations l10n;

  const _ChargeDropdown({
    required this.selectedCharge,
    required this.availableCharges,
    required this.onChanged,
    required this.hint,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<StudentCharge>(
      initialValue: selectedCharge,
      isExpanded: true,
      decoration: financeInputDecoration(
        label: hint,
        hint: hint,
        accentColor: AppColors.bleuArdoise,
        readOnly: onChanged == null,
      ),
      items: availableCharges
          .map(
            (c) => DropdownMenuItem<StudentCharge>(
              value: c,
              child: Text(
                c.feeCode.localizedFeeLabel(l10n),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null
          ? AppLocalizations.of(
              context,
            )!.facturationCreatePaymentChargeDropdownHint
          : null,
    );
  }
}
