// DTOs de pull delta (FF-Lot 2). Grille tarifaire + grand-livre autoritaire.
// Réponses serveur (fromJson) → converties en modèles locaux au upsert.

import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de faire échouer toute la page.
///
/// Money-grade — sans ça, un seul enregistrement fautif (champ requis à `null`,
/// montant absent) fige le curseur de la ressource : le cycle re-tire la même
/// page indéfiniment et le miroir local reste gelé, invisible pour le caissier.
/// La ligne écartée réapparaîtra au prochain delta une fois le serveur corrigé.
/// (Pour un paiement, l'échec d'une allocation nested écarte le paiement ENTIER
/// via ce même filet au niveau de la page — jamais une application partielle.)
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

// `FeeTariffDto` / `FeeTariffDelta` — **RETIRÉS (ADR-015 F8)**. Ils décodaient
// `GET /api/v1/sync/finance/tariffs`, que rien n'appelait : la grille tarifaire
// descend en réalité par le bundle référentiel d'Inscription
// (`RefFeeTariffDto`), qui l'écrit dans la MÊME table locale `fee_tariffs`.
// Deux décodeurs pour une table, un seul branché — celui qui restait donnait à
// croire que Finance tirait ses propres tarifs.

class StudentChargeDto {
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? feeTariffId;
  final String feeCode;
  final String label;
  final int expectedAmountInCents;
  final int amountPaidInCents; // autoritaire
  final String currency;
  final String status;
  final String? dueAt;
  final int version;

  const StudentChargeDto({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.feeTariffId,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.status,
    this.dueAt,
    this.version = 0,
  });

  factory StudentChargeDto.fromJson(Map<String, dynamic> j) => StudentChargeDto(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    academicYearId: j['academicYearId'] as String?,
    schoolLevelId: j['schoolLevelId'] as String?,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
    feeTariffId: j['feeTariffId'] as String?,
    feeCode: j['feeCode'] as String,
    label: j['label'] as String,
    expectedAmountInCents: (j['expectedAmountInCents'] as num).toInt(),
    amountPaidInCents: (j['amountPaidInCents'] as num?)?.toInt() ?? 0,
    currency: j['currency'] as String,
    status: (j['status'] as String?) ?? 'DUE',
    dueAt: j['dueAt'] as String?,
    version: (j['version'] as num?)?.toInt() ?? 0,
  );

  /// Autoritaire : `amount_paid` ET `optimistic_paid` alignés sur le serveur.
  StudentChargeLocalModel toLocalModel(int now) => StudentChargeLocalModel(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    feeTariffId: feeTariffId,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expectedAmountInCents,
    amountPaidInCents: amountPaidInCents,
    optimisticPaidInCents: amountPaidInCents,
    currency: currency,
    // Le contrat de pull émet UNPAID ; le local (créances offline) émet DUE —
    // sémantiquement identiques (rien payé). On normalise pour ne pas mélanger
    // les deux vocabulaires dans la colonne `status`.
    status: status == 'UNPAID' ? 'DUE' : status,
    dueAt: dueAt,
    version: version,
    syncStatus: 'SYNCED',
    syncedAt: now,
    updatedAt: now,
  );
}

class PaymentDto {
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? method;
  final String paidAt;
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro du payeur (v28). Absent des deltas scellés avant l'évolution du
  /// contrat : il ne sert donc qu'à HYDRATER une ligne inconnue (versement d'un
  /// autre poste), jamais à patcher une ligne que ce poste a saisie —
  /// cf. `PaymentLocalModel.toPullPatch`.
  final String? payerPhoneNumber;
  final String? status;

  /// UUID du reçu scellé, porté par `PaymentDelta` (v19). Le serveur l'envoyait
  /// déjà ; le client ne le lisait pas. C'est le seul chemin vers le reçu
  /// définitif d'un versement encaissé sur un AUTRE poste — celui-ci n'a jamais
  /// eu de ligne `generated_documents` locale.
  final String? receiptId;

  /// Encaisseur attribué par le serveur (v29). `GET /sync/payments` l'APLATIT
  /// en deux champs, là où les routes back-office rendent un objet
  /// `collectedBy { id, firstName, lastName }` — le flux de synchro est le seul
  /// contrat que lit ce client.
  final String? collectedById;
  final String? collectedByName;

  /// L'extourne (V122), ISO-8601. `null` = versement en vigueur.
  ///
  /// C'est ce qui permet de **barrer** un encaissement au lieu de le voir
  /// disparaître : une ligne supprimée n'a plus de `server_updated_at` à
  /// comparer et ne peut être annoncée par aucun delta.
  final String? cancelledAt;

  const PaymentDto({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.method,
    required this.paidAt,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.status,
    this.receiptId,
    this.collectedById,
    this.collectedByName,
    this.cancelledAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> j) => PaymentDto(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    academicYearId: j['academicYearId'] as String?,
    method: j['method'] as String?,
    paidAt: j['paidAt'] as String,
    // ⚠️ **Aucun repli sur `''`.** Le serveur rend `null` sur un encaissement
    // anonyme (V114), et le replier écrirait en base un nom de longueur zéro —
    // c'est-à-dire la confusion même que la V114 a supprimée. `null` reste
    // `null` jusqu'à l'écran.
    payerFirstName: j['payerFirstName'] as String?,
    payerLastName: j['payerLastName'] as String?,
    payerMiddleName: j['payerMiddleName'] as String?,
    payerPhoneNumber: j['payerPhoneNumber'] as String?,
    status: j['status'] as String?,
    receiptId: j['receiptId'] as String?,
    collectedById: j['collectedById'] as String?,
    collectedByName: j['collectedByName'] as String?,
    cancelledAt: j['cancelledAt'] as String?,
  );

  PaymentLocalModel toLocalModel(int now) => PaymentLocalModel(
    id: id,
    clientUuid: id,
    studentId: studentId,
    academicYearId: academicYearId,
    method: method ?? 'CASH',
    paidAt: paidAt,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    status: status,
    receiptId: receiptId,
    collectedById: collectedById,
    collectedByName: collectedByName,
    syncStatus: 'SYNCED',
    syncedAt: now,
    updatedAt: now,
    cancelledAt: EpochIsoHelper.tryToEpochMs(cancelledAt),
  );
}

// ── Pull KEYSET (contrat openapi_billing_sync, ADR-008/009) ──────────────────
// Enveloppe de pagination opaque partagée avec l'Inscription (KeysetPageEnvelope
// / KeysetPageDto) : `nextCursor`/`nextWatermark` base64url renvoyés VERBATIM
// sur l'unique paramètre `cursor`, jamais décodés ni recalculés.

/// Page keyset des créances élèves (`GET /api/v1/sync/student-charges`).
class StudentChargePageDto implements KeysetPageDto<StudentChargeDto> {
  @override
  final List<StudentChargeDto> items;
  @override
  final KeysetPageEnvelope page;

  const StudentChargePageDto({required this.items, required this.page});

  factory StudentChargePageDto.fromJson(Map<String, dynamic> j) =>
      StudentChargePageDto(
        items: _lenientList(j['items'], StudentChargeDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Allocation NESTED du pull paiements (schéma minimal `PaymentDelta.allocations`
/// : `id, studentChargeId?, feeCode, studentChargeLabel, amountInCents,
/// currency`) — seul `paymentId` reste implicite, l'allocation étant imbriquée
/// dans son versement.
///
/// **Chaque imputation porte sa propre devise, toujours présente** : elle solde
/// une créance, donc elle en tient exactement une, et la colonne est NOT NULL
/// depuis la création de la table côté serveur. C'est ce qui permet de
/// reconstruire le total par devise du versement **sans faire confiance à
/// `amounts`** — et ce qui a rendu possible de retirer le montant scalaire de
/// `payments`.
///
/// Elle était auparavant reprise du paiement parent : faux dès qu'un versement
/// en porte deux, toutes les imputations héritant de la première.
class PaymentPullAllocationDto {
  final String id;
  final String? studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentPullAllocationDto({
    required this.id,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  factory PaymentPullAllocationDto.fromJson(Map<String, dynamic> j) =>
      PaymentPullAllocationDto(
        id: j['id'] as String,
        studentChargeId: j['studentChargeId'] as String?,
        feeCode: j['feeCode'] as String,
        // Le contrat le déclare requis ; le repli sur le `feeCode` reste, parce
        // qu'un delta scellé avant l'évolution peut encore descendre.
        studentChargeLabel:
            (j['studentChargeLabel'] as String?) ?? j['feeCode'] as String,
        amountInCents: (j['amountInCents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? '',
      );

  PaymentAllocationLocalModel toLocalModel({required String paymentId}) =>
      PaymentAllocationLocalModel(
        id: id,
        clientUuid: id,
        paymentId: paymentId,
        studentChargeId: studentChargeId,
        feeCode: feeCode,
        studentChargeLabel: studentChargeLabel,
        amountInCents: amountInCents,
        currency: currency,
      );
}

/// Item du pull paiements : un paiement (autoritaire, SYNCED) + ses allocations.
class PaymentDeltaDto {
  final PaymentDto payment;
  final List<PaymentPullAllocationDto> allocations;

  /// Ce qui est réellement **entré dans le tiroir**, une entrée par devise
  /// reçue.
  ///
  /// Les imputations disent ce que le versement a **éteint**, en devise de
  /// créance ; celles-ci disent ce qui a été **perçu**. Sans elles, le second
  /// poste voit un versement de 50 USD sans aucun moyen de savoir qu'il a été
  /// encaissé en francs — et son tiroir local dérive de celui du serveur, la
  /// dérive même que ce flux existe pour borner.
  ///
  /// Vides sur un versement d'avant l'alignement du contrat : le poste retombe
  /// alors sur l'identité écrite par le backfill de la v41, jamais sur une
  /// lecture des imputations.
  final List<PaymentPullTenderDto> tenders;

  const PaymentDeltaDto({
    required this.payment,
    required this.allocations,
    this.tenders = const [],
  });

  factory PaymentDeltaDto.fromJson(Map<String, dynamic> j) => PaymentDeltaDto(
    payment: PaymentDto.fromJson(j),
    allocations: (j['allocations'] as List<dynamic>? ?? const [])
        .map(
          (e) => PaymentPullAllocationDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
    tenders: [
      for (final raw in (j['tenders'] as List<dynamic>? ?? const []))
        if (raw is Map<String, dynamic>) PaymentPullTenderDto.fromJson(raw),
    ],
  );

  List<PaymentAllocationLocalModel> allocationModels() =>
      allocations.map((a) => a.toLocalModel(paymentId: payment.id)).toList();

  List<PaymentTenderLocalModel> tenderModels() =>
      tenders.map((t) => t.toLocalModel(paymentId: payment.id)).toList();
}

/// Une ligne d'encaissement, telle qu'elle redescend.
///
/// **Aucun lien vers une imputation**, comme en base : le payeur a posé une
/// somme, pas un billet par poste. La correspondance se dérive du taux, elle ne
/// se transporte pas.
class PaymentPullTenderDto {
  final String id;

  /// Le **net conservé**, jamais le montant présenté.
  final int amountInCents;

  final String currency;

  /// Le taux appliqué, en **décimal** sur le fil. `null` vaut 1.
  final double? rate;

  /// La devise de la **créance** réglée. `null` vaut [currency].
  final String? pivotCurrency;

  const PaymentPullTenderDto({
    required this.id,
    required this.amountInCents,
    required this.currency,
    this.rate,
    this.pivotCurrency,
  });

  /// Lecture **tolérante** : refuser une ligne mal formée ferait perdre le
  /// versement entier au pull, alors qu'il est déjà encaissé et déjà imprimé.
  factory PaymentPullTenderDto.fromJson(Map<String, dynamic> j) =>
      PaymentPullTenderDto(
        id: (j['id'] as String?) ?? '',
        amountInCents: (j['amountInCents'] as num?)?.toInt() ?? 0,
        currency: (j['currency'] as String?) ?? '',
        rate: (j['rate'] as num?)?.toDouble(),
        pivotCurrency: j['pivotCurrency'] as String?,
      );

  PaymentTenderLocalModel toLocalModel({required String paymentId}) {
    final value = rate;
    return PaymentTenderLocalModel(
      id: id,
      // Le versement descendu porte l'identifiant SERVEUR : c'est lui qui fait
      // foi ici, il n'y a pas d'uuid client à remapper.
      clientUuid: id,
      paymentId: paymentId,
      amountInCents: amountInCents,
      currency: currency,
      // Un taux absent, nul ou négatif vaut l'identité : il diviserait ou
      // inverserait de l'argent.
      rateMicros: (value == null || value <= 0)
          ? ExchangeRate.scale
          : (value * ExchangeRate.scale).round(),
      pivotCurrency: pivotCurrency ?? currency,
    );
  }
}

/// Page keyset des paiements (`GET /api/v1/sync/payments`).
class PaymentPageDto implements KeysetPageDto<PaymentDeltaDto> {
  @override
  final List<PaymentDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const PaymentPageDto({required this.items, required this.page});

  factory PaymentPageDto.fromJson(Map<String, dynamic> j) => PaymentPageDto(
    items: _lenientList(j['items'], PaymentDeltaDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
