import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_form_fields.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationCreatePaymentDetailsSection extends StatelessWidget {
  final TextEditingController receivedAmountController;
  final DateTime paymentDate;
  final Set<String> currencies;
  final String? selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onPickDate;
  final bool readOnly;

  const FacturationCreatePaymentDetailsSection({
    super.key,
    required this.receivedAmountController,
    required this.paymentDate,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.onPickDate,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizations = MaterialLocalizations.of(context);
    final formattedDate = localizations.formatMediumDate(paymentDate);
    final orderedCurrencies = currencies.toList(growable: false)..sort();

    return FinanceSectionCard(
      gradientColors: const [
        AppColors.financeDetailInfoSurface,
        AppColors.financeDetailInfoSurfaceAlt,
      ],
      borderColor: AppColors.bleuArdoise.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: l10n.facturationCreatePaymentDetailsSectionTitle,
            subtitle: l10n.facturationCreatePaymentDetailsSectionSubtitle,
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.bleuArdoise.withValues(alpha: 0.1),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
              final fieldWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (AppDimensions.spacingM * 2)) / 3;

              return Wrap(
                spacing: AppDimensions.spacingM,
                runSpacing: AppDimensions.spacingM,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextFormField(
                      controller: receivedAmountController,
                      readOnly: readOnly,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.moneyTabular.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: financeInputDecoration(
                        label: l10n.facturationCreatePaymentReceivedAmountLabel,
                        hint: l10n.facturationCreatePaymentReceivedAmountHint,
                        accentColor: AppColors.bleuArdoise,
                        readOnly: readOnly,
                      ),
                      validator: (value) {
                        final normalized = value?.trim() ?? '';
                        if (normalized.isEmpty) {
                          return l10n.facturationCreatePaymentAmountRequired;
                        }
                        final parsed = double.tryParse(
                          normalized.replaceAll(' ', '').replaceAll(',', '.'),
                        );
                        if (parsed == null) {
                          return l10n.facturationCreatePaymentAmountInvalid;
                        }
                        if (parsed <= 0) {
                          return l10n
                              .facturationCreatePaymentAmountMustBePositive;
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _CurrencyField(
                      label: l10n.facturationCreatePaymentCurrencyLabel,
                      currencies: orderedCurrencies,
                      selectedCurrency: selectedCurrency,
                      onCurrencyChanged: onCurrencyChanged,
                      readOnly: readOnly || orderedCurrencies.length > 1,
                      multiCurrencyHint:
                          l10n.facturationCreatePaymentCurrencyReadOnlyHint,
                      unavailableHint:
                          l10n.facturationCreatePaymentCurrencyUnavailable,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: InkWell(
                      onTap: readOnly ? null : onPickDate,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                      child: IgnorePointer(
                        child: TextFormField(
                          readOnly: true,
                          initialValue: formattedDate,
                          decoration:
                              financeInputDecoration(
                                label: l10n.facturationCreatePaymentDateLabel,
                                hint: l10n.facturationCreatePaymentDateLabel,
                                accentColor: AppColors.bleuArdoise,
                                readOnly: true,
                              ).copyWith(
                                suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  final String label;
  final List<String> currencies;
  final String? selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final bool readOnly;
  final String multiCurrencyHint;
  final String unavailableHint;

  const _CurrencyField({
    required this.label,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.readOnly,
    required this.multiCurrencyHint,
    required this.unavailableHint,
  });

  @override
  Widget build(BuildContext context) {
    if (currencies.isEmpty) {
      return TextFormField(
        readOnly: true,
        decoration: financeInputDecoration(
          label: label,
          hint: unavailableHint,
          accentColor: AppColors.bleuArdoise,
          readOnly: true,
        ),
      );
    }

    if (readOnly && currencies.length > 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.financeDetailMutedSurface,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: currencies
                  .map(
                    (currency) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.spacingS,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        currency,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              multiCurrencyHint,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final effectiveValue = selectedCurrency ?? currencies.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: currencies
                .map(
                  (currency) => ButtonSegment<String>(
                    value: currency,
                    label: Text(currency),
                  ),
                )
                .toList(growable: false),
            selected: {effectiveValue},
            onSelectionChanged: readOnly
                ? null
                : (selection) {
                    final picked = selection.firstOrNull;
                    if (picked != null) {
                      onCurrencyChanged(picked);
                    }
                  },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textSecondary,
              selectedForegroundColor: AppColors.surface,
              selectedBackgroundColor: AppColors.bleuArdoise,
              side: BorderSide(
                color: AppColors.bleuArdoise.withValues(alpha: 0.25),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.spacingM),
              ),
              textStyle: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}
