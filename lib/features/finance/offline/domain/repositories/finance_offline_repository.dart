import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';

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
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerMiddleName;

  /// Numéro E.164 du payeur. Requis à la saisie (le CTA reste gris sans lui),
  /// nullable dans le draft : les rejeux d'outbox et les tests d'avant la v28
  /// n'en portent pas.
  final String? payerPhoneNumber;

  /// Ce que le guichet déclare encaisser, **par devise**. `null` → dérivé des
  /// imputations.
  ///
  /// ⚠️ **C'est de l'IMPUTÉ**, pas du perçu : la devise est celle de la créance
  /// que chaque montant éteint. Déclaré ET dérivé sont comparés devise par
  /// devise avant écriture — c'est le fail-fast qui évite un 422
  /// `ALLOCATION_SUM_MISMATCH` sur de l'argent déjà reçu.
  ///
  /// Ce que le tiroir a réellement vu est dans [tenders], et rien ne relie les
  /// deux sans le taux.
  final MoneyBag? amounts;

  /// Ce qui est **entré dans le tiroir**, une entrée par couple (devise reçue,
  /// devise de créance). `null` → identité : le parent a réglé dans la devise
  /// de la créance, ce qui est le cas courant.
  ///
  /// Le couple perçu/imputé est vérifié par
  /// `TenderComposition.check` avant écriture : sans cette épreuve,
  /// encaisser 100 000 FC pour une créance de 50 \$ quand le taux du jour en vaut
  /// 145 000 laisse la créance éteinte, la caisse cohérente, et 45 000 FC
  /// partis.
  final List<TenderDraft>? tenders;
  final List<AllocationDraft> allocations;

  const RecordPaymentDraft({
    required this.studentId,
    required this.academicYearId,
    this.method,
    required this.paidAt,
    this.payerFirstName,
    this.payerLastName,
    this.payerMiddleName,
    this.payerPhoneNumber,
    this.amounts,
    this.tenders,
    required this.allocations,
  });
}

/// Repository offline-first du module Facturation.
abstract class FinanceOfflineRepository {
  /// Encaisse un paiement en local-first. Renvoie l'id du paiement (uuid client).
  Future<Either<Failure, String>> recordPayment(RecordPaymentDraft draft);

  /// La série de taux de guichet de l'école, telle que le référentiel la sert.
  ///
  /// Liste vide = « aucun taux » — et l'écran en tire la seule conclusion sûre :
  /// il n'ouvre pas la bascule de devise. Le guichet PROPOSE un taux, il ne
  /// l'invente pas.
  ///
  /// Lecture locale, jamais d'erreur métier : une série illisible se réduit à
  /// une liste vide, elle ne fait pas échouer un encaissement.
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates();

  /// Les **titres de sections** que l'école a écrits, indexés par nature.
  ///
  /// Table vide = « on ne connaît aucun titre » — et l'écran en tire la seule
  /// conclusion sûre : il nomme par la nature localisée. C'est le repli, et il
  /// est **stable** : un cache vide dit toujours la même chose, là où le cache
  /// mémoire du provisioning répondait selon qu'on était passé ou non par
  /// Configuration dans la session.
  ///
  /// ⚠️ **Une section masquée garde son titre.** Masquer dit « ne me la propose
  /// plus à la saisie », jamais « ne sais plus la nommer » : une créance posée
  /// avant le masquage existe toujours, et c'est elle qu'on affiche.
  ///
  /// Lecture locale, jamais d'erreur métier : un cache illisible se réduit à une
  /// table vide, il ne fait pas échouer l'affichage d'une fiche.
  Future<Either<Failure, Map<String, String>>> getFeeSectionTitles();

  /// Pose un taux de guichet dans la série de l'école.
  ///
  /// **Publié sur le serveur, puis mis en cache local** — dans cet ordre, et
  /// jamais l'un sans l'autre. Le pull remplace la table en bloc : un taux écrit
  /// seulement ici disparaîtrait au premier cycle réussi, et la bascule de
  /// devise du guichet s'éteindrait sans un mot.
  ///
  /// Ce n'est pas de l'outbox : un taux ne s'applique pas avant d'exister. Sans
  /// réseau, la pose **échoue et le dit** — c'est un geste de direction, pas un
  /// encaissement qu'on ne peut pas refuser.
  Future<Either<Failure, Unit>> saveExchangeRate({
    required String base,
    required String quote,
    required int rateMicros,
    required DateTime effectiveFrom,
    int? divergenceBandBp,
  });

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

  /// Natures de frais réellement facturées sur l'année — la liste que le
  /// tableau de bord du Contrôle des frais propose à la sélection.
  Future<Either<Failure, List<String>>> getFeeCodesForYear(
    String academicYearId,
  );

  /// Position de TOUTE la population sur le frais [feeCode], ventilée par
  /// niveau, éventuellement bornée au cycle [schoolLevelGroupId].
  Future<Either<Failure, List<LocalFeeLevelAggregate>>>
  getFeeChargePositionsByLevel({
    required String academicYearId,
    required String feeCode,
    String? schoolLevelGroupId,
  });
}
