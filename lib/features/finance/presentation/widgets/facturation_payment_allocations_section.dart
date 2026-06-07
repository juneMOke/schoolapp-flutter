import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_allocations_table.dart';

class FacturationPaymentAllocationsSection extends StatelessWidget {
  final String paymentId;
  final String currency;

  const FacturationPaymentAllocationsSection({
    super.key,
    required this.paymentId,
    required this.currency,
  });

  void _retry(BuildContext context) {
    context.read<PaymentsBloc>().add(
      PaymentsAllocationsRequested(paymentId: paymentId),
    );
  }

  // ── BlocConsumer predicates ──────────────────────────────────────────────

  bool _shouldListen(PaymentsState prev, PaymentsState curr) =>
      prev.allocationsStatus != curr.allocationsStatus &&
      curr.allocationsStatus == PaymentsStatus.failure;

  bool _shouldRebuild(PaymentsState prev, PaymentsState curr) =>
      prev.allocationsStatus != curr.allocationsStatus ||
      prev.allocationsErrorType != curr.allocationsErrorType ||
      prev.allocationsByPaymentId[paymentId] !=
          curr.allocationsByPaymentId[paymentId];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PaymentsBloc, PaymentsState>(
      listenWhen: _shouldListen,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.allocationsErrorType.localizedAllocationsMessage(l10n),
            ),
          ),
        );
      },
      buildWhen: _shouldRebuild,
      builder: (context, state) {
        final allocations = state.allocationsByPaymentId[paymentId] ?? const [];

        return AnimatedSwitcher(
          duration: FinanceMotion.standard,
          switchInCurve: FinanceMotion.outCurve,
          switchOutCurve: FinanceMotion.inCurve,
          child: () {
            if (state.allocationsStatus == PaymentsStatus.loading &&
                allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('payment-allocations-loading'),
                message: l10n.loadingStudents,
                icon: Icons.hourglass_top_rounded,
                accent: AppColors.bleuArdoise,
                accentSoft: AppColors.surfaceAlt,
                child: const CircularProgressIndicator(),
              );
            }

            if (state.allocationsStatus == PaymentsStatus.failure &&
                allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('payment-allocations-error'),
                message: state.allocationsErrorType.localizedAllocationsMessage(
                  l10n,
                ),
                icon: Icons.error_outline,
                accent: AppColors.terreCuite,
                accentSoft: AppColors.papier,
                actionLabel: l10n.facturationDetailPaymentsRetry,
                onAction: () => _retry(context),
              );
            }

            if (allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('payment-allocations-empty'),
                message: l10n.facturationPaymentAllocationsEmpty,
                icon: Icons.inbox_outlined,
                accent: AppColors.textSecondary,
                accentSoft: AppColors.financeDetailMutedSurface,
                actionLabel: l10n.facturationDetailPaymentsRetry,
                onAction: () => _retry(context),
              );
            }

            final totalPaid = allocations.fold<int>(
              0,
              (sum, item) => sum + item.amountInCents,
            );

            return Column(
              key: const ValueKey('payment-allocations-content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceSectionHeader(
                  icon: Icons.list_alt_outlined,
                  title: l10n.facturationPaymentAllocationsSectionTitle,
                  subtitle: null,
                  accent: AppColors.bleuArdoise,
                  accentSoft: AppColors.surfaceAlt,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                FacturationPaymentDetailAllocationsTable(
                  allocations: allocations,
                  totalInCents: totalPaid,
                  currency: currency,
                ),
              ],
            );
          }(),
        );
      },
    );
  }
}
