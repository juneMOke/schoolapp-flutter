import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Ce que l'agent saisit pour **déclarer** une dépense déjà payée (v3).
///
/// Pas de date de dépense à part : elle **est** le jour du décaissement à
/// Kinshasa (F47), et le serveur refuse un écart
/// (`DECLARATION_DATE_MISMATCH`). La demander deux fois, c'est inviter
/// l'erreur.
class ExpenseDeclarationDraft extends Equatable {
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final String? supplier;
  final ExpenseFundingSource fundingSource;

  /// L'heure du décaissement ; bornée à maintenant à l'écriture.
  final DateTime disbursedAt;

  /// La note libre sur l'accord reçu (« accord du promoteur par WhatsApp »).
  final String note;

  /// La photo du bon, telle que la capture l'a rendue.
  final Uint8List voucherBytes;

  /// `image/jpeg`, `image/png` ou `application/pdf`.
  final String voucherContentType;

  /// L'agent détient `expense.decide` : la déclaration naît visée par lui
  /// (F41). Lu sur la session par l'écran, jamais deviné du rôle.
  final bool visaOnDeclare;

  /// Nom de l'agent connecté, affiché tant que le serveur n'a pas renvoyé le
  /// sien.
  final String? recordedByName;

  /// La déclaration refusée que celle-ci régularise (F45), ou `null`.
  final String? replacing;

  const ExpenseDeclarationDraft({
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    this.supplier,
    this.fundingSource = ExpenseFundingSource.cash,
    required this.disbursedAt,
    this.note = '',
    required this.voucherBytes,
    required this.voucherContentType,
    this.visaOnDeclare = false,
    this.recordedByName,
    this.replacing,
  });

  @override
  List<Object?> get props => [
    typeId,
    title,
    description,
    amountInCents,
    currency,
    supplier,
    fundingSource,
    disbursedAt,
    note,
    voucherBytes.length,
    voucherContentType,
    visaOnDeclare,
    recordedByName,
    replacing,
  ];
}
