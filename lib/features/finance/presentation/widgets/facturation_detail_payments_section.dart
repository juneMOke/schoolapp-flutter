import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.detailCardPadding),
        decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.financeDetailPaymentsSurface,
            AppColors.financeDetailPaymentsSurfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(
          color: AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;
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
                        Container(
                          width: AppDimensions.spacingL,
                          height: AppDimensions.spacingL,
                          decoration: BoxDecoration(
                            color: AppColors.financeDetailPaymentsAccentSoft,
                            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            size: AppDimensions.detailMiniIconSize,
                            color: AppColors.financeDetailPaymentsAccent,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(
                          l10n.facturationDetailPaymentsSectionTitle,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.financeDetailPaymentsAccent,
                            fontWeight: FontWeight.w700,
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
                        Row(
                          children: [
                            Container(
                              width: AppDimensions.spacingL,
                              height: AppDimensions.spacingL,
                              decoration: BoxDecoration(
                                color: AppColors.financeDetailPaymentsAccentSoft,
                                borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                size: AppDimensions.detailMiniIconSize,
                                color: AppColors.financeDetailPaymentsAccent,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text(
                              l10n.facturationDetailPaymentsSectionTitle,
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.financeDetailPaymentsAccent,
                                fontWeight: FontWeight.w700,
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
              if (state.status == PaymentsStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == PaymentsStatus.failure) {
                return _ErrorCard(
                  message: state.errorType.localizedMessage(l10n),
                  retryLabel: l10n.facturationDetailPaymentsRetry,
                  onRetry: () => _retry(context),
                );
              }

              if (state.payments.isEmpty) {
                return _EmptyCard(message: l10n.facturationDetailPaymentsEmpty);
              }

              return FacturationPaymentsTable(
                payments: state.payments,
                onViewRequested: onViewPaymentRequested,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.financeDetailMutedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.financeDetailMutedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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

  static const _gradientStart = Color(0xFF818CF8); // violet clair
  static const _gradientEnd = AppColors.financeDetailPaymentsAccent; // violet ancre

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          splashColor: Colors.white.withValues(alpha: 0.15),
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
                  color: Colors.white,
                  size: AppDimensions.detailMiniIconSize,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  label,
                  style: AppTextStyles.action.copyWith(
                    color: Colors.white,
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