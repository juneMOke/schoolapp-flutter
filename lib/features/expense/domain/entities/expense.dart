import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Une dépense du registre — un fait plat, sans jointure.
///
/// Le montant reste **dans sa devise d'engagement**, en centimes (francs
/// compris) : il n'est jamais converti ni réécrit. Toute lecture en dollars
/// est un calcul d'affichage.
class Expense extends Equatable {
  /// Fabriqué par le poste ; clé d'idempotence de la remontée.
  final String id;

  /// `DEP-0412`, attribué par le serveur à la première remontée ; `null`
  /// tant que l'accusé n'est pas revenu (« en attente », A3).
  final String? number;
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final ExpenseStatus status;

  /// Date de règlement (A2) ; `null` si non payée.
  final DateTime? paidOn;

  /// Date de la dépense, pas de la saisie.
  final DateTime expenseDate;
  final String? supplier;
  final ExpenseFundingSource fundingSource;
  final String? recordedById;

  /// Nom de l'agent qui a saisi ; `null` pour une écriture système ou une
  /// saisie locale pas encore accusée.
  final String? recordedByName;

  /// Horloge d'arbitrage du contenu (dernier écrit gagne), UTC.
  final DateTime clientUpdatedAt;

  /// Instant du retrait ; une dépense retirée quitte le registre.
  final DateTime? deletedAt;
  final ExpenseSyncState syncState;

  /// `detailCode` du dernier refus serveur (A4), ou `null`.
  final String? syncErrorCode;

  const Expense({
    required this.id,
    this.number,
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    required this.status,
    this.paidOn,
    required this.expenseDate,
    this.supplier,
    this.fundingSource = ExpenseFundingSource.cash,
    this.recordedById,
    this.recordedByName,
    required this.clientUpdatedAt,
    this.deletedAt,
    this.syncState = ExpenseSyncState.synced,
    this.syncErrorCode,
  });

  bool get isPaid => status == ExpenseStatus.paid;

  bool get isWithdrawn => deletedAt != null;

  bool get isRejected => syncState == ExpenseSyncState.rejected;

  /// `YYYY-MM-DD` — clé de période et de groupe de jour.
  String get dayKey => ExpenseDay.format(expenseDate);

  @override
  List<Object?> get props => [
    id,
    number,
    typeId,
    title,
    description,
    amountInCents,
    currency,
    status,
    paidOn,
    expenseDate,
    supplier,
    fundingSource,
    recordedById,
    recordedByName,
    clientUpdatedAt,
    deletedAt,
    syncState,
    syncErrorCode,
  ];
}
