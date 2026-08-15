import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charges_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_allocations_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section des allocations (paiements imputés) pour une charge.
/// Affiche une table ETEELO avec les paiements alloués + gestion des états (loading/error/empty/success).
class FacturationChargeAllocationsSection extends StatelessWidget {
  final String chargeId;
  final double paidAmountInCents;
  final String currency;

  const FacturationChargeAllocationsSection({
    super.key,
    required this.chargeId,
    required this.paidAmountInCents,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<StudentChargesBloc, StudentChargesState>(
      listenWhen: _shouldListen,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.allocationsErrorType.localizedMessage(l10n)),
          ),
        );
      },
      buildWhen: _shouldRebuild,
      builder: (context, state) {
        final allocations = state.allocationsByChargeId[chargeId] ?? const [];

        return AnimatedSwitcher(
          duration: FinanceMotion.standard,
          switchInCurve: FinanceMotion.outCurve,
          switchOutCurve: FinanceMotion.inCurve,
          child: () {
            // Même règle que la section Versements : `payment_allocations`
            // n'est peuplée que par le flux paiements. Sans le droit de le
            // lire, la table est vide par construction — le dire « aucune
            // imputation » serait affirmer ce qu'on ne sait pas
            // (ADR-015 §6-C).
            if (!PermissionGate.allows(context, const [
              Perm.financePaymentRead,
            ])) {
              return StateCard(
                key: const ValueKey('charge-allocations-withheld'),
                message: l10n.facturationChargeDetailAllocationsWithheld,
                icon: Icons.lock_outline,
                accent: AppColors.textSecondary,
                accentSoft: AppColors.financeDetailMutedSurface,
              );
            }

            if (state.allocationsStatus == StudentChargesStatus.loading &&
                allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('charge-allocations-loading'),
                message: l10n.loadingStudents,
                icon: Icons.hourglass_top_rounded,
                accent: AppColors.bleuArdoise,
                accentSoft: AppColors.surfaceAlt,
                child: const CircularProgressIndicator(),
              );
            }

            if (state.allocationsStatus == StudentChargesStatus.failure &&
                allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('charge-allocations-error'),
                message: state.allocationsErrorType.localizedMessage(l10n),
                icon: Icons.error_outline,
                accent: AppColors.terreCuite,
                accentSoft: AppColors.papier,
                actionLabel: l10n.facturationChargeDetailAllocationsRetry,
                onAction: () => _retry(context),
              );
            }

            if (allocations.isEmpty) {
              return StateCard(
                key: const ValueKey('charge-allocations-empty'),
                message: l10n.facturationChargeDetailAllocationsEmpty,
                icon: Icons.receipt_long_outlined,
                accent: AppColors.textSecondary,
                accentSoft: AppColors.financeDetailMutedSurface,
              );
            }

            final totalPaid = allocations.fold<double>(
              0,
              (sum, item) => sum + item.amountInCents,
            );

            return Column(
              key: const ValueKey('charge-allocations-content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinanceSectionHeader(
                  icon: Icons.list_alt_outlined,
                  title: l10n.facturationChargeDetailAllocationsSectionTitle,
                  subtitle: null,
                  accent: AppColors.bleuArdoise,
                  accentSoft: AppColors.surfaceAlt,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                FacturationChargeDetailAllocationsTable(
                  allocations: allocations.cast<PaymentAllocation>(),
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
