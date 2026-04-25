import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_consistency_info_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_context_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FacturationPaymentAllocationsSection extends StatelessWidget {
  final String paymentId;
  final int expectedTotalInCents;
  final String currency;

  const FacturationPaymentAllocationsSection({
    super.key,
    required this.paymentId,
    required this.expectedTotalInCents,
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

  String _formatAmount(int cents, String currencyCode) {
    final major = (cents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final wholePart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$wholePart.${parts.last} $currencyCode';
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.financeDetailCardShadowBlur,
            offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
          ),
        ],
      ),
      child: BlocConsumer<PaymentsBloc, PaymentsState>(
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

          if (state.allocationsStatus == PaymentsStatus.loading &&
              allocations.isEmpty) {
            return _StateCard(
              message: l10n.loadingStudents,
              icon: Icons.hourglass_top_rounded,
              accent: AppColors.financeDetailPaymentsAccent,
              accentSoft: AppColors.financeDetailPaymentsAccentSoft,
              child: const Padding(
                padding: EdgeInsets.only(top: AppDimensions.spacingM),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state.allocationsStatus == PaymentsStatus.failure &&
              allocations.isEmpty) {
            return _StateCard(
              message: state.allocationsErrorType.localizedAllocationsMessage(l10n),
              icon: Icons.error_outline,
              accent: AppColors.financeDetailAmber,
              accentSoft: AppColors.financeDetailWarningSoft,
              actionLabel: l10n.facturationDetailPaymentsRetry,
              onAction: () => _retry(context),
            );
          }

          if (allocations.isEmpty) {
            return _StateCard(
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
          final isConsistent = totalPaid == expectedTotalInCents;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: l10n.facturationPaymentAllocationsSectionTitle,
                subtitle: l10n.facturationPaymentAllocationsSectionSubtitle,
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
                  FinanceContextChip(
                    label: _formatAmount(expectedTotalInCents, currency),
                    icon: Icons.summarize_outlined,
                    accent: AppColors.financeDetailTeal,
                    accentSoft: AppColors.financeDetailTealSoft,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              ...allocations.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                  child: _AllocationRow(
                    label: item.studentChargeLabel,
                    amount: _formatAmount(item.amountInCents, item.currency),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              _AllocationRow(
                label: l10n.facturationPaymentAllocationsTotalLabel,
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
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppDimensions.spacingL,
          height: AppDimensions.spacingL,
          decoration: BoxDecoration(
            color: AppColors.financeDetailPaymentsAccentSoft,
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          child: const Icon(
            Icons.list_alt_outlined,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.financeDetailPaymentsAccent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.financeDetailPaymentsAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
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

class _StateCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  const _StateCard({
    required this.message,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.detailHeaderIconSize, color: accent),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: accent),
                ),
              ),
            ],
          ),
          child ?? const SizedBox.shrink(),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
