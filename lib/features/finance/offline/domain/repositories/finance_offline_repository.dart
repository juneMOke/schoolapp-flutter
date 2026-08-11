import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Draft d'une imputation (le repo générera l'uuid client honoré).
class AllocationDraft {
  final String? studentChargeId; // réel | provisoire | null (avance)
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const AllocationDraft({
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });
}

/// Draft d'un encaissement (chemin local-first money-grade).
class RecordPaymentDraft {
  final String studentId;
  final String academicYearId;
  final String currency;
  final String? method; // défaut CASH
  final String paidAt; // ISO-8601 — date terrain
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final int? amountInCents; // si null → Σ allocations
  final List<AllocationDraft> allocations;

  const RecordPaymentDraft({
    required this.studentId,
    required this.academicYearId,
    required this.currency,
    this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.amountInCents,
    required this.allocations,
  });
}

/// Repository offline-first du module Facturation.
abstract class FinanceOfflineRepository {
  /// Encaisse un paiement en local-first. Renvoie l'id du paiement (uuid client).
  Future<Either<Failure, String>> recordPayment(RecordPaymentDraft draft);

  /// La grille tarifaire est-elle présente sur cet appareil pour cette année ?
  /// Sépare « rien à payer » de « rien à annoncer » quand les créances
  /// générées sont vides.
  Future<Either<Failure, bool>> hasFeeGridForYear(String academicYearId);

  /// Génère les créances provisoires d'un nouvel élève depuis la grille (FF5).
  Future<Either<Failure, List<LocalStudentCharge>>> initializeCharges({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
  });

  Future<Either<Failure, List<LocalStudentCharge>>> getCharges(
    String studentId,
  );

  Future<Either<Failure, List<LocalPayment>>> getPayments(String studentId);

  Future<Either<Failure, List<LocalPaymentAllocation>>> getAllocations(
    String paymentId,
  );

  /// Reçu (RC) d'un paiement connu localement, ou `null` s'il n'y en a pas.
  ///
  /// `Right(null)` est le cas normal quand aucune pièce n'a été produite pour
  /// ce paiement — un `Left` ne signale qu'une base illisible.
  Future<Either<Failure, LocalGeneratedDocument?>> getPaymentReceipt(
    String paymentId,
  );
}
