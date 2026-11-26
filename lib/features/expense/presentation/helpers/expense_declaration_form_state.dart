import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';

/// Ce que le formulaire saisit **en plus** pour une déclaration : la photo
/// du bon et la note sur l'accord reçu.
///
/// L'heure du décaissement ne se saisit pas (écart de recette E1, F49) :
/// c'est l'instant où l'agent appuie sur « Déclarer ». Un décaissement
/// antidaté fausserait une caisse déjà clôturée.
class ExpenseDeclarationFormState {
  CapturedDocument? voucher;
  final TextEditingController note = TextEditingController();

  /// La déclaration refusée que celle-ci régularise (F45), ou `null`.
  final String? replacing;

  /// L'instant du décaissement d'origine, repris tel quel par une
  /// redéclaration : l'argent est sorti à ce moment-là. `null` pour une
  /// déclaration neuve.
  final DateTime? redeclaredAt;

  ExpenseDeclarationFormState() : replacing = null, redeclaredAt = null;

  /// Reprend une déclaration refusée : même instant, même photo — un nouvel
  /// identifiant à l'écriture. La note n'est pas reprise : elle vit au fil,
  /// et la ligne ne la porte pas.
  ExpenseDeclarationFormState.redeclaring(ExpenseRedeclaration from)
    : voucher = from.voucher,
      replacing = from.expenseId,
      redeclaredAt = from.disbursedAt.toUtc();

  /// L'instant UTC du décaissement : celui d'origine pour une redéclaration,
  /// [now] sinon.
  DateTime disbursedAt(DateTime now) => redeclaredAt ?? now.toUtc();

  bool get hasVoucher => voucher != null;

  /// La déclaration, à partir du contenu saisi au formulaire commun ; `null`
  /// tant qu'il manque la photo.
  ExpenseDeclarationDraft? draft(
    ExpenseDraft content, {
    required bool visaOnDeclare,
    required DateTime now,
  }) {
    final voucher = this.voucher;
    if (voucher == null) return null;
    return ExpenseDeclarationDraft(
      typeId: content.typeId,
      title: content.title,
      description: content.description,
      amountInCents: content.amountInCents,
      currency: content.currency,
      supplier: content.supplier,
      fundingSource: content.fundingSource,
      disbursedAt: disbursedAt(now),
      note: note.text,
      voucherBytes: voucher.bytes,
      voucherContentType: voucher.mimeType.value,
      visaOnDeclare: visaOnDeclare,
      recordedByName: content.recordedByName,
      replacing: replacing,
    );
  }

  void dispose() => note.dispose();
}

/// Ce qu'une redéclaration reprend de la déclaration refusée (F45).
class ExpenseRedeclaration {
  final String expenseId;
  final DateTime disbursedAt;

  /// `null` quand la photo d'origine ne se relit plus : l'agent en prend une
  /// autre, la déclaration refusée part quand même du registre.
  final CapturedDocument? voucher;

  const ExpenseRedeclaration({
    required this.expenseId,
    required this.disbursedAt,
    this.voucher,
  });
}
