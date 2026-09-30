import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
      if (view.awaitingFrozenLines)
        PayrollTone.validated.notice(
          l10n.payrollAwaitingFrozen,
          icon: Icons.cloud_download_outlined,
        ),
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
            PayrollLabels.serverRefusal(
              l10n,
              refusal.syncErrorCode ?? refusal.syncError,
              month: attendanceMonth,
            ),
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
            PayrollLabels.rule(l10n, blocker.rule, month: attendanceMonth),
          ),
      if (view.phase == PayrollPhase.submitted && canManage) ...[
        if (view.validateBlocker case final blocker?)
          PayrollTone.submitted.notice(
            PayrollLabels.rule(l10n, blocker.rule, month: attendanceMonth),
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
            if (_navigation(context) case final navigation?
                when PermissionGate.allows(context, [Perm.hrStaffRead])) ...[
              const SizedBox(width: AppSpacing.sm),
              EteeloButton.ghost(
                label: l10n.payrollOpenStaffFile,
                onPressed: () => navigation.add(
                  SubMenuItemSelected(
                    menuId: MenuConstants.hrMenuId,
                    subMenuId: MenuConstants.hrStaffFileId,
                    title: l10n.subMenuStaffFile,
                  ),
                ),
                fullWidth: false,
              ),
            ],
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

  /// La navigation de la coquille ; `null` hors d'elle (page ouverte par sa
  /// route) — le bouton se tait plutôt que d'ouvrir une page nue.
  static NavigationBloc? _navigation(BuildContext context) {
    try {
      return BlocProvider.of<NavigationBloc>(context);
    } catch (_) {
      return null;
    }
  }
}
