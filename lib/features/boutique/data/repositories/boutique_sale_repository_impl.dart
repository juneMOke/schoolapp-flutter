import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_sync_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sale_repository.dart';

/// Encaissement local-first : la vente est écrite, l'outbox la portera.
///
/// **Rien ici n'attend le réseau.** Le guichet rend la monnaie et l'article
/// avant que le serveur ne sache quoi que ce soit — c'est le cas d'usage normal
/// d'une caisse, pas une dégradation.
class BoutiqueSaleRepositoryImpl implements BoutiqueSaleRepository {
  final BoutiqueSaleWriteDao _dao;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;
  final DeviceIdentityService _device;
  final Clock _now;

  /// La série de taux, relue **ici** et non reçue de l'écran : l'UI ne peut pas
  /// fabriquer un couple perçu/vendu que la base ne justifierait pas.
  final ExchangeRateReader? _rates;

  const BoutiqueSaleRepositoryImpl({
    required BoutiqueSaleWriteDao dao,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
    required DeviceIdentityService device,
    Clock now = systemClock,
    ExchangeRateReader? rates,
  }) : _dao = dao,
       _currentUser = currentUser,
       _ids = ids,
       _device = device,
       _now = now,
       _rates = rates;

  @override
  Future<Either<Failure, RecordedSale>> recordSale({
    required BoutiqueCart cart,
    required String academicYearId,
    String? cashierName,
  }) async {
    // Fail-fast LOCAL plutôt que de subir un refus serveur : un 422 arriverait
    // sur une vente déjà encaissée, immobiliserait l'argent en SYNC_ERROR, et
    // ne dirait au guichet rien qu'il puisse corriger.
    if (!cart.canCollect) {
      return const Left(
        ValidationFailure('Le panier n\'est pas prêt à être encaissé.'),
      );
    }
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      // Sans école, l'entrée d'outbox serait inéligible au flush scopé — elle
      // dormirait indéfiniment sans que rien ne le signale.
      return const Left(
        ValidationFailure('Aucune école courante : vente non enregistrée.'),
      );
    }
    final authorId = _currentUser.uid;
    if (authorId == null || authorId.isEmpty) {
      // `authorId` est vérifié par le serveur (403 si ce n'est pas le pousseur).
      // Pousser sans lui produirait un refus terminal sur de l'argent reçu.
      return const Left(
        ValidationFailure('Aucun utilisateur courant : vente non enregistrée.'),
      );
    }

    try {
      final nowMs = _now();
      final soldAt = DateTime.now().toUtc().toIso8601String();
      final saleId = _ids.newId();
      final payer = cart.payer;
      // La vente porte ses montants PAR DEVISE, et chaque ligne la sienne : un
      // panier qui règle 450,00 $ d'uniformes et 90 000 FC de manuels est un
      // acte de caisse — une vente, un reçu, pas deux.
      //
      // Une devise dont les lignes totalisent zéro — un article offert — n'a
      // pas à figurer dans `amounts` : `withoutZeros` s'en charge.
      final amounts = cart.totals.withoutZeros;
      final deviceId = await _resolveDeviceId();

      final lines = <BoutiqueSaleLineLocalModel>[];
      final wireLines = <BoutiqueSaleLineInput>[];
      for (var index = 0; index < cart.lines.length; index++) {
        final line = cart.lines[index];
        // `canCollect` l'a déjà garanti ; on ne déréférence pas un prix nul sur
        // la foi d'un contrôle fait ailleurs.
        final unitPrice = line.unitPriceInCents;
        final lineTotal = line.lineTotalInCents;
        if (unitPrice == null || lineTotal == null) {
          return const Left(
            ValidationFailure('Une ligne du panier n\'a pas de prix résolu.'),
          );
        }

        final lineId = _ids.newId();
        lines.add(
          BoutiqueSaleLineLocalModel(
            id: lineId,
            saleId: saleId,
            articleId: line.article.id,
            // Libellé et code RECOPIÉS : le catalogue est remplacé en bloc à
            // chaque bundle, et cette vente doit rester lisible après le
            // retrait de son article.
            articleLabel: line.article.label,
            articleCode: line.article.code,
            beneficiaryStudentId: line.beneficiary?.studentId,
            beneficiaryName: line.beneficiary?.fullName,
            schoolLevelId: line.effectiveLevelId,
            size: line.size,
            quantity: line.quantity,
            unitPriceInCents: unitPrice,
            lineTotalInCents: lineTotal,
            // Celle de l'ARTICLE tel qu'il a été vendu : c'est ce que le tiroir
            // a reçu, et aucun rafraîchissement du catalogue ne le changera.
            currency: line.article.currency,
            position: index,
          ),
        );
        wireLines.add(
          BoutiqueSaleLineInput(
            articleId: line.article.id,
            beneficiaryStudentId: line.beneficiary?.studentId,
            schoolLevelId: line.effectiveLevelId,
            size: line.size,
            quantity: line.quantity,
            unitPriceInCents: unitPrice,
            lineTotalInCents: lineTotal,
            currency: line.article.currency,
          ),
        );
      }

      final phone = payer.phoneNumber.trim().isEmpty
          ? null
          : PhoneNumberFormat.canonicalE164(payer.phoneNumber);

      final sale = BoutiqueSaleLocalModel(
        id: saleId,
        schoolId: schoolId,
        academicYearId: academicYearId,
        payerLastName: _orNull(payer.lastName),
        payerMiddleName: _orNull(payer.middleName),
        payerFirstName: _orNull(payer.firstName),
        payerPhoneNumber: phone,
        // Composé ICI dans l'ordre du serveur — NOM en capitales, puis post-nom
        // et prénom. Le serveur le dérivera de son côté ; le recopier permet au
        // ticket imprimé au guichet de dire la même chose que le reçu scellé,
        // sans attendre la synchro.
        payerName: _composePayerName(
          payer.lastName,
          payer.middleName,
          payer.firstName,
        ),
        collectedById: authorId,
        collectedByName: cashierName,
        soldAt: soldAt,
        deviceId: deviceId,
        updatedAt: nowMs,
      );

      // Ce qui est ENTRÉ DANS LE TIROIR, à côté de ce qui a été vendu.
      final settlement = TenderSettlement(
        rates: await _rates?.forCurrentSchool() ?? const <ExchangeRate>[],
        at: DateTime.parse(soldAt),
      );
      final settlementLines = [
        for (final due in amounts.entries) _settle(settlement, cart, due),
      ];
      final tenders = settlement.tendersFor(settlementLines);

      // Fail-fast LOCAL sur le couple perçu/vendu, comme au guichet : un refus
      // serveur arriverait sur une vente déjà encaissée et l'immobiliserait en
      // SYNC_ERROR, sans rien que le comptoir puisse corriger.
      final violation = TenderComposition.check(
        allocations: amounts.entries,
        tenders: tenders,
      );
      if (violation != null) {
        return Left(ValidationFailure(violation.message));
      }

      final request = BoutiqueSaleRequest(
        sale: BoutiqueSaleInput(
          id: saleId,
          academicYearId: academicYearId,
          payerLastName: sale.payerLastName,
          payerFirstName: sale.payerFirstName,
          payerMiddleName: sale.payerMiddleName,
          payerPhoneNumber: phone,
          amounts: amounts,
          tenders: tenders,
          soldAt: soldAt,
        ),
        lines: wireLines,
        authorId: authorId,
      );

      await _dao.recordSale(
        sale: sale,
        lines: lines,
        request: request,
        outboxEntryId: _ids.newId(),
        schoolId: schoolId,
        nowMs: nowMs,
        tenders: [
          for (final tender in tenders)
            BoutiqueSaleTenderLocalModel(
              id: _ids.newId(),
              saleId: saleId,
              amountInCents: tender.amountInCents,
              currency: tender.currency,
              rateMicros: tender.rateMicros,
              pivotCurrency: tender.pivotCurrency,
            ),
        ],
      );

      return Right(RecordedSale(sale: sale, lines: lines));
    } catch (e) {
      // L'écriture est atomique : si elle échoue, RIEN n'a été posé, et le
      // guichet peut réessayer sans risque de double vente.
      return Left(StorageFailure('Vente non enregistrée : $e'));
    }
  }

  /// Le règlement d'une devise du panier, tel que le comptoir l'a décidé.
  ///
  /// Sans devise de règlement choisie, c'est l'identité : le client paie dans la
  /// devise du catalogue, il n'y a ni taux ni conversion.
  ///
  /// ⚠️ **Le montant dû n'est jamais négociable ici** — et c'est la différence
  /// avec le guichet. Une vente est comptant **intégral** (invariant I-5, aucune
  /// colonne de reste sur `boutique_sales`) : ce qui entre dans le tiroir vaut
  /// toujours le prix du panier converti. Le montant saisi au comptoir ne sert
  /// qu'à une chose, rendre la monnaie : posé au-dessus du dû, l'excédent
  /// repart avec le client ; posé en dessous, il ne fabrique pas une vente à
  /// moitié payée — l'écran le signale, et le tiroir garde le compte juste.
  SettlementLine _settle(
    TenderSettlement settlement,
    BoutiqueCart cart,
    Money due,
  ) {
    final tender = cart.tenderFor(due.currency);
    final target = tender.currency.isEmpty ? due.currency : tender.currency;
    final line = settlement.fromSettled(
      settledCurrency: due.currency,
      tenderCurrency: target,
      settledCents: due.amountInCents,
    );
    final tendered = tender.tenderedCents ?? 0;
    if (tendered <= line.tenderCents) return line;
    return SettlementLine(
      settledCurrency: line.settledCurrency,
      tenderCurrency: line.tenderCurrency,
      rate: line.rate,
      settledCents: line.settledCents,
      tenderCents: line.tenderCents,
      changeCents: tendered - line.tenderCents,
    );
  }

  /// `NOM Post-nom Prénom`, nom en capitales — l'ordre RDC, et celui que le
  /// serveur applique.
  /// `null` quand le triplet entier est vide — **jamais `''`**.
  ///
  /// C'est ce que le ticket lit pour escamoter son bloc payeur, et c'est la
  /// règle que le serveur s'est donnée en V114 : « pas de payeur » est un fait,
  /// pas un nom de longueur zéro. Une chaîne vide ferait imprimer un cadre
  /// creux, qui sur une pièce se lit comme une mention effacée.
  static String? _composePayerName(
    String lastName,
    String middleName,
    String firstName,
  ) => _orNull(
    [
      lastName.trim().toUpperCase(),
      middleName.trim(),
      firstName.trim(),
    ].where((part) => part.isNotEmpty).join(' '),
  );

  static String? _orNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Best-effort : un identifiant d'appareil indisponible laisse la colonne
  /// vide, jamais un encaissement en échec.
  Future<String?> _resolveDeviceId() async {
    try {
      return await _device.getOrCreateDeviceId();
    } catch (_) {
      return null;
    }
  }
}
