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

  /// Date de règlement (A2) ; posée par le geste de paiement, et par lui
  /// seul — jamais dérivée du statut à la sauvegarde (F20).
  final DateTime? paidOn;

  /// Qui a tranché, et quand. `null` tant que rien n'est décidé ; remis à
  /// `null` par une correction ou une annulation de décision.
  final String? decidedById;
  final String? decidedByName;
  final DateTime? decidedAt;

  /// Motif — obligatoire si [ExpenseStatus.refused], `null` sinon.
  final String? decisionReason;

  /// Relances du demandeur ; remises à 0 au retour en attente — une nouvelle
  /// version repart avec un compteur neuf.
  final int reminderCount;

  /// Fraîcheur du fil, **distincte** de [clientUpdatedAt] : un message ne doit
  /// jamais faire perdre une décision à l'arbitrage. Sert aussi l'indice
  /// « n msg » de la liste.
  final DateTime? lastMessageAt;

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
    this.decidedById,
    this.decidedByName,
    this.decidedAt,
    this.decisionReason,
    this.reminderCount = 0,
    this.lastMessageAt,
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

  /// L'argent est engagé pour de bon (approuvée ou payée). **Toute somme du
  /// module passe par là** — jamais par une égalité de statut.
  bool get isFirm => status.isFirm;

  /// Décaissée et soldée — ce qui autorise la ligne « Payée le … ».
  bool get isPaid => status == ExpenseStatus.paid;

  /// Déposée, pas encore décidée : elle attend dans la file.
  bool get isPending => status == ExpenseStatus.pending;

  /// Une décision a été rendue sur cette demande.
  bool get isDecided => decidedAt != null;

  bool get isWithdrawn => deletedAt != null;

  /// Déposée par le compte de la session ? La comparaison se fait sur
  /// l'identifiant, **jamais sur le nom** (F24), et **deux identifiants vides
  /// ne se ressemblent pas** : une ligne sans demandeur connu n'appartient à
  /// personne plutôt qu'à tout le monde.
  bool isRequestedBy(String? accountId) =>
      accountId != null &&
      accountId.isNotEmpty &&
      recordedById != null &&
      recordedById == accountId;

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
    decidedById,
    decidedByName,
    decidedAt,
    decisionReason,
    reminderCount,
    lastMessageAt,
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
