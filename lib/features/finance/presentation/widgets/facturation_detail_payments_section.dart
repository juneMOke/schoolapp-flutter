import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
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
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              final totalPaidInCents = state.payments.fold<int>(
                0,
                (sum, payment) => sum + payment.amountInCents,
              );
              final currency = state.payments.isNotEmpty
                  ? state.payments.first.currency
                  : '';
              final subtitle = state.status == PaymentsStatus.success
                  ? l10n.facturationDetailPaymentsRecordedWithTotal(
                      state.payments.length,
                      formatMonetaryAmountWithCurrency(
                        amount: totalPaidInCents / 100,
                        currency: currency,
                      ),
                    )
                  : l10n.facturationDetailPaymentsSectionSubtitle;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: l10n.facturationDetailPaymentsSectionTitle,
                    subtitle: subtitle,
                    actionLabel: l10n.facturationDetailCollectPaymentAction,
                    onActionPressed: onCreatePaymentRequested,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppDimensions.spacingM),
                  AnimatedSwitcher(
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
                        return StateCard(
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
                        return StateCard(
                          key: const ValueKey('payments-empty'),
                          message: l10n.facturationDetailPaymentsEmpty,
                          icon: Icons.inbox_outlined,
                          accent: AppColors.textSecondary,
                          accentSoft: AppColors.surfaceAlt,
                        );
                      }

                      final sorted = [...state.payments]
                        ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

                      return Column(
                        key: const ValueKey('payments-list'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sorted.length; i++) ...[
                            FacturationPaymentLine(
                              payment: sorted[i],
                              onTap: () => onViewPaymentRequested(sorted[i]),
                            ),
                            if (i < sorted.length - 1)
                              const SizedBox(height: AppDimensions.spacingS),
                          ],
                        ],
                      );
                    }(),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Le bouton « Encaisser un paiement » reste aligné avec le titre tant
        // qu'il y a la place (desktop, 2 colonnes, tablette) ; il ne passe sous
        // le titre que sur petit téléphone.
        final compact = constraints.maxWidth < AppBreakpoints.dataTablePhoneMax;
        final button = EteeloButton.primary(
          label: actionLabel,
          icon: Icons.add,
          onPressed: onActionPressed,
          fullWidth: false,
        );

        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: AppDimensions.spacingXL,
              height: AppDimensions.spacingXL,
              child: Icon(
                Icons.payments_outlined,
                size: AppDimensions.detailHeaderIconSize,
                color: AppColors.bleuArdoise,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.bleuProfond,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppDimensions.spacingM),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppDimensions.spacingM),
            button,
          ],
        );
      },
    );
  }
}
