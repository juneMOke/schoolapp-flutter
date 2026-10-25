import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advance_circuit_row.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Dans le circuit de dépense · N » : les avances demandées et pas encore
/// décaissées — à valider, puis à décaisser. Elles se tranchent ici comme
/// dans Dépenses ▸ Validations (spec §10) : ce sont les mêmes gestes de la
/// même dépense.
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
                // La file appartient aux Dépenses : à qui peut l'ouvrir.
                if (canAccessSubMenu(
                  MenuConstants.expenseQueueId,
                  PermissionGate.maybeBlocOf(context)?.state.permissions,
                ))
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
            for (final request in requests)
              PayrollAdvanceCircuitRow(snapshot: snapshot, request: request),
          ],
        ),
      ),
    );
  }

  static int _order(PayrollAdvanceRequest request) =>
      request.status == ExpenseStatus.pending ? 0 : 1;
}
