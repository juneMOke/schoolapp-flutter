import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Tarif de la grille (référentiel gelé sur la saison). Montant en centimes.
class LocalFeeTariff extends Equatable {
  final String id;
  final String feeCode;

  /// Ce qui distingue deux lignes de **même nature** sur un niveau : « T1 » et
  /// « T2 » d'un minerval étalé (v39).
  ///
  /// ⚠️ **Un code égal à [feeCode] ne distingue rien** : le serveur retombe sur
  /// la nature quand l'école n'en saisit pas. Les écrans le traitent comme une
  /// absence — c'est la règle de composition, pas une propriété de ce champ.
  final String? code;

  final String label;
  final int amountInCents;
  final String currency;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? dueAt; // yyyy-MM-dd | null
  final int version;

  const LocalFeeTariff({
    required this.id,
    required this.feeCode,
    this.code,
    required this.label,
    required this.amountInCents,
    required this.currency,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.dueAt,
    this.version = 0,
  });

  @override
  List<Object?> get props => [
    id,
    feeCode,
    code,
    label,
    amountInCents,
    currency,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    dueAt,
    version,
  ];
}

/// Créance du grand-livre. `amountPaidInCents`/`status` sont AUTORITAIRES
/// (miroir serveur, écrits UNIQUEMENT par le pull/ACK). Le solde optimiste NE
/// SE STOCKE PAS : `amountPaidPendingInCents` est la somme des allocations des
/// paiements de CE poste non encore remontés (`sync_status <> 'SYNCED'`),
/// **composée à la lecture** (FRONT §5). On dérive, on n'incrémente jamais
/// (FRONT §8) — `optimisticPaidInCents`/`optimisticRemainingInCents` en découlent.
class LocalStudentCharge extends Equatable {
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? feeTariffId;

  /// Le code de la ligne de grille dont cette créance dépend — « T2 », « OM2 »
  /// — **composé à la lecture** par jointure sur [feeTariffId] (v39).
  ///
  /// Ce n'est pas une colonne de `student_charges` : le serveur ne sert le code
  /// que sur le TARIF, jamais sur la créance. Il est donc `null` chaque fois que
  /// la grille n'est pas jointe — créance *ad hoc* sans tarif, tarif absent de
  /// cet appareil (grille caviardée, année purgée), base d'avant le pull qui a
  /// rempli la colonne.
  ///
  /// ⚠️ **Un code égal à [feeCode] ne distingue rien** : le serveur retombe sur
  /// la nature quand l'école n'en saisit pas. C'est la composition d'affichage
  /// qui l'écarte, pas ce champ — ici on rapporte ce que la grille dit.
  final String? feeTariffCode;

  final String feeCode;
  final String label;
  final int expectedAmountInCents;
  final int amountPaidInCents; // autoritaire (miroir serveur)
  final int
  amountPaidPendingInCents; // composé au read (paiements non remontés)
  final String currency;
  final StudentChargeStatus status; // autoritaire
  final String? dueAt;
  final int version;
  final SyncState syncState;

  const LocalStudentCharge({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.feeTariffId,
    this.feeTariffCode,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    this.amountPaidPendingInCents = 0,
    required this.currency,
    required this.status,
    this.dueAt,
    this.version = 0,
    this.syncState = SyncState.synced,
  });

  /// Déjà payé TOTAL affiché : miroir serveur + encaissements de ce poste non
  /// remontés (FRONT §5 « paid_total »). Dérivé, jamais stocké.
  int get optimisticPaidInCents => amountPaidInCents + amountPaidPendingInCents;

  /// Reste à payer composé : `max(0, expected - paid_total)` (FRONT §5).
  int get optimisticRemainingInCents {
    final remaining = expectedAmountInCents - optimisticPaidInCents;
    return remaining < 0 ? 0 : remaining;
  }

  /// Vrai si le solde optimiste dépasse le dû (« versement > dû », non bloquant).
  bool get isOptimisticallyOverpaid =>
      optimisticPaidInCents > expectedAmountInCents;

  /// Créance locale d'un nouvel élève, jamais poussée (FRONT §5.2).
  bool get isProvisional => syncState == SyncState.provisional;

  /// Vrai si cette créance compte dans le périmètre de [academicYear].
  ///
  /// ⚠️ **Une créance sans année appartient à TOUTES les années.** Ce n'est pas
  /// une tolérance de lecture : `academic_year_id` est nullable par
  /// construction, et tout le domaine Facturation la rattache à l'année
  /// demandée — lecture du grand-livre, garde-fou de génération
  /// (`finance_charge_seed_dao`), paiements.
  ///
  /// La règle vit ici parce qu'elle avait déjà divergé : le solde du ticket
  /// provisoire exigeait l'égalité stricte et imprimait donc une dette **plus
  /// petite** que celle affichée à l'écran, sur un papier remis à un parent.
  /// Un écart dans ce sens ne se rattrape jamais — `optimisticRemainingInCents`
  /// est clampé à zéro, donc une créance écartée n'est compensée nulle part.
  bool belongsToYear(String academicYear) =>
      academicYearId == null || academicYearId == academicYear;

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    feeTariffId,
    feeTariffCode,
    feeCode,
    label,
    expectedAmountInCents,
    amountPaidInCents,
    amountPaidPendingInCents,
    currency,
    status,
    dueAt,
    version,
    syncState,
  ];
}

/// Totaux d'un élève **par devise** (FRONT §5 — la conversion USD/CDF est hors
/// V1, l'agrégation reste donc scopée par devise). `totalPaid` inclut les
/// encaissements de ce poste non remontés (reste composé).
class LocalStudentLedgerTotals extends Equatable {
  final String currency;
  final int totalDueInCents;
  final int totalPaidInCents;
  final int totalRemainingInCents;

  const LocalStudentLedgerTotals({
    required this.currency,
    required this.totalDueInCents,
    required this.totalPaidInCents,
    required this.totalRemainingInCents,
  });

  /// Agrège une liste de créances composées en un total par devise (jamais de
  /// mélange de devises : une entrée par `currency` rencontrée).
  static List<LocalStudentLedgerTotals> byCurrency(
    List<LocalStudentCharge> charges,
  ) {
    final due = <String, int>{};
    final paid = <String, int>{};
    final remaining = <String, int>{};
    for (final c in charges) {
      due[c.currency] = (due[c.currency] ?? 0) + c.expectedAmountInCents;
      paid[c.currency] = (paid[c.currency] ?? 0) + c.optimisticPaidInCents;
      remaining[c.currency] =
          (remaining[c.currency] ?? 0) + c.optimisticRemainingInCents;
    }
    return [
      for (final currency in due.keys)
        LocalStudentLedgerTotals(
          currency: currency,
          totalDueInCents: due[currency]!,
          totalPaidInCents: paid[currency]!,
          totalRemainingInCents: remaining[currency]!,
        ),
    ];
  }

  @override
  List<Object?> get props => [
    currency,
    totalDueInCents,
    totalPaidInCents,
    totalRemainingInCents,
  ];
}

/// Paiement (événement append-only). `id` honoré serveur.
class LocalPayment extends Equatable {
  final String id;
  final String clientUuid;
  final String studentId;
  final String? academicYearId;

  /// Ce qui a été encaissé, **une entrée par devise**, dérivé des imputations.
  ///
  /// Le versement portait un montant scalaire : un résumé de ses allocations,
  /// juste tant qu'il n'y avait qu'une devise. Un passage au guichet qui solde
  /// une créance en dollars et une en francs n'a pas de montant unique.
  final MoneyBag amounts;
  final PaymentMethod method;
  final String paidAt; // ISO-8601
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur (v28), nul quand le versement est antérieur au
  /// palier ou vient d'un autre poste.
  final String? payerPhoneNumber;
  final String? status;

  /// Caissier ayant encaissé — uid et nom dénormalisé (v19). Alimentent la
  /// zone Z3 du ticket provisoire : sur une pièce non scellée, l'imputabilité
  /// humaine se substitue à l'imputabilité cryptographique (RG-012-11).
  final String? cashierUid;
  final String? cashierFirstName;
  final String? cashierLastName;

  /// Encaisseur attribué par le serveur (v29) — le seul renseigné quand le
  /// versement vient d'un autre guichet, où rien de local n'a été stampé.
  final String? collectedById;
  final String? collectedByName;

  /// Appareil ayant encaissé (préfixe du numéro provisoire, traçabilité).
  final String? deviceId;

  /// UUID de la pièce scellée côté serveur, quand il est connu.
  final String? receiptId;

  final SyncState syncState;

  const LocalPayment({
    required this.id,
    required this.clientUuid,
    required this.studentId,
    this.academicYearId,
    this.amounts = MoneyBag.empty,
    required this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
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
    this.syncState = SyncState.pendingSync,
  });

  @override
  List<Object?> get props => [
    id,
    clientUuid,
    studentId,
    academicYearId,
    amounts,
    method,
    paidAt,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    status,
    cashierUid,
    cashierFirstName,
    cashierLastName,
    collectedById,
    collectedByName,
    deviceId,
    receiptId,
    syncState,
  ];
}

/// Imputation d'un paiement sur une créance (append-only immuable).
class LocalPaymentAllocation extends Equatable {
  final String id;
  final String paymentId;
  final String? studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  /// Identité du payeur et date (ISO-8601 local) du paiement joint. Renseignés
  /// par les lectures qui joignent la table `payments` (détail d'un frais) ;
  /// vides / nulls sinon (l'imputation seule ne les porte pas).
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro du payeur, replié depuis le paiement porteur (v28). Nul pour un
  /// versement antérieur au palier ou venu d'un autre poste.
  final String? payerPhoneNumber;
  final String? paidAt;

  /// Code de la ligne de grille sur laquelle l'argent a été reçu (v39), joint
  /// depuis `ref_fee_tariffs` par `fee_tariff_id`.
  ///
  /// ⚠️ **Le LIBELLÉ, lui, est gelé** ([studentChargeLabel]) : c'est ce que le
  /// guichet a validé le jour de l'encaissement, et il ne se recalcule pas. Le
  /// code n'est joint que pour DÉSIGNER la tranche à l'écran — jamais pour
  /// réécrire ce qui a été imprimé.
  final String? feeTariffCode;

  const LocalPaymentAllocation({
    required this.id,
    required this.paymentId,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
    this.payerFirstName = '',
    this.payerLastName = '',
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.paidAt,
    this.feeTariffCode,
  });

  @override
  List<Object?> get props => [
    id,
    paymentId,
    studentChargeId,
    feeCode,
    studentChargeLabel,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    payerPhoneNumber,
    paidAt,
    feeTariffCode,
  ];
}
