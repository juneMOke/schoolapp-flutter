import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_thread_composer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les gestes de la file, orchestrés.
///
/// La file **ne crée ni ne modifie** de demande : déposer et corriger restent
/// au registre, qui est le seul écran d'écriture de contenu. Ici on tranche,
/// on relance, on retire — et on ouvre la fiche pour le reste.
class ExpenseQueueActions {
  final BuildContext context;

  const ExpenseQueueActions(this.context);

  ExpenseQueueCubit get _cubit => context.read<ExpenseQueueCubit>();

  /// Ouvre la fiche. [refusing] déplie d'emblée le panneau de motif — c'est
  /// le « Refuser » de la ligne, qui ne part jamais sans son mot.
  Future<void> open(Expense expense, {bool refusing = false}) async {
    final cubit = _cubit;
    final thread = (await cubit.thread(expense.id)).fold((_) => null, (m) => m);
    if (!context.mounted) return;
    final snapshot = cubit.state.snapshot;
    final outcome = await showExpenseDetailDialog(
      context,
      expense: expense,
      type: snapshot.typesById[expense.typeId],
      reader: snapshot.usdReader,
      thread: thread,
      accountId: _agentId(),
      startRefusing: refusing,
      onComment: (body) => _comment(expense, body),
    );
    if (outcome == null || !context.mounted) return;
    // La demande a pu bouger pendant que la fiche était ouverte.
    final latest = cubit.state.view.pending.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );
    switch (outcome) {
      // Les raccourcis d'écran (dupliquer, modifier, supprimer) appartiennent
      // au registre : la file y renvoie plutôt que de rouvrir un formulaire
      // par-dessus une file de décision.
      case ExpenseDetailShortcut():
        context.go(AppRoutesNames.expenseRegister);
      case ExpenseDetailGesture(:final gesture, :final note):
        await applyGesture(latest, gesture, note: note);
    }
  }

  Future<void> applyGesture(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _cubit.applyGesture(
      expense,
      gesture,
      note: note,
      actorName: _agentName(),
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => AppSnackBar.showError(
        context,
        failure is ConflictFailure
            ? l10n.expenseGestureRefused
            : l10n.expenseWriteFailed,
      ),
      (_) {
        _notifyLocalWrite();
        AppSnackBar.showSuccess(
          context,
          expenseGestureToast(l10n, gesture, _name(expense)),
        );
      },
    );
  }

  /// Le lot : une écriture par demande, **un** accusé de synthèse.
  ///
  /// La somme annoncée est celle de la sélection **avant** le lot : après, les
  /// lignes ont quitté la file, et il n'y aurait plus rien à totaliser.
  Future<void> applyBatch(ExpenseGesture gesture, {String note = ''}) async {
    final cubit = _cubit;
    final l10n = AppLocalizations.of(context)!;
    final expenses = cubit.selectedExpenses;
    if (expenses.isEmpty) return;
    final totals = ExpenseTotals.of(expenses, cubit.state.snapshot.usdReader);
    final outcome = await cubit.applyBatch(
      expenses,
      gesture,
      note: note,
      actorName: _agentName(),
    );
    if (!context.mounted) return;
    if (outcome.done == 0) {
      AppSnackBar.showError(context, l10n.expenseQueueBatchNone);
      return;
    }
    _notifyLocalWrite();
    final usd = totals.usdCents;
    if (outcome.failed > 0) {
      // Un lot à moitié passé n'est pas un succès : le dire en avertissement
      // évite de croire la file vidée.
      AppSnackBar.showError(
        context,
        l10n.expenseQueueBatchPartial(outcome.done, outcome.failed),
      );
      return;
    }
    AppSnackBar.showSuccess(
      context,
      usd == null
          ? l10n.expenseQueueSelected(outcome.done)
          : l10n.expenseQueueBatchDone(outcome.done, ExpenseMoneyText.usd(usd)),
    );
  }

  Future<ExpenseCommentResult> _comment(Expense expense, String body) async {
    final cubit = _cubit;
    final written = await cubit.applyGesture(
      expense,
      ExpenseGesture.comment,
      note: body,
      actorName: _agentName(),
    );
    if (written.isLeft()) return (sent: false, thread: null);
    if (context.mounted) _notifyLocalWrite();
    final thread = (await cubit.thread(expense.id)).fold((_) => null, (m) => m);
    return (sent: true, thread: thread);
  }

  static String _name(Expense expense) => expense.number ?? expense.title;

  String? _agentId() {
    final id = PermissionGate.maybeBlocOf(context)?.state.user?.id;
    return id == null || id.isEmpty ? null : id;
  }

  String? _agentName() {
    final user = PermissionGate.maybeBlocOf(context)?.state.user;
    if (user == null) return null;
    final name = '${user.lastName} ${user.firstName}'.trim();
    return name.isEmpty ? null : name;
  }

  void _notifyLocalWrite() {
    try {
      context.read<SyncStatusCubit>().notifyLocalWrite();
    } on ProviderNotFoundException {
      // Aucune pastille montée : le battement poussera.
    }
  }
}
