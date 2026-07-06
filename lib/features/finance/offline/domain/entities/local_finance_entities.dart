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
/// (pull/ACK) ; `optimisticPaidInCents` porte l'affichage local (encaissement).
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
  final int amountPaidInCents; // autoritaire
  final int optimisticPaidInCents; // affichage
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
    required this.optimisticPaidInCents,
    required this.currency,
    required this.status,
    this.dueAt,
    this.version = 0,
    this.syncState = SyncState.synced,
  });

  /// Reste optimiste (affichage) : `max(0, expected - optimiste)`.
  int get optimisticRemainingInCents {
    final remaining = expectedAmountInCents - optimisticPaidInCents;
    return remaining < 0 ? 0 : remaining;
  }

  /// Vrai si le solde optimiste dépasse le dû (« versement > dû », non bloquant).
  bool get isOptimisticallyOverpaid =>
      optimisticPaidInCents > expectedAmountInCents;

  bool get isProvisional => syncState == SyncState.pendingSync;

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
    optimisticPaidInCents,
    currency,
    status,
    dueAt,
    version,
    syncState,
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
