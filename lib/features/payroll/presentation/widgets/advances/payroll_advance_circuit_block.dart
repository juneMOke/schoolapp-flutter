import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Dans le circuit de dépense · N » : les avances demandées et pas encore
/// décaissées — à valider, puis à décaisser. Elles se tranchent dans
/// Dépenses ▸ Validations, la seule file de validation (B5).
class PayrollAdvanceCircuitBlock extends StatelessWidget {
  final PayrollSnapshot snapshot;

  const PayrollAdvanceCircuitBlock({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final requests = [
      for (final request in snapshot.advanceRequests)
        if (request.isInCircuit) request,
    ]..sort((a, b) => _order(a).compareTo(_order(b)));
    if (requests.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Text(
                  l10n.payrollAdvanceCircuitTitle(requests.length),
                  style: AppTypography.labelLarge,
                ),
                EteeloButton.secondary(
                  label: l10n.payrollAdvanceCircuitOpen,
                  icon: Icons.fact_check_outlined,
                  onPressed: () => context.go(
                    AppRoutesNames.homeSubMenuPath(
                      MenuConstants.expenseQueueId,
                    ),
                  ),
                  fullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final request in requests) _Row(snapshot, request),
          ],
        ),
      ),
    );
  }

  static int _order(PayrollAdvanceRequest request) =>
      request.status == ExpenseStatus.pending ? 0 : 1;
}

class _Row extends StatelessWidget {
  final PayrollSnapshot snapshot;
  final PayrollAdvanceRequest request;

  const _Row(this.snapshot, this.request);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = request.status == ExpenseStatus.pending;
    final tone = pending ? PayrollTone.submitted : PayrollTone.validated;
    final installments = request.block.installments;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.xxxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.member(request.staffMemberId)?.fullName ??
                      request.staffMemberId,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
                Text(
                  [
                    installments > 1
                        ? l10n.payrollAdvanceOver(installments)
                        : l10n.payrollAdvanceOnce,
                    l10n.payrollAdvanceCircuitVia,
                  ].join(' · '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormat.format(request.amount),
                style: AppTypography.labelLarge.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                pending
                    ? l10n.payrollAdvanceCircuitToApprove
                    : l10n.payrollAdvanceCircuitToPay,
                style: AppTypography.labelSmall.copyWith(color: tone.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
