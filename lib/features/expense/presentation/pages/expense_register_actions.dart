import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_dialog.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes du registre, orchestrés : modale, écriture, accusé (spec §9).
///
/// Toute écriture produit un accusé — c'est la contrepartie de l'absence de
/// confirmations. Supprimer offre un « Annuler » dans le toast (D4), qui ne
/// ralentit pas le cas nominal comme le ferait une boîte de dialogue.
class ExpenseRegisterActions {
  final BuildContext context;

  const ExpenseRegisterActions(this.context);

  ExpenseRegisterCubit get _cubit => context.read<ExpenseRegisterCubit>();

  Future<void> create() {
    final snapshot = _cubit.state.snapshot;
    return _openForm(
      ExpenseFormSeed.blank(types: snapshot.activeTypes, today: DateTime.now()),
    );
  }

  Future<void> edit(Expense expense) =>
      _openForm(ExpenseFormSeed.edit(expense));

  Future<void> duplicate(Expense expense) =>
      _openForm(ExpenseFormSeed.duplicate(expense, today: DateTime.now()));

  Future<void> _openForm(ExpenseFormSeed seed) async {
    final cubit = _cubit;
    final l10n = AppLocalizations.of(context)!;
    final draft = await showExpenseFormDialog(
      context,
      seed: seed,
      types: _formTypes(seed.typeId),
      rate: cubit.state.snapshot.usdToCdf,
      today: DateTime.now(),
      recordedByName: _agentName(),
    );
    if (draft == null || !context.mounted) return;
    final result = await cubit.save(draft);
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackBar.showError(context, l10n.expenseWriteFailed),
      (saved) {
        _notifyLocalWrite();
        AppSnackBar.showSuccess(
          context,
          seed.isEdit
              ? l10n.expenseToastUpdated(_name(saved))
              : l10n.expenseToastCreated(
                  ExpenseMoneyText.of(saved),
                  saved.status.wireValue,
                ),
        );
      },
    );
  }

  Future<void> open(Expense expense) async {
    final cubit = _cubit;
    // Le fil se lit avant d'ouvrir : une lecture locale est immédiate, et la
    // fiche n'a donc ni squelette ni erreur à porter. `null` = illisible.
    final thread = (await cubit.thread(expense.id)).fold((_) => null, (m) => m);
    if (!context.mounted) return;
    final snapshot = cubit.state.snapshot;
    final choice = await showExpenseDetailDialog(
      context,
      expense: expense,
      type: snapshot.typesById[expense.typeId],
      reader: snapshot.usdReader,
      thread: thread,
      accountId: _agentId(),
    );
    if (choice == null || !context.mounted) return;
    // Un pull a pu redescendre la ligne pendant que la fiche était ouverte :
    // on repart de ce que le registre porte maintenant.
    final latest = cubit.state.snapshot.expenses.firstWhere(
      (e) => e.id == expense.id,
      orElse: () => expense,
    );
    switch (choice) {
      case ExpenseDetailChoice.withdraw:
        await withdraw(latest);
      case ExpenseDetailChoice.duplicate:
        await duplicate(latest);
      case ExpenseDetailChoice.edit:
        await edit(latest);
    }
  }

  Future<void> withdraw(Expense expense) async {
    final cubit = _cubit;
    final l10n = AppLocalizations.of(context)!;
    final result = await cubit.withdraw(expense);
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackBar.showError(context, l10n.expenseWriteFailed),
      (_) {
        _notifyLocalWrite();
        AppSnackBar.showSuccess(
          context,
          l10n.expenseToastWithdrawn(_name(expense)),
          actionLabel: l10n.expenseToastUndo,
          duration: AppSnackBar.undoDuration,
          onAction: () => _restore(cubit, expense, l10n),
        );
      },
    );
  }

  Future<void> _restore(
    ExpenseRegisterCubit cubit,
    Expense expense,
    AppLocalizations l10n,
  ) async {
    final result = await cubit.restore(expense);
    if (!context.mounted) return;
    result.fold(
      (_) => AppSnackBar.showError(context, l10n.expenseWriteFailed),
      (_) {
        _notifyLocalWrite();
        AppSnackBar.showSuccess(
          context,
          l10n.expenseToastRestored(_name(expense)),
        );
      },
    );
  }

  /// Les types offerts : actifs, plus celui de la dépense modifiée s'il a été
  /// masqué depuis — il la nomme encore.
  List<ExpenseType> _formTypes(String currentTypeId) => [
    for (final type in _cubit.state.snapshot.types)
      if (type.active || type.id == currentTypeId) type,
  ];

  static String _name(Expense expense) => expense.number ?? expense.title;

  /// L'identifiant du compte, pour reconnaître ses propres messages dans le
  /// fil (F24) — jamais le nom : deux homonymes dans une école suffiraient à
  /// s'attribuer les messages l'un de l'autre. Vide sur une session héritée,
  /// et il vaut alors `null` : mieux vaut ne reconnaître personne que tout le
  /// monde.
  String? _agentId() {
    final id = PermissionGate.maybeBlocOf(context)?.state.user?.id;
    return id == null || id.isEmpty ? null : id;
  }

  /// L'agent est pris de la session, jamais saisi.
  String? _agentName() {
    final user = PermissionGate.maybeBlocOf(context)?.state.user;
    if (user == null) return null;
    final name = '${user.lastName} ${user.firstName}'.trim();
    return name.isEmpty ? null : name;
  }

  /// Pousse sans attendre le prochain battement ; un harnais sans pastille de
  /// synchro n'a rien à pousser.
  void _notifyLocalWrite() {
    try {
      context.read<SyncStatusCubit>().notifyLocalWrite();
    } on ProviderNotFoundException {
      // Aucune pastille montée : le battement poussera.
    }
  }
}
