import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_flow.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/form/expense_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le registre fait **en plus** pour déclarer (v3) : savoir si la
/// session peut déclarer et viser, obtenir la photo du bon, écrire la
/// déclaration et l'annoncer.
class ExpenseDeclarationActions {
  final BuildContext context;

  const ExpenseDeclarationActions(this.context);

  List<String>? get _permissions =>
      PermissionGate.maybeBlocOf(context)?.state.permissions;

  /// La capture de la photo, si la session peut déclarer — c'est
  /// l'interrupteur de la déclaration (F35) ; sinon `null`, et le formulaire
  /// reste celui de la demande.
  ExpenseVoucherCapture? get voucherCapture {
    final allowed = canAccess(
      requires: kExpenseDeclareAccess.requires,
      permissions: _permissions,
    );
    if (!allowed || !GetIt.instance.isRegistered<DocumentCaptureFlow>()) {
      return null;
    }
    return (context) => GetIt.instance<DocumentCaptureFlow>().run(
      context,
      title: AppLocalizations.of(context)!.expenseVoucherCaptureTitle,
      policy: DocumentCapturePolicy.expenseVoucher,
    );
  }

  /// La session détient `expense.decide` : la déclaration naîtra visée
  /// (F41). La permission, jamais le rôle.
  bool get visaOnDeclare => canAccess(
    requires: kExpenseDecideAccess.requires,
    permissions: _permissions,
  );

  /// Écrit la déclaration et l'annonce ; rend la dépense écrite, ou `null`.
  Future<Expense?> declare(ExpenseDeclarationDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await context.read<ExpenseRegisterCubit>().declare(draft);
    if (!context.mounted) return null;
    return result.fold(
      (_) {
        AppSnackBar.showError(context, l10n.expenseDeclareFailed);
        return null;
      },
      (declared) {
        AppSnackBar.showSuccess(
          context,
          l10n.expenseToastDeclared(ExpenseMoneyText.of(declared)),
        );
        return declared;
      },
    );
  }
}
