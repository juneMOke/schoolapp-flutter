import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Modèle de la table `payments`.
class PaymentLocalModel {
  final String id;
  final String clientUuid;
  final String studentId;
  final String? academicYearId;
  final String method;
  final String paidAt;
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28). Nul pour tout versement antérieur au palier
  /// et pour tout versement venu d'un autre poste — la saisie l'exige ici, le
  /// passé n'en a pas.
  final String? payerPhoneNumber;
  final String? status;

  /// Caissier — uid ET nom dénormalisé (v19). Le nom est recopié plutôt que
  /// rejoint : `OutboxAuthorDirectory.identityOf` peut rendre `null`, et
  /// l'entrée d'outbox qui portait l'auteur disparaît à l'ACK. Sans cette
  /// copie, une réimpression de ticket quelques heures plus tard ne pourrait
  /// nommer que l'utilisateur COURANT — faux sur tablette partagée, et c'est
  /// précisément l'imputabilité humaine que RG-012-11 cherche à établir.
  final String? cashierUid;
  final String? cashierFirstName;
  final String? cashierLastName;

  /// Encaisseur tel que le SERVEUR l'attribue (v29), distinct des `cashier_*`
  /// ci-dessus que ce poste stampe lui-même : les deux nomment la même
  /// personne pour un versement encaissé ici, mais seul celui-ci existe quand
  /// le versement vient d'un autre guichet.
  final String? collectedById;
  final String? collectedByName;

  /// Appareil ayant encaissé (zone Z3 du ticket, traçabilité RG-012-16).
  final String? deviceId;

  /// UUID de la pièce scellée côté serveur, capté à l'ACK ou au pull. Seule clé
  /// permettant de re-télécharger le reçu définitif.
  final String? receiptId;

  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  /// L'extourne, en millisecondes epoch. `null` = versement en vigueur.
  ///
  /// Descendue par le pull, jamais écrite au guichet : ce poste encaisse, il
  /// n'annule pas. Une ligne annulée reste affichée — barrée — plutôt que de
  /// disparaître, et surtout elle cesse de compter dans la caisse et dans le
  /// solde des créances.
  final int? cancelledAt;

  const PaymentLocalModel({
    required this.id,
    required this.clientUuid,
    required this.studentId,
    this.academicYearId,
    this.method = 'CASH',
    required this.paidAt,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.status,
    this.cashierUid,
    this.cashierFirstName,
    this.cashierLastName,
    this.collectedById,
    this.collectedByName,
    this.deviceId,
    this.receiptId,
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
    this.cancelledAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'client_uuid': clientUuid,
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'method': method,
    'paid_at': paidAt,
    'payer_first_name': payerFirstName,
    'payer_last_name': payerLastName,
    'payer_middle_name': payerMiddleName,
    'payer_phone_number': payerPhoneNumber,
    'status': status,
    'cashier_uid': cashierUid,
    'cashier_first_name': cashierFirstName,
    'cashier_last_name': cashierLastName,
    'collected_by_id': collectedById,
    'collected_by_name': collectedByName,
    'device_id': deviceId,
    'receipt_id': receiptId,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
    'cancelled_at': cancelledAt,
  };

  /// Colonnes dont le PULL est autoritaire (`openapi_billing_sync`
  /// §PaymentDelta). Sert au patch d'une ligne DÉJÀ connue ; une ligne inconnue
  /// (paiement de l'autre poste) s'insère via [toMap].
  ///
  /// **Exclut l'identité du payeur — téléphone compris — et `client_uuid`** :
  /// le contrat ne les porte pas. Les réécrire depuis un DTO de pull les
  /// remplacerait par le repli `''` — perte définitive du nom saisi au guichet.
  /// Le téléphone (v28) suit la même règle et pour une raison de plus : il est
  /// `null` chez qui ne l'a pas, et un patch le viderait sur le poste MÊME qui
  /// vient de le saisir, dès le premier delta portant ce versement.
  ///
  /// **Exclut surtout l'état de synchro** (`sync_status`, `sync_error`,
  /// `synced_at`) : il appartient à l'ACK et à l'outbox, JAMAIS au pull. Le pull
  /// dit « le serveur connaît ce paiement », pas « ton miroir de créances a
  /// intégré son montant » — or c'est ce second fait que `sync_status` encode
  /// pour la lecture composée. Le passer à SYNCED ici sortirait le paiement du
  /// `paid_pending` (FRONT §5) alors que `student_charges.amount_paid` peut
  /// encore être périmé : la créance s'afficherait IMPAYÉE et le caissier
  /// **réencaisserait**. Seul `applyPaymentAck` bascule SYNCED — et il le fait
  /// dans la MÊME transaction que l'intégration des créances autoritaires.
  /// **Exclut `status` et `method`** : `PaymentDelta` ne porte pas `status` du
  /// tout (le DTO le laisse donc toujours `null` → le patch viderait la colonne
  /// locale), et `method` y est `nullable` alors que `PaymentDto.toLocalModel`
  /// replie sur `'CASH'` — patcher écraserait un `BANK_TRANSFER` saisi au
  /// guichet par un `CASH` inventé. Ces deux colonnes restent celles du poste
  /// qui a encaissé.
  /// **Exclut le caissier et l'appareil** (v19) : ce sont des faits du poste qui
  /// a encaissé, absents du contrat de pull. Les patcher depuis un DTO les
  /// viderait — le ticket perdrait son imputabilité. `receipt_id`, lui, est bien
  /// porté par le delta : c'est le seul moyen de retrouver le reçu définitif
  /// d'un paiement encaissé sur un AUTRE poste.
  Map<String, Object?> toPullPatch() => {
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'paid_at': paidAt,
    if (receiptId != null) 'receipt_id': receiptId,
    // Écrits sous condition, comme `receipt_id` : le delta ne peut qu'AJOUTER
    // l'attribution serveur, jamais l'effacer. Un payload qui les omettrait —
    // versement scellé avant l'évolution du contrat, poste resté en arrière —
    // rendrait sinon anonyme une ligne déjà nommée.
    //
    // Ils ne touchent PAS aux `cashier_*` : ce que ce poste a imprimé sur le
    // ticket ne se réécrit pas depuis le réseau.
    if (collectedById != null) 'collected_by_id': collectedById,
    if (collectedByName != null) 'collected_by_name': collectedByName,
    // Écrite sous condition, et jamais effacée : une extourne ne se défait pas.
    // Un payload qui omettrait le champ — poste resté en arrière, delta scellé
    // avant l'évolution du contrat — remettrait sinon en vigueur un versement
    // annulé, et le ferait recompter dans la caisse.
    if (cancelledAt != null) 'cancelled_at': cancelledAt,
    'updated_at': updatedAt,
  };

  factory PaymentLocalModel.fromMap(Map<String, Object?> m) =>
      PaymentLocalModel(
        id: m['id'] as String,
        clientUuid: m['client_uuid'] as String,
        studentId: m['student_id'] as String,
        academicYearId: m['academic_year_id'] as String?,
        method: (m['method'] as String?) ?? 'CASH',
        paidAt: m['paid_at'] as String,
        // `as String?` et non `as String` : la colonne est nullable depuis la
        // v43, et un cast dur ferait LEVER la lecture d'un versement anonyme —
        // là où rien ne manque, où tout est normal, et où l'écran n'aurait
        // aucun moyen de le dire.
        payerFirstName: m['payer_first_name'] as String?,
        payerLastName: m['payer_last_name'] as String?,
        payerMiddleName: m['payer_middle_name'] as String?,
        payerPhoneNumber: m['payer_phone_number'] as String?,
        status: m['status'] as String?,
        cashierUid: m['cashier_uid'] as String?,
        cashierFirstName: m['cashier_first_name'] as String?,
        cashierLastName: m['cashier_last_name'] as String?,
        collectedById: m['collected_by_id'] as String?,
        collectedByName: m['collected_by_name'] as String?,
        deviceId: m['device_id'] as String?,
        receiptId: m['receipt_id'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
        cancelledAt: m['cancelled_at'] as int?,
      );

  /// [amounts] est **dérivé des imputations**, pas relu d'une colonne : le
  /// versement n'a plus de montant à lui. L'appelant les fournit — c'est le DAO
  /// de lecture qui fait la jointure, en un seul passage pour tout le lot.
  LocalPayment toEntity({MoneyBag amounts = MoneyBag.empty}) => LocalPayment(
    id: id,
    clientUuid: clientUuid,
    studentId: studentId,
    academicYearId: academicYearId,
    amounts: amounts,
    method: PaymentMethod.fromApiValue(method),
    paidAt: paidAt,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    status: status,
    cashierUid: cashierUid,
    cashierFirstName: cashierFirstName,
    cashierLastName: cashierLastName,
    collectedById: collectedById,
    collectedByName: collectedByName,
    deviceId: deviceId,
    receiptId: receiptId,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}
