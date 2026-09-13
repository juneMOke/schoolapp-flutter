import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';

export 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';

// Modèles de fil de la remontée (`POST /api/v1/sync/expenses` et
// `/deletion`). Parsés À LA MAIN, comme les 60 modèles offline du dépôt : un
// `fromJson` généré lèverait sur un champ absent sans distinguer « illisible »
// de « refusé ».
//
// ⚠️ Le round-trip `toJson` → `fromJson` EST le chemin du push : l'outbox
// range le texte, le handler le relit avant de pousser. Un champ perdu à la
// relecture partirait muet sans qu'aucun test de sérialisation ne rougisse —
// d'où des tests jugés sur du JSON brut.

/// L'état **complet** d'une dépense, tel que le poste le remonte
/// (`ExpenseInput`).
class ExpenseInputDto {
  final String id;
  final String typeId;
  final String title;
  final String? description;
  final int amountInCents;
  final String currency;
  final String status;
  final String? paidOn;
  final String expenseDate;
  final String? supplier;
  final String fundingSource;

  /// Horloge d'arbitrage, ISO-8601 UTC — c'est aussi la valeur que l'accusé
  /// compare à la ligne locale pour savoir si une saisie plus récente attend.
  final String clientUpdatedAt;

  const ExpenseInputDto({
    required this.id,
    required this.typeId,
    required this.title,
    this.description,
    required this.amountInCents,
    required this.currency,
    required this.status,
    this.paidOn,
    required this.expenseDate,
    this.supplier,
    required this.fundingSource,
    required this.clientUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'typeId': typeId,
    'title': title,
    'description': description,
    'amountInCents': amountInCents,
    'currency': currency,
    'status': status,
    'paidOn': paidOn,
    'expenseDate': expenseDate,
    'supplier': supplier,
    'fundingSource': fundingSource,
    'clientUpdatedAt': clientUpdatedAt,
  };

  /// Relecture du payload d'outbox — **stricte** : un payload qui ne se relit
  /// pas ne se répare pas en le rejouant.
  factory ExpenseInputDto.fromJson(Map<String, dynamic> j) => ExpenseInputDto(
    id: j['id'] as String,
    typeId: j['typeId'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    amountInCents: (j['amountInCents'] as num).toInt(),
    currency: j['currency'] as String,
    status: j['status'] as String,
    paidOn: j['paidOn'] as String?,
    expenseDate: j['expenseDate'] as String,
    supplier: j['supplier'] as String?,
    fundingSource: (j['fundingSource'] as String?) ?? 'CASH',
    clientUpdatedAt: j['clientUpdatedAt'] as String,
  );
}

/// Corps de `POST /api/v1/sync/expenses` — et payload de l'outbox, qui porte
/// l'auteur à sa racine (`kOutboxAuthorIdKey`) pour la garde d'attribution.
class ExpenseSyncRequestDto {
  final ExpenseInputDto expense;

  /// Uid serveur du compte qui a fait le geste ; omis quand la session ne le
  /// connaît pas (backend hérité sans claim `uid`).
  final String? authorId;

  const ExpenseSyncRequestDto({required this.expense, this.authorId});

  Map<String, dynamic> toJson() => {
    'expense': expense.toJson(),
    kOutboxAuthorIdKey: ?authorId,
  };

  factory ExpenseSyncRequestDto.fromJson(Map<String, dynamic> j) =>
      ExpenseSyncRequestDto(
        expense: ExpenseInputDto.fromJson(j['expense'] as Map<String, dynamic>),
        authorId: j[kOutboxAuthorIdKey] as String?,
      );
}

/// Payload d'outbox d'un retrait ou d'une restauration.
///
/// L'identifiant de la dépense y est rangé parce qu'il part dans le CHEMIN de
/// la requête, pas dans son corps ([toWireJson]).
class ExpenseWithdrawalPayload {
  final String expenseId;
  final bool deleted;

  /// Instant du geste, ISO-8601 UTC — horloge propre au retrait.
  final String changedAt;
  final String? authorId;

  const ExpenseWithdrawalPayload({
    required this.expenseId,
    required this.deleted,
    required this.changedAt,
    this.authorId,
  });

  Map<String, dynamic> toJson() => {'expenseId': expenseId, ...toWireJson()};

  /// Corps de `POST /api/v1/sync/expenses/{id}/deletion`.
  Map<String, dynamic> toWireJson() => {
    'deleted': deleted,
    'changedAt': changedAt,
    kOutboxAuthorIdKey: ?authorId,
  };

  factory ExpenseWithdrawalPayload.fromJson(Map<String, dynamic> j) =>
      ExpenseWithdrawalPayload(
        expenseId: j['expenseId'] as String,
        deleted: j['deleted'] as bool,
        changedAt: j['changedAt'] as String,
        authorId: j[kOutboxAuthorIdKey] as String?,
      );
}

/// Accusé d'une remontée : l'état retenu et l'issue de l'arbitrage.
class ExpenseSyncResponseDto {
  final ExpenseDeltaDto expense;

  /// `APPLIED` ou `SUPERSEDED` ; un serveur muet vaut `APPLIED`.
  final String lwwOutcome;

  const ExpenseSyncResponseDto({
    required this.expense,
    required this.lwwOutcome,
  });

  bool get isSuperseded => lwwOutcome == 'SUPERSEDED';

  /// Lève [FormatException] sur un accusé sans dépense lisible : le handler
  /// le traite en échec LOCAL, donc en tentative — le POST est idempotent.
  factory ExpenseSyncResponseDto.fromJson(Map<String, dynamic> j) {
    final expense = ExpenseDeltaDto.tryParse(j['expense']);
    if (expense == null) {
      throw const FormatException('Accusé de dépense illisible');
    }
    final outcome = j['lwwOutcome'];
    return ExpenseSyncResponseDto(
      expense: expense,
      lwwOutcome: outcome is String ? outcome.trim().toUpperCase() : 'APPLIED',
    );
  }
}
