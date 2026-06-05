import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_charge_line.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_neutral_line.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryChargesSection extends StatelessWidget {
  final bool canLoadCharges;
  final VoidCallback onRetry;

  const SummaryChargesSection({
    super.key,
    required this.canLoadCharges,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SummarySectionCard(
      title: l10n.studentChargesStepTitle,
      icon: Icons.paid_outlined,
      // Frais : section en lecture seule, pas de bouton « Modifier ».
      child: BlocBuilder<StudentChargesBloc, StudentChargesState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.studentCharges != curr.studentCharges ||
            prev.errorType != curr.errorType,
        builder: (context, state) {
          if (!canLoadCharges) {
            return SummaryNeutralLine(
              message: l10n.summaryChargesUnavailable,
              retryLabel: l10n.studentChargesRetry,
              onRetry: null,
            );
          }

          if (state.status == StudentChargesStatus.loading &&
              state.studentCharges.isEmpty) {
            return Text(
              l10n.studentChargesLoading,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            );
          }

          if (state.status == StudentChargesStatus.failure &&
              state.studentCharges.isEmpty) {
            return SummaryNeutralLine(
              message: l10n.summaryChargesUnavailable,
              retryLabel: l10n.studentChargesRetry,
              onRetry: onRetry,
            );
          }

          final rows = state.studentCharges;
          final total = rows.fold<double>(
            0,
            (sum, charge) => sum + charge.expectedAmountInCents,
          );
          final currency = rows.isNotEmpty ? rows.first.currency : '';

          return Column(
            children: [
              ...rows.map((charge) => SummaryChargeLine(charge: charge)),
              const SizedBox(height: AppDimensions.spacingS),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.summaryChargesTotalDue,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMonetaryAmountWithCurrency(
                      amount: total,
                      currency: currency,
                    ),
                    style: AppTextStyles.totalAmountLora.copyWith(
                      fontSize: 18,
                      color: AppColors.terreCuite,
                    ),
                  ),
                ],
              ),
              if (state.status == StudentChargesStatus.failure)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SecondaryButton(
                      label: l10n.studentChargesRetry,
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                      fullWidth: false,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
