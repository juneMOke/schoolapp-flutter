import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que dit un état du circuit. Partagé par la pastille, le filtre de
/// statut et la chaîne de validation — trois lectures du même mot.
String expenseStatusLabel(AppLocalizations l10n, ExpenseStatus status) =>
    switch (status) {
      ExpenseStatus.pending => l10n.expenseStatusPending,
      ExpenseStatus.approved => l10n.expenseStatusApproved,
      ExpenseStatus.paid => l10n.expenseStatusPaid,
      ExpenseStatus.refused => l10n.expenseStatusRefused,
      ExpenseStatus.retracted => l10n.expenseStatusRetracted,
    };

/// Libellé d'une source de fonds.
String expenseFundingLabel(
  AppLocalizations l10n,
  ExpenseFundingSource source,
) => switch (source) {
  ExpenseFundingSource.cash => l10n.expenseFundingCash,
  ExpenseFundingSource.bank => l10n.expenseFundingBank,
  ExpenseFundingSource.mobileMoney => l10n.expenseFundingMobileMoney,
};

/// Ce que dit un acte du fil (F33). Un commentaire libre n'a pas d'acte : le
/// fil l'affiche sans ligne de constat, et il n'y a donc rien à nommer.
String expenseActLabel(AppLocalizations l10n, ExpenseAct act) => switch (act) {
  ExpenseAct.deposit => l10n.expenseActDeposit,
  ExpenseAct.reminder => l10n.expenseActReminder,
  ExpenseAct.approval => l10n.expenseActApproval,
  ExpenseAct.refusal => l10n.expenseActRefusal,
  ExpenseAct.payment => l10n.expenseActPayment,
  ExpenseAct.retraction => l10n.expenseActRetraction,
  ExpenseAct.reopening => l10n.expenseActReopening,
  ExpenseAct.correction => l10n.expenseActCorrection,
  ExpenseAct.edit => l10n.expenseActEdit,
};

/// Le motif d'un refus serveur, dit à l'économe (A4) — par son code machine
/// quand on le connaît, par la phrase générique sinon.
String expenseRejectionLabel(AppLocalizations l10n, String? code) =>
    switch (code) {
      'UNKNOWN_EXPENSE_TYPE' => l10n.expenseRejectedUnknownType,
      'EXPENSE_DATE_IN_FUTURE' => l10n.expenseRejectedDateInFuture,
      'PAYMENT_DATE_IN_FUTURE' => l10n.expenseRejectedPaidOnInFuture,
      'HTTP_403' => l10n.expenseRejectedForbidden,
      _ => l10n.expenseRejectedGeneric,
    };

/// Le mot du bouton qui pose un geste.
///
/// ⚠️ « Retirer » nomme la **reprise par son demandeur**, pas le retrait du
/// registre : celui-ci s'appelle « Supprimer » à l'écran (F25). Les
/// intervertir ferait croire qu'on efface une demande qu'on ne fait que
/// reprendre.
String expenseGestureLabel(AppLocalizations l10n, ExpenseGesture gesture) =>
    switch (gesture) {
      ExpenseGesture.approve => l10n.expenseGestureApprove,
      ExpenseGesture.refuse => l10n.expenseGestureRefuse,
      ExpenseGesture.pay => l10n.expenseGesturePay,
      ExpenseGesture.retract => l10n.expenseGestureRetract,
      ExpenseGesture.resubmit => l10n.expenseGestureResubmit,
      ExpenseGesture.reopen => l10n.expenseGestureReopen,
      ExpenseGesture.remind => l10n.expenseGestureRemind,
      ExpenseGesture.comment => l10n.expenseGestureComment,
    };

/// L'accusé d'un geste posé, nommant la demande.
String expenseGestureToast(
  AppLocalizations l10n,
  ExpenseGesture gesture,
  String name,
) => switch (gesture) {
  ExpenseGesture.approve => l10n.expenseToastApproved(name),
  ExpenseGesture.refuse => l10n.expenseToastRefused(name),
  ExpenseGesture.pay => l10n.expenseToastPaid(name),
  ExpenseGesture.retract => l10n.expenseToastRetracted(name),
  ExpenseGesture.resubmit => l10n.expenseToastResubmitted(name),
  ExpenseGesture.reopen => l10n.expenseToastReopened(name),
  ExpenseGesture.remind => l10n.expenseToastReminded(name),
  ExpenseGesture.comment => l10n.expenseToastCommented(name),
};
