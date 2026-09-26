import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

/// Un versement prêt à écrire : ses lignes, et son reçu provisoire.
class ComposedPayment {
  final PaymentLocalModel payment;
  final List<PaymentAllocationLocalModel> allocations;
  final List<PaymentTenderLocalModel> tenders;
  final GeneratedDocumentLocalModel receipt;

  const ComposedPayment({
    required this.payment,
    required this.allocations,
    required this.tenders,
    required this.receipt,
  });
}

/// Valide un brouillon d'encaissement et compose ses lignes locales — sans rien
/// écrire.
///
/// Partagé par l'encaissement et par la correction d'un versement : le
/// remplaçant EST un encaissement, et il doit passer par les mêmes gardes
/// money-grade. Deux copies de ces gardes finiraient par diverger sur de
/// l'argent.
class PaymentComposer {
  final IdGenerator _idGenerator;
  final CurrentUserContext? _currentUser;
  final OutboxAuthorDirectory? _authorDirectory;
  final DeviceIdentityService? _deviceIdentity;

  const PaymentComposer({
    required IdGenerator idGenerator,
    CurrentUserContext? currentUser,
    OutboxAuthorDirectory? authorDirectory,
    DeviceIdentityService? deviceIdentity,
  }) : _idGenerator = idGenerator,
       _currentUser = currentUser,
       _authorDirectory = authorDirectory,
       _deviceIdentity = deviceIdentity;

  /// [replacesPaymentId] : le versement que celui-ci remplace, pour un
  /// remplaçant de correction.
  Future<Either<Failure, ComposedPayment>> compose(
    RecordPaymentDraft draft, {
    required int nowMs,
    String? replacesPaymentId,
  }) async {
    // Invariant FRONT §6 step7 / §8 : le total du paiement = Σ des
    // allocations — **devise par devise**.
    //
    // Le serveur a resserré `ALLOCATION_SUM_MISMATCH` : un total juste
    // globalement mais mal réparti est désormais refusé. La comparaison
    // scalaire d'avant laissait passer 1 000 $ + 2 000 FC déclarés contre
    // 2 000 $ + 1 000 FC imputés — le total « collait », la répartition non.
    // Le 422 tombait alors sur de l'argent physiquement reçu, reçu déjà
    // imprimé, et l'immobilisait en SYNC_ERROR. Ce fail-fast LOCAL est ce qui
    // l'empêche d'arriver.
    final allocationsBag = MoneyBag.sumBy(
      draft.allocations,
      (a) => Money.parse(a.amountInCents, a.currency),
    );
    final declaredBag = draft.amounts ?? allocationsBag;

    if (declaredBag != allocationsBag) {
      return Left(
        ValidationFailure(
          'Total du paiement ($declaredBag) ≠ somme des allocations '
          '($allocationsBag), devise par devise.',
        ),
      );
    }

    // Un versement à deux devises est un cas NOMINAL : c'est un acte de
    // guichet, donc un versement, un reçu, une notification — pas deux.
    //
    // Reste le refus du versement vide : rien à encaisser n'est pas un
    // encaissement.
    if (allocationsBag.isEmpty || allocationsBag.isAllZero) {
      return const Left(ValidationFailure('Aucun montant à encaisser.'));
    }

    // SECONDE garde, et elle porte sur autre chose que la première.
    //
    // Celle du dessus compare de l'imputé à de l'imputé — `amounts` est en
    // devise de créance — et reste juste quoi qu'il arrive. Celle-ci confronte
    // ce qui est entré dans le TIROIR à ce qui a été imputé, via le taux :
    // sans elle, encaisser 100 000 FC pour une créance de 50 $ quand le taux
    // du jour en vaut 145 000 laisse la créance éteinte, la caisse cohérente,
    // et 45 000 FC partis — invisible à tout contrôle existant.
    //
    // `null` = le parent a réglé dans la devise de la créance : l'identité,
    // c'est-à-dire le cas courant, qui ne coûte aucune arithmétique.
    final tenderDrafts =
        draft.tenders ?? TenderComposition.identityFor(allocationsBag.entries);
    final violation = TenderComposition.check(
      allocations: allocationsBag.entries,
      tenders: tenderDrafts,
    );
    if (violation != null) {
      return Left(ValidationFailure(violation.message));
    }

    // Caissier et appareil sont résolus AVANT la transaction et STAMPÉS sur
    // la ligne : le ticket provisoire est une projection de `payments`, et il
    // doit pouvoir nommer qui a encaissé des mois plus tard, sur une tablette
    // partagée, alors que l'entrée d'outbox qui portait l'auteur aura été
    // supprimée à l'ACK (RG-012-7/11). Best-effort : une identité indisponible
    // laisse les colonnes vides, jamais un encaissement en échec.
    final cashierUid = _currentUser?.uid;
    final cashier = cashierUid == null
        ? null
        : await _resolveCashier(cashierUid);
    final deviceId = await _resolveDeviceId();
    final paymentId = _idGenerator.newId();

    final payment = PaymentLocalModel(
      id: paymentId,
      clientUuid: paymentId,
      studentId: draft.studentId,
      academicYearId: draft.academicYearId,
      method: draft.method ?? 'CASH',
      paidAt: draft.paidAt,
      payerFirstName: draft.payerFirstName,
      payerLastName: draft.payerLastName,
      payerMiddleName: draft.payerMiddleName,
      payerPhoneNumber: draft.payerPhoneNumber,
      cashierUid: cashierUid,
      cashierFirstName: cashier?.firstName,
      cashierLastName: cashier?.lastName,
      deviceId: deviceId,
      replacesPaymentId: replacesPaymentId,
      updatedAt: nowMs,
    );

    final allocations = draft.allocations
        .map(
          (a) => PaymentAllocationLocalModel(
            id: _idGenerator.newId(),
            clientUuid: _idGenerator.newId(),
            paymentId: paymentId,
            studentChargeId: a.studentChargeId,
            feeTariffId: a.feeTariffId,
            feeCode: a.feeCode,
            studentChargeLabel: a.studentChargeLabel,
            amountInCents: a.amountInCents,
            currency: a.currency,
          ),
        )
        .toList();

    final tenders = [
      for (final tender in tenderDrafts)
        PaymentTenderLocalModel(
          id: _idGenerator.newId(),
          clientUuid: _idGenerator.newId(),
          paymentId: paymentId,
          amountInCents: tender.amountInCents,
          currency: tender.currency,
          rateMicros: tender.rateMicros,
          pivotCurrency: tender.pivotCurrency,
        ),
    ];

    final number = provisionalNumber(paymentId, deviceId);
    final receipt = GeneratedDocumentLocalModel(
      id: _idGenerator.newId(),
      docDomain: 'PAYMENT',
      paymentId: paymentId,
      studentId: draft.studentId,
      docType: 'RC',
      number: number,
      provisionalNumber: number,
      createdAt: nowMs,
    );

    return Right(
      ComposedPayment(
        payment: payment,
        allocations: allocations,
        tenders: tenders,
        receipt: receipt,
      ),
    );
  }

  /// Identité affichable du caissier. `null` si l'annuaire ne sait pas répondre
  /// — auquel cas le ticket taira le nom plutôt que d'inventer.
  Future<OutboxAuthorIdentity?> _resolveCashier(String uid) async {
    try {
      return await _authorDirectory?.identityOf(uid);
    } catch (_) {
      return null;
    }
  }

  /// Identifiant d'installation, généré au premier besoin. `null` si le secure
  /// storage est indisponible : l'encaissement prime sur la traçabilité.
  Future<String?> _resolveDeviceId() async {
    try {
      return await _deviceIdentity?.getOrCreateDeviceId();
    } catch (_) {
      return null;
    }
  }

  /// `PROV-<idAppareil>-<8 hex du paiement>` (RG-012-10, zone Z3).
  ///
  /// Le segment appareil est OMIS quand l'identifiant n'a pas pu être résolu :
  /// le format dégradé `PROV-<8 hex>` reste celui déjà produit sur le terrain
  /// avant la v19, donc lisible par tout ce qui existe. Deux formats coexistent
  /// délibérément — aucune migration ne réécrit les numéros déjà remis à des
  /// parents sur du papier.
  static String provisionalNumber(String paymentId, String? deviceId) {
    final suffix = paymentId.substring(0, 8).toUpperCase();
    if (deviceId == null || deviceId.isEmpty) return 'PROV-$suffix';
    return 'PROV-${DeviceIdentityService.shorten(deviceId)}-$suffix';
  }
}
