import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher.dart';

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

  /// Le bloc R.H. d'une avance au personnel (`STAFF_ADVANCE`) ; `null`
  /// ailleurs, ou caviardé pour qui ne lit pas la paie (T14).
  final ExpenseStaffAdvance? staffAdvance;
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

  // ── La déclaration et son visa (v3) ─────────────────────────────────────

  /// Figé à la création (F36).
  final ExpenseMode mode;

  /// `null` hors déclaration — un second axe, jamais lu dans [status].
  final ExpenseVisaStatus? visaStatus;
  final String? visaById;
  final String? visaByName;
  final DateTime? visaAt;

  /// Non nul si et seulement si la déclaration est signalée.
  final String? flagReason;

  /// L'heure du décaissement (`paidAt` du serveur).
  final DateTime? disbursedAt;

  /// La journée de caisse de la sortie, que lit la garde de l'annulation
  /// (F44) ; `null` sans ligne au registre de caisse.
  final DateTime? cashDay;

  /// La sortie est arrivée après une clôture : elle compte pour la journée
  /// ouverte suivante.
  final bool afterClosure;

  final ExpenseVoucher? voucher;

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
    this.staffAdvance,
    this.fundingSource = ExpenseFundingSource.cash,
    this.recordedById,
    this.recordedByName,
    required this.clientUpdatedAt,
    this.deletedAt,
    this.syncState = ExpenseSyncState.synced,
    this.syncErrorCode,
    this.mode = ExpenseMode.authorization,
    this.visaStatus,
    this.visaById,
    this.visaByName,
    this.visaAt,
    this.flagReason,
    this.disbursedAt,
    this.cashDay,
    this.afterClosure = false,
    this.voucher,
  });

  /// Le montant **dans sa devise d'engagement** — la seule forme sous
  /// laquelle il se transporte. La lecture en dollars est un calcul
  /// d'affichage, faite par `ExpenseUsdReader` et jamais rangée ici.
  Money get money => Money(amountInCents, currency);

  /// L'argent est engagé pour de bon (approuvée ou payée). **Toute somme du
  /// module passe par là** — jamais par une égalité de statut.
  ///
  /// Une déclaration refusée par le serveur n'en est pas (F45) : le serveur
  /// ne l'a jamais comptée, et la compter ici ferait lire deux totaux
  /// différents. L'argent ne compte plus que par sa redéclaration.
  bool get isFirm => status.isFirm && !isDeclarationToRegularize;

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

  bool get isDeclaration => mode == ExpenseMode.declaration;

  /// Une déclaration que le serveur a refusée pour de bon, sans jamais
  /// l'enregistrer (pas de numéro) : l'argent est sorti, le serveur n'en sait
  /// rien. « À régulariser » (F45), par une redéclaration.
  bool get isDeclarationToRegularize =>
      isDeclaration && isRejected && number == null;

  /// Une déclaration annulée (F43) : `RETRACTED` en mode déclaration. Elle
  /// se dit « Annulée », jamais « Retirée », et elle est terminale.
  bool get isCancelledDeclaration =>
      isDeclaration && status == ExpenseStatus.retracted;

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
    staffAdvance,
    fundingSource,
    recordedById,
    recordedByName,
    clientUpdatedAt,
    deletedAt,
    syncState,
    syncErrorCode,
    mode,
    visaStatus,
    visaById,
    visaByName,
    visaAt,
    flagReason,
    disbursedAt,
    cashDay,
    afterClosure,
    voucher,
  ];
}
