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
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_voucher_repository.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_cancellation.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_form_state.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_support.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_outcome.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';
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

  /// Ce que la fiche d'une déclaration demande ; `null` si le module v3
  /// n'est pas monté (tests, harnais).
  ExpenseDeclarationSupport? get support {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ExpenseVoucherRepository>() ||
        !getIt.isRegistered<ExpenseDeclarationCancellation>()) {
      return null;
    }
    final vouchers = getIt<ExpenseVoucherRepository>();
    final cancellation = getIt<ExpenseDeclarationCancellation>();
    return ExpenseDeclarationSupport(
      loadVoucher: vouchers.voucherOf,
      canCancel: cancellation.canCancel,
      canRedeclare: voucherCapture != null,
    );
  }

  /// Régularise une déclaration refusée (F45) : le formulaire s'ouvre en
  /// déclaration, prérempli de son contenu, de son heure et de sa photo. La
  /// nouvelle part sous un nouvel identifiant et retire l'ancienne du
  /// registre, dans la même transaction.
  Future<void> redeclare(
    Expense expense, {
    required List<ExpenseType> types,
    required ExchangeRate? rate,
    String? recordedByName,
  }) async {
    final support = this.support;
    final disbursedAt = expense.disbursedAt;
    if (support == null || disbursedAt == null) return;
    final image = (await support.loadVoucher(
      expense,
    )).fold((_) => null, (image) => image);
    if (!context.mounted) return;
    final mime = DocumentMimeType.values
        .where((m) => m.value == image?.contentType)
        .firstOrNull;
    final outcome = await showExpenseFormDialog(
      context,
      seed: ExpenseFormSeed.duplicate(expense, today: DateTime.now()),
      types: types,
      rate: rate,
      today: DateTime.now(),
      recordedByName: recordedByName,
      captureVoucher: voucherCapture,
      visaOnDeclare: visaOnDeclare,
      redeclaration: ExpenseRedeclaration(
        expenseId: expense.id,
        disbursedAt: disbursedAt,
        voucher: image == null || mime == null
            ? null
            : CapturedDocument(
                bytes: image.bytes,
                mimeType: mime,
                source: DocumentCaptureSource.import,
                sha256Hex: '',
                capturedAt: DateTime.now(),
              ),
      ),
    );
    if (!context.mounted) return;
    if (outcome is ExpenseFormDeclaration) await declare(outcome.draft);
  }
}
