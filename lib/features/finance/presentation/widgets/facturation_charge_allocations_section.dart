import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_state_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_consistency_info_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_context_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationChargeAllocationsSection extends StatelessWidget {
  final String chargeId;
  final double expectedAmountInCents;
  final String currency;

  const FacturationChargeAllocationsSection({
    super.key,
    required this.chargeId,
    required this.expectedAmountInCents,
    required this.currency,
  });

  // ── BlocConsumer predicates ──────────────────────────────────────────────

  bool _shouldListen(StudentChargesState prev, StudentChargesState curr) =>
      prev.allocationsStatus != curr.allocationsStatus &&
      curr.allocationsStatus == StudentChargesStatus.failure;

  bool _shouldRebuild(StudentChargesState prev, StudentChargesState curr) =>
      prev.allocationsStatus != curr.allocationsStatus ||
      prev.allocationsErrorType != curr.allocationsErrorType ||
      prev.allocationsByChargeId[chargeId] !=
          curr.allocationsByChargeId[chargeId];

  void _retry(BuildContext context) {
    context.read<StudentChargesBloc>().add(
      StudentChargePaymentAllocationsRequested(chargeId: chargeId),
    );
  }

  String _formatAmount(double cents, String currencyCode) {
    final major = (cents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$whole.${parts.last} $currencyCode';
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
      child: BlocConsumer<StudentChargesBloc, StudentChargesState>(
        listenWhen: _shouldListen,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.allocationsErrorType.localizedMessage(l10n),
              ),
            ),
          );
        },
        buildWhen: _shouldRebuild,
        builder: (context, state) {
          final allocations =
              state.allocationsByChargeId[chargeId] ?? const [];

          return AnimatedSwitcher(
            duration: FinanceMotion.standard,
            switchInCurve: FinanceMotion.outCurve,
            switchOutCurve: FinanceMotion.inCurve,
            child: () {
              if (state.allocationsStatus == StudentChargesStatus.loading &&
                  allocations.isEmpty) {
                return FinanceStateCard(
                  key: const ValueKey('charge-allocations-loading'),
                  message: l10n.loadingStudents,
                  icon: Icons.hourglass_top_rounded,
                  accent: AppColors.financeDetailPaymentsAccent,
                  accentSoft: AppColors.financeDetailPaymentsAccentSoft,
                  child: const CircularProgressIndicator(),
                );
              }

              if (state.allocationsStatus == StudentChargesStatus.failure &&
                  allocations.isEmpty) {
                return FinanceStateCard(
                  key: const ValueKey('charge-allocations-error'),
                  message: state.allocationsErrorType.localizedMessage(l10n),
                  icon: Icons.error_outline,
                  accent: AppColors.financeDetailAmber,
                  accentSoft: AppColors.financeDetailWarningSoft,
                  actionLabel: l10n.facturationChargeDetailAllocationsRetry,
                  onAction: () => _retry(context),
                );
              }

              if (allocations.isEmpty) {
                return FinanceStateCard(
                  key: const ValueKey('charge-allocations-empty'),
                  message: l10n.facturationChargeDetailAllocationsEmpty,
                  icon: Icons.inbox_outlined,
                  accent: AppColors.textSecondary,
                  accentSoft: AppColors.financeDetailMutedSurface,
                  actionLabel: l10n.facturationChargeDetailAllocationsRetry,
                  onAction: () => _retry(context),
                );
              }

              final totalPaid = allocations.fold<double>(
                0,
                (sum, item) => sum + item.amountInCents,
              );
              final isConsistent = totalPaid == expectedAmountInCents;

              return Column(
                key: const ValueKey('charge-allocations-content'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FinanceSectionHeader(
                    icon: Icons.list_alt_outlined,
                    title: l10n.facturationChargeDetailAllocationsSectionTitle,
                    subtitle: l10n.facturationChargeDetailAllocationsSectionSubtitle,
                    accent: AppColors.financeDetailPaymentsAccent,
                    accentSoft: AppColors.financeDetailPaymentsAccentSoft,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Wrap(
                    spacing: AppDimensions.spacingS,
                    runSpacing: AppDimensions.spacingS,
                    children: [
                      FinanceContextChip(
                        label: currency,
                        icon: Icons.attach_money_outlined,
                        accent: AppColors.financeDetailPaymentsAccent,
                        accentSoft: AppColors.financeDetailPaymentsAccentSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  ...allocations.map(
                    (item) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.spacingS),
                      child: _AllocationRow(
                        label: item.studentChargeLabel,
                        amount: _formatAmountFromItem(item),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  _AllocationRow(
                    label: l10n.facturationChargeDetailAllocationsTotalLabel,
                    amount: _formatAmount(totalPaid, currency),
                    isTotal: true,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  FinanceConsistencyInfoBar(
                    message: isConsistent
                        ? l10n.facturationPaymentAllocationsConsistencyOk
                        : l10n.facturationPaymentAllocationsConsistencyWarning,
                    isConsistent: isConsistent,
                  ),
                ],
              );
            }(),
          );
        },
      ),
    );
  }

  String _formatAmountFromItem(PaymentAllocation item) {
    final major = (item.amountInCents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$whole.${parts.last} ${item.currency}';
  }
}

class _AllocationRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _AllocationRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: isTotal
            ? AppColors.financeDetailPaymentsAccentSoft
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(
          color: isTotal
              ? AppColors.financeDetailPaymentsAccent.withValues(alpha: 0.22)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
