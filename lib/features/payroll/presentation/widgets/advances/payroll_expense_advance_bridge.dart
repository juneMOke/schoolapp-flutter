import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/expense/presentation/bridge/expense_staff_advance_bridge.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advance_decisions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_advance_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pont Dépenses → Paie : « Avance / prêt au personnel » choisi dans
/// Dépenses ▸ Nouvelle demande ouvre le formulaire d'avance de la Paie, qui
/// dépose la même demande de dépense que RH · Paie ▸ Avances & prêts.
class PayrollExpenseAdvanceBridge implements ExpenseStaffAdvanceBridge {
  final LoadPayrollUseCase _load;
  final PayrollCommands Function() _commands;
  final DateTime Function() _now;

  PayrollExpenseAdvanceBridge({
    required LoadPayrollUseCase load,
    required PayrollCommands Function() commands,
    DateTime Function() now = DateTime.now,
  }) : _load = load,
       _commands = commands,
       _now = now;

  @override
  bool allows(List<String>? permissions) =>
      permissions != null &&
      permissions.contains(Perm.hrPayRead.wire) &&
      permissions.contains(Perm.expenseWrite.wire);

  @override
  Future<bool> request(BuildContext context) async {
    final today = SchoolDayCalendar.dayOf(_now());
    final snapshot = (await _load()).fold((_) => null, (s) => s);
    if (!context.mounted) return false;
    void announce(PayrollNotice notice) => showPayrollNotice(
      context,
      notice,
      monthLabel: PayrollLabels.month(context, today.substring(0, 7)),
    );
    if (snapshot == null) {
      announce(const PayrollNotice(PayrollNoticeKind.writeFailed));
      return false;
    }
    final draft = await PayrollAdvanceDialog.show(
      context,
      PayrollAdvanceDialog(snapshot: snapshot, today: today, asRequest: true),
    );
    if (draft == null || !context.mounted) return false;
    final notice = await _commands().requestAdvance(
      snapshot,
      draft,
      title: AppLocalizations.of(context)!.payrollAdvanceExpenseTitle,
      today: DateTime.parse(today),
      amount: MoneyFormat.format(draft.amount),
      recordedByName: PayrollAdvanceDecisions.sessionAgentName(context),
    );
    if (context.mounted) announce(notice);
    return notice.kind == PayrollNoticeKind.advanceRequested;
  }
}
