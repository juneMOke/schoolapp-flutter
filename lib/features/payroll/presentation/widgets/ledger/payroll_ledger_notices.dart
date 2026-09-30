import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les bandeaux du livre, du plus grave au plus doux : refus du dernier geste,
/// renvoi motivé, ce qui empêche le geste suivant, et ce qu'il faut vérifier
/// avant de soumettre.
class PayrollLedgerNotices extends StatelessWidget {
  final PayrollMonthView view;

  const PayrollLedgerNotices({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = PayrollLedgerActions(context);
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final canManage = PermissionGate.allows(
      context,
      kPayrollManageAccess.requires,
    );
    final attendanceMonth = PayrollLabels.month(
      context,
      PayrollMonth.previous(view.month),
    );
    final refusal = view.lastRefusal;
    final returned = view.header?.returnReason;
    final notices = <Widget>[
      if (refusal != null && refusal.isStale)
        Row(
          children: [
            Expanded(
              child: PayrollTone.alert.notice(
                l10n.payrollStaleBanner,
                icon: Icons.sync_problem,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            EteeloButton.secondary(
              label: l10n.payrollStaleOpen,
              onPressed: () => actions.compare(refusal),
              fullWidth: false,
            ),
          ],
        )
      else if (refusal != null)
        PayrollTone.alert.notice(
          l10n.payrollGestureRefused(
            refusal.syncErrorCode ?? refusal.syncError ?? '—',
          ),
          icon: Icons.error_outline,
        ),
      if (view.phase == PayrollPhase.draft && returned != null)
        PayrollTone.alert.notice(
          l10n.payrollReturnedBanner(returned),
          icon: Icons.reply,
        ),
      if (view.phase == PayrollPhase.draft && canWrite)
        if (view.submitBlocker case final blocker?)
          PayrollTone.submitted.notice(
            _blocker(l10n, blocker, attendanceMonth),
          ),
      if (view.phase == PayrollPhase.submitted && canManage) ...[
        if (view.validateBlocker case final blocker?)
          PayrollTone.submitted.notice(
            _blocker(l10n, blocker, attendanceMonth),
          ),
        if (view.attendance == PayrollAttendanceState.unverifiable)
          PayrollTone.draft.notice(
            l10n.payrollAttendanceUnverifiable(attendanceMonth),
          ),
      ],
      if (view.isEditable && view.zeroHourMembers.isNotEmpty)
        PayrollTone.submitted.notice(
          l10n.payrollZeroHours(
            attendanceMonth,
            view.zeroHourMembers.map(actions.nameOf).join(', '),
          ),
          icon: Icons.schedule,
        ),
      if (view.withoutContract.isNotEmpty)
        Row(
          children: [
            Expanded(
              child: PayrollTone.draft.notice(
                l10n.payrollWithoutContract(view.withoutContract.length),
                icon: Icons.assignment_late_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            EteeloButton.ghost(
              label: l10n.payrollOpenStaffFile,
              onPressed: () => context.push(AppRoutesNames.hrStaffFile),
              fullWidth: false,
            ),
          ],
        ),
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, notice) in notices.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            notice,
          ],
        ],
      ),
    );
  }

  static String _blocker(
    AppLocalizations l10n,
    PayrollBlocker blocker,
    String attendanceMonth,
  ) => switch (blocker) {
    PayrollBlocker.previousNotValidated => l10n.payrollBlockerPrevious,
    PayrollBlocker.attendanceOpen => l10n.payrollBlockerAttendance(
      attendanceMonth,
    ),
    PayrollBlocker.emptyLedger => l10n.payrollBlockerEmpty,
    PayrollBlocker.hasDisbursements => l10n.payrollBlockerDisbursed,
  };
}
