import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Draft d'une imputation (le repo générera l'uuid client honoré).
class AllocationDraft {
  final String? studentChargeId; // réel | provisoire | null (avance)

  /// Ligne de grille visée — `null` pour une créance *ad hoc*, hors grille.
  ///
  /// **De meilleure autorité que [studentChargeId]** sur le chemin de synchro :
  /// un tarif vient toujours du référentiel servi par le serveur, il ne peut
  /// donc jamais être provisoire.
  final String? feeTariffId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const AllocationDraft({
    this.studentChargeId,
    this.feeTariffId,
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
  final String? method; // défaut CASH
  final String paidAt; // ISO-8601 — date terrain
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur. Requis à la saisie (le CTA reste gris sans lui),
  /// nullable dans le draft : les rejeux d'outbox et les tests d'avant la v28
  /// n'en portent pas.
  final String? payerPhoneNumber;

  /// Ce que le guichet déclare encaisser, **par devise**. `null` → dérivé des
  /// imputations.
  ///
  /// Déclaré ET dérivé sont comparés devise par devise avant écriture : c'est
  /// le fail-fast qui évite un 422 `ALLOCATION_SUM_MISMATCH` sur de l'argent
  /// déjà reçu.
  final MoneyBag? amounts;
  final List<AllocationDraft> allocations;

  const RecordPaymentDraft({
    required this.studentId,
    required this.academicYearId,
    this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.amounts,
    required this.allocations,
  });
}

/// Repository offline-first du module Facturation.
abstract class FinanceOfflineRepository {
  /// Encaisse un paiement en local-first. Renvoie l'id du paiement (uuid client).
  Future<Either<Failure, String>> recordPayment(RecordPaymentDraft draft);

  /// Payeurs à proposer d'emblée pour cet élève : ceux qui ont déjà payé pour
  /// lui, puis ses tuteurs déclarés. Lecture locale, jamais d'erreur métier.
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit,
  });

  /// Recherche un payeur déjà venu à la caisse, toutes fiches élèves
  /// confondues. Sans critère : liste vide.
  Future<Either<Failure, List<LocalPayerIdentity>>> searchPayers({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit,
  });

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

  /// Grille applicable à un niveau sur une année (Contrôle des frais) : tarifs
  /// du niveau **et** tarifs définis au cycle seul.
  Future<Either<Failure, List<LocalFeeTariff>>> getFeeTariffsForLevel({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  });

  /// Position des élèves [studentIds] sur le frais [feeCode] : attendu, payé
  /// (miroir + encaissements non remontés) et reste composé.
  Future<Either<Failure, List<LocalFeeChargeAggregate>>>
  getFeeChargeAggregates({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  });
}
