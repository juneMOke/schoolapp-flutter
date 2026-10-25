import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_advance_payment.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_advance_guard.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/advance/expense_advance_pay_dialog.dart';

/// Avant de payer une avance au personnel, recueillir ce que le geste PAY
/// doit porter (T13). Une dépense ordinaire passe sans question.
abstract final class ExpenseAdvancePayFlow {
  /// `proceed: false` : la caisse a renoncé. Sinon le décaissement, `null`
  /// pour une dépense ordinaire.
  ///
  /// [type] nomme l'avance quand son bloc R.H. est caviardé (caisse sans
  /// `hr.pay.read`) : le geste PAY doit porter le mois et la preuve quand même.
  static Future<({bool proceed, ExpenseAdvancePayment? payment})> run(
    BuildContext context,
    Expense expense,
    ExpenseGesture gesture, {
    ExpenseType? type,
    DateTime Function() now = DateTime.now,
  }) async {
    final isAdvance =
        expense.staffAdvance != null ||
        type?.code == ExpenseStaffAdvance.typeCode;
    if (gesture != ExpenseGesture.pay || !isAdvance) {
      return (proceed: true, payment: null);
    }
    final today = now();
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
    final current = key(today);
    final next = key(DateTime(today.year, today.month + 1));
    final guard = GetIt.instance.isRegistered<ExpenseAdvanceGuard>()
        ? GetIt.instance<ExpenseAdvanceGuard>()
        : null;
    // La paie en cours ne reçoit la retenue que tant qu'elle est en
    // brouillon ; le mois suivant reste toujours possible.
    final currentOpen = await guard?.acceptsFirstMonth(current) ?? false;
    if (!context.mounted) return (proceed: false, payment: null);
    final material = MaterialLocalizations.of(context);
    final payment = await ExpenseAdvancePayDialog.show(
      context,
      ExpenseAdvancePayDialog(
        expense: expense,
        months: [if (currentOpen) current, next],
        monthLabel: (month) => PresenceLabels.month(material, month),
      ),
    );
    return (proceed: payment != null, payment: payment);
  }
}
