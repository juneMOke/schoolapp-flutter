import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';

/// Tarif de la grille (référentiel gelé sur la saison). Montant en centimes.
class LocalFeeTariff extends Equatable {
  final String id;
  final String feeCode;
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

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    feeTariffId,
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
  final int amountInCents;
  final String currency;
  final PaymentMethod method;
  final String paidAt; // ISO-8601
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final String? status;
  final SyncState syncState;

  const LocalPayment({
    required this.id,
    required this.clientUuid,
    required this.studentId,
    this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.status,
    this.syncState = SyncState.pendingSync,
  });

  @override
  List<Object?> get props => [
    id,
    clientUuid,
    studentId,
    academicYearId,
    amountInCents,
    currency,
    method,
    paidAt,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    status,
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

  const LocalPaymentAllocation({
    required this.id,
    required this.paymentId,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
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
  ];
}
