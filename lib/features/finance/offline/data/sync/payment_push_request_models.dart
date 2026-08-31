// Requête du PUSH de l'agrégat paiement — miroir strict de
// `openapi_billing_sync.yaml` 1.1.0 §PaymentAggregateRequest
// (`POST /api/v1/sync/payments`).
//
// Forme IMBRIQUÉE : `{payment: {…}, allocations: [{…}]}`. `payment.id` est un
// uuid CLIENT honoré — **clé d'idempotence money-grade** (`ON CONFLICT (id) DO
// NOTHING`) : un rejeu après coupure ne compte JAMAIS l'argent deux fois.
// Centimes `int`, jamais de flottant.

import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une imputation du versement sur une créance (spec `PaymentAllocationInput`).
class PaymentAllocationInput {
  /// uuid client honoré (idempotence fine de l'allocation).
  final String id;

  /// Créance visée : id réel, id **provisoire** (créance générée localement pour
  /// un élève inscrit offline → le serveur remappe par `studentId + feeCode`),
  /// ou `null` = « créance pas encore matérialisée côté client » → remap.
  ///
  /// Ce n'est **PAS** une ligne d'avance/crédit (décision D) : le trop-perçu est
  /// détecté serveur après recompute et signalé via `overpayment`, jamais porté
  /// par une allocation.
  final String? studentChargeId;

  /// Poste — **clé de remap serveur** (INSCRIPTION, MINERVAL_T1, …).
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentAllocationInput({
    required this.id,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentChargeId': studentChargeId,
    'feeCode': feeCode,
    'studentChargeLabel': studentChargeLabel,
    'amountInCents': amountInCents,
    'currency': currency,
  };

  factory PaymentAllocationInput.fromJson(Map<String, dynamic> j) =>
      PaymentAllocationInput(
        id: j['id'] as String,
        studentChargeId: j['studentChargeId'] as String?,
        feeCode: j['feeCode'] as String,
        studentChargeLabel: (j['studentChargeLabel'] as String?) ?? '',
        amountInCents: (j['amountInCents'] as num).toInt(),
        currency: j['currency'] as String,
      );
}

/// L'encaissement lui-même (spec `PaymentInput`).
class PaymentInput {
  /// uuid CLIENT = id serveur honoré (clé d'idempotence money-grade).
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? classroomId;

  /// Ce qui est encaissé, **une entrée par devise**.
  ///
  /// Le serveur vérifie l'égalité avec les imputations **devise par devise**
  /// (422 `ALLOCATION_SUM_MISMATCH`) : un total juste globalement mais mal
  /// réparti est refusé. Ne jamais additionner deux entrées.
  final MoneyBag amounts;
  final String? method; // 'CASH'…
  final String? details;
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28). Nullable dans le contrat bien que la saisie
  /// l'exige : l'outbox peut encore porter un versement mis en file par une
  /// version ANTÉRIEURE de l'app, qui n'en avait aucun. Le refuser ici
  /// bloquerait définitivement de l'argent déjà encaissé, reçu déjà imprimé.
  final String? payerPhoneNumber;
  final String? externalReference;

  /// Heure **métier** de l'encaissement (ISO-8601) — peut être antérieure au
  /// push (ADR-008).
  final String paidAt;

  const PaymentInput({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.classroomId,
    required this.amounts,
    this.method,
    this.details,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.externalReference,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'academicYearId': academicYearId,
    'classroomId': classroomId,
    'amounts': [
      for (final amount in amounts.entries)
        {'amountInCents': amount.amountInCents, 'currency': amount.currency},
    ],
    'method': method ?? 'CASH',
    'details': details,
    'payerFirstName': payerFirstName,
    'payerLastName': payerLastName,
    'payerMiddleName': payerMiddleName,
    'payerPhoneNumber': payerPhoneNumber,
    'externalReference': externalReference,
    'paidAt': paidAt,
  };

  factory PaymentInput.fromJson(Map<String, dynamic> j) => PaymentInput(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    academicYearId: j['academicYearId'] as String?,
    classroomId: j['classroomId'] as String?,
    amounts: _amountsOf(j),
    method: j['method'] as String?,
    details: j['details'] as String?,
    payerFirstName: j['payerFirstName'] as String?,
    payerLastName: j['payerLastName'] as String?,
    payerMiddleName: j['payerMiddleName'] as String?,
    payerPhoneNumber: j['payerPhoneNumber'] as String?,
    externalReference: j['externalReference'] as String?,
    paidAt: j['paidAt'] as String,
  );

  /// Relit les montants d'un payload d'outbox, **quelle que soit sa forme**.
  ///
  /// C'est la TROISIÈME forme que ce parseur doit tolérer, et pour la même
  /// raison que les deux premières : une tablette mise à jour hors ligne porte
  /// encore en file des versements écrits par la version précédente, avec un
  /// `amountInCents` scalaire. Les refuser ici les ferait basculer en `failed`
  /// — issue TERMINALE de l'outbox : le cash encaissé au guichet, reçu déjà
  /// imprimé, ne remonterait JAMAIS et l'élève resterait débiteur.
  ///
  /// Le repli est conservé tant que des tablettes peuvent porter des versements
  /// d'avant la bascule.
  static MoneyBag _amountsOf(Map<String, dynamic> j) {
    final raw = j['amounts'];
    if (raw is List) {
      return MoneyBag.of([
        for (final entry in raw)
          if (entry is Map<String, dynamic>)
            Money.parse(
              (entry['amountInCents'] as num?)?.toInt() ?? 0,
              (entry['currency'] as String?) ?? '',
            ),
      ]);
    }
    // Forme scalaire — payload figé avant la bascule multi-devise.
    final cents = (j['amountInCents'] as num?)?.toInt();
    if (cents == null) return MoneyBag.empty;
    return MoneyBag.from(Money.parse(cents, (j['currency'] as String?) ?? ''));
  }
}

/// L'agrégat complet poussé en UN seul appel (spec `PaymentAggregateRequest`).
class PaymentAggregateRequest {
  final PaymentInput payment;

  /// Répartition du versement (au moins une ligne — `minItems: 1`).
  final List<PaymentAllocationInput> allocations;

  /// Uid de l'auteur (ADR-010 D-05), figé à la saisie. Le serveur (garde A3)
  /// rejette 403 si `authorId ≠ uid` du JWT. `null` = session héritée sans uid.
  final String? authorId;

  const PaymentAggregateRequest({
    required this.payment,
    required this.allocations,
    this.authorId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (authorId != null) 'authorId': authorId,
    'payment': payment.toJson(),
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };

  /// Tolère les DEUX formes, car ce parseur relit des payloads d'outbox écrits
  /// par une version ANTÉRIEURE de l'app :
  ///  - **imbriquée** `{payment: {…}, allocations: […]}` — contrat 1.1.0 ;
  ///  - **à plat** `{id, studentId, …, allocations: […]}` — ancien
  ///    `CreatePaymentRequest`, encore en attente dans l'outbox d'une tablette
  ///    mise à jour hors-ligne.
  ///
  /// Sans ce repli, l'ancien payload lèverait au parse → `failed` (issue
  /// TERMINALE de l'outbox) : le cash encaissé au guichet, reçu déjà imprimé, ne
  /// remonterait JAMAIS et l'élève resterait débiteur. Le repli est conservé
  /// tant que des tablettes peuvent porter des paiements pré-migration.
  factory PaymentAggregateRequest.fromJson(Map<String, dynamic> j) {
    final nested = j['payment'];
    final source = nested is Map<String, dynamic> ? nested : j;
    return PaymentAggregateRequest(
      authorId: j['authorId'] as String?,
      payment: PaymentInput.fromJson(source),
      allocations: (j['allocations'] as List<dynamic>? ?? const [])
          .map(
            (e) => PaymentAllocationInput.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
