import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationCreatePaymentFooterActions extends StatelessWidget {
  final int allocatedAmountInCents;
  final String currency;
  final bool canSubmit;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const FacturationCreatePaymentFooterActions({
    super.key,
    required this.allocatedAmountInCents,
    required this.currency,
    required this.canSubmit,
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  String _format(int amountInCents) => formatMonetaryAmountWithCurrency(
    amount: amountInCents / 100,
    currency: currency,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = l10n.facturationCreatePaymentFooterTotalPayments(
      _format(allocatedAmountInCents),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

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
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          summary,
                          style: AppTextStyles.totalAmountLora.copyWith(
                            color: AppColors.bleuArdoise,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: l10n.cancel,
                                onPressed: isLoading ? null : onCancel,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Expanded(
                              child: PrimaryButton(
                                label: l10n.facturationCreatePaymentSubmitLabel,
                                icon: Icons.check_circle_outline,
                                isLoading: isLoading,
                                onPressed: canSubmit ? onSubmit : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary,
                            style: AppTextStyles.totalAmountLora.copyWith(
                              color: AppColors.bleuArdoise,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        SizedBox(
                          width: 180,
                          child: SecondaryButton(
                            label: l10n.cancel,
                            onPressed: isLoading ? null : onCancel,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        SizedBox(
                          width: 240,
                          child: PrimaryButton(
                            label: l10n.facturationCreatePaymentSubmitLabel,
                            icon: Icons.check_circle_outline,
                            isLoading: isLoading,
                            onPressed: canSubmit ? onSubmit : null,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
