import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_advance_payment.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_advance_pay_flow.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_local_write.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_reason_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Trancher une demande d'avance depuis la Paie (spec §10) : approuver tout
/// de suite ; refuser avec un motif, transmis à l'économe ; décaisser avec le
/// mois de première retenue et sa preuve — la même modale que la caisse.
abstract final class PayrollAdvanceDecisions {
  static Future<void> run(
    BuildContext context,
    PayrollAdvanceRequest request,
    ExpenseGesture gesture, {
    required String name,
  }) async {
    final cubit = context.read<PayrollCubit>();
    final l10n = AppLocalizations.of(context)!;
    // La copie relue de la dépense : c'est elle que la modale montre et que
    // le geste emporte.
    final expense = await cubit.commands.advanceExpense(request.expenseId);
    if (!context.mounted) return;
    if (expense == null) {
      cubit.announce(const PayrollNotice(PayrollNoticeKind.writeFailed));
      return;
    }
    var note = '';
    ExpenseAdvancePayment? payment;
    switch (gesture) {
      case ExpenseGesture.refuse:
        final reason = await PayrollReasonDialog.show(
          context,
          title: l10n.payrollAdvanceRefuseTitle,
          confirmLabel: l10n.payrollAdvanceRefuseConfirm,
          hint: l10n.payrollAdvanceRefuseHint,
          destructive: true,
        );
        if (reason == null) return;
        note = reason;
      case ExpenseGesture.pay:
        final flow = await ExpenseAdvancePayFlow.run(context, expense, gesture);
        if (!flow.proceed) return;
        payment = flow.payment;
      default:
        break;
    }
    if (!context.mounted) return;
    final actorName = sessionAgentName(context);
    await cubit.perform(
      (commands) => commands.decideAdvance(
        expense,
        gesture,
        name: name,
        amount: MoneyFormat.format(request.amount),
        note: note,
        actorName: actorName,
        advancePayment: payment,
      ),
    );
    if (context.mounted) notifyPayrollLocalWrite(context);
  }

  /// Le nom de la session, affiché dans le fil de la demande ; c'est son
  /// identifiant, jamais ce nom, qui sert les comparaisons.
  static String? sessionAgentName(BuildContext context) {
    final user = PermissionGate.maybeBlocOf(context)?.state.user;
    if (user == null) return null;
    final name = '${user.lastName} ${user.firstName}'.trim();
    return name.isEmpty ? null : name;
  }
}
