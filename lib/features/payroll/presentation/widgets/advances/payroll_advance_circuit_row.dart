import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advance_decisions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une demande dans le circuit : l'agent, le montant, où elle en est, et le
/// seul geste possible à qui en a le droit — la direction approuve ou
/// refuse, la caisse décaisse. Les autres lisent qui est attendu.
class PayrollAdvanceCircuitRow extends StatefulWidget {
  final PayrollSnapshot snapshot;
  final PayrollAdvanceRequest request;

  const PayrollAdvanceCircuitRow({
    super.key,
    required this.snapshot,
    required this.request,
  });

  @override
  State<PayrollAdvanceCircuitRow> createState() => _CircuitRowState();
}

class _CircuitRowState extends State<PayrollAdvanceCircuitRow> {
  /// Un geste en vol : un second toucher ne repart pas avec la même copie.
  bool _busy = false;

  Future<void> _decide(ExpenseGesture gesture, String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    await PayrollAdvanceDecisions.run(
      context,
      widget.request,
      gesture,
      name: name,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final request = widget.request;
    final l10n = AppLocalizations.of(context)!;
    final pending = request.status == ExpenseStatus.pending;
    final tone = pending ? PayrollTone.submitted : PayrollTone.validated;
    final installments = request.block.installments;
    final name =
        snapshot.member(request.staffMemberId)?.fullName ??
        request.staffMemberId;
    final decidedAt = request.decidedAt;
    final details = [
      installments > 1
          ? l10n.payrollAdvanceOver(installments)
          : l10n.payrollAdvanceOnce,
      if (!pending && decidedAt != null)
        l10n.payrollAdvanceApprovedOn(
          PayrollLabels.day(context, decidedAt),
          request.decidedByName ?? '—',
        ),
      l10n.payrollAdvanceCircuitVia,
    ];
    final gestures = pending
        ? const [ExpenseGesture.refuse, ExpenseGesture.approve]
        : const [ExpenseGesture.pay];
    final allowed = [
      for (final gesture in gestures)
        if (PermissionGate.allowsAccess(context, expenseGestureAccess(gesture)))
          gesture,
    ];
    VoidCallback? decide(ExpenseGesture gesture) =>
        _busy ? null : () => _decide(gesture, name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge,
                    ),
                    Text(
                      details.join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: allowed.isEmpty
                ? Text(
                    pending
                        ? l10n.payrollAdvanceWaitsDirection
                        : l10n.payrollAdvanceWaitsCash,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final gesture in allowed)
                        switch (gesture) {
                          ExpenseGesture.refuse => EteeloButton.secondary(
                            label: l10n.payrollAdvanceRefuse,
                            icon: Icons.cancel_outlined,
                            onPressed: decide(gesture),
                            fullWidth: false,
                          ),
                          ExpenseGesture.approve => EteeloButton.primary(
                            label: l10n.payrollAdvanceApprove,
                            icon: Icons.verified_outlined,
                            onPressed: decide(gesture),
                            fullWidth: false,
                          ),
                          _ => EteeloButton.primary(
                            label: l10n.payrollAdvanceDisburse,
                            icon: Icons.payments_outlined,
                            onPressed: decide(gesture),
                            fullWidth: false,
                          ),
                        },
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
