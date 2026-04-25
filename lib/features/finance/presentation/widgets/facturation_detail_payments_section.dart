import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_state_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payments_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationDetailPaymentsSection extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final VoidCallback onCreatePaymentRequested;
  final ValueChanged<Payment> onViewPaymentRequested;

  const FacturationDetailPaymentsSection({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.onCreatePaymentRequested,
    required this.onViewPaymentRequested,
  });

  void _retry(BuildContext context) {
    context.read<PaymentsBloc>().add(
      PaymentsRequested(studentId: studentId, academicYearId: academicYearId),
    );
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
              final actionButton = _CollectPaymentButton(
                label: l10n.facturationDetailCollectPaymentAction,
                onPressed: onCreatePaymentRequested,
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FinanceSectionHeader(
                            icon: Icons.payments_outlined,
                            title: l10n.facturationDetailPaymentsSectionTitle,
                            accent: AppColors.financeDetailPaymentsAccent,
                            accentSoft: AppColors.financeDetailPaymentsAccentSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.facturationDetailPaymentsSectionSubtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    actionButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FinanceSectionHeader(
                          icon: Icons.payments_outlined,
                          title: l10n.facturationDetailPaymentsSectionTitle,
                          accent: AppColors.financeDetailPaymentsAccent,
                          accentSoft: AppColors.financeDetailPaymentsAccentSoft,
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          l10n.facturationDetailPaymentsSectionSubtitle,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  actionButton,
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          BlocConsumer<PaymentsBloc, PaymentsState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status || prev.errorType != curr.errorType,
            listener: (context, state) {
              if (state.status != PaymentsStatus.failure) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorType.localizedMessage(l10n))),
              );
            },
            buildWhen: (prev, curr) =>
                prev.status != curr.status ||
                prev.payments != curr.payments ||
                prev.errorType != curr.errorType,
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: FinanceMotion.standard,
                switchInCurve: FinanceMotion.outCurve,
                switchOutCurve: FinanceMotion.inCurve,
                child: () {
                  if (state.status == PaymentsStatus.loading) {
                    return const Center(
                      key: ValueKey('payments-loading'),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.status == PaymentsStatus.failure) {
                    return FinanceStateCard(
                      key: const ValueKey('payments-error'),
                      message: state.errorType.localizedMessage(l10n),
                      icon: Icons.error_outline,
                      accent: AppColors.warning,
                      accentSoft: AppColors.financeDetailWarningSoft,
                      actionLabel: l10n.facturationDetailPaymentsRetry,
                      onAction: () => _retry(context),
                    );
                  }

                  if (state.payments.isEmpty) {
                    return FinanceStateCard(
                      key: const ValueKey('payments-empty'),
                      message: l10n.facturationDetailPaymentsEmpty,
                      icon: Icons.inbox_outlined,
                      accent: AppColors.textSecondary,
                      accentSoft: AppColors.financeDetailMutedSurface,
                    );
                  }

                  return FacturationPaymentsTable(
                    key: const ValueKey('payments-table'),
                    payments: state.payments,
                    onViewRequested: onViewPaymentRequested,
                  );
                }(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Bouton CTA principal — encaisser un paiement.
/// Gradient pill avec ombre portée pour un fort impact visuel.
class _CollectPaymentButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CollectPaymentButton({
    required this.label,
    required this.onPressed,
  });

  static const _gradientStart = AppColors.financeDetailPaymentsAccentLight;
  static const _gradientEnd = AppColors.financeDetailPaymentsAccent; // violet ancre

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FinanceMotion.fast,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
          splashColor: AppColors.surface.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.point_of_sale_outlined,
                  color: AppColors.surface,
                  size: AppDimensions.detailMiniIconSize,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  label,
                  style: AppTextStyles.action.copyWith(
                    color: AppColors.surface,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}