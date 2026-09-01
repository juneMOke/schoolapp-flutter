import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Assemble le ticket depuis les lignes locales.
///
/// Le **solde** n'est pas recalculé ici : il est demandé au domaine Facturation
/// (`getCharges`), seul détenteur de la sémantique money-grade du reste à payer
/// — lequel compose le miroir autoritaire et les encaissements pas encore
/// remontés. Répliquer ce SQL ici ferait diverger deux vérités sur l'argent.
class ProvisionalTicketRepositoryImpl implements ProvisionalTicketRepository {
  final ProvisionalTicketDao _dao;
  final FinanceOfflineRepository _finance;
  final DeviceIdentityService _deviceIdentity;

  const ProvisionalTicketRepositoryImpl({
    required ProvisionalTicketDao dao,
    required FinanceOfflineRepository finance,
    required DeviceIdentityService deviceIdentity,
  }) : _dao = dao,
       _finance = finance,
       _deviceIdentity = deviceIdentity;

  @override
  Future<void> markTicketPrinted(String paymentId) async {
    try {
      await _dao.markTicketPrinted(paymentId, DateTime.now());
    } catch (_) {
      // Muet par contrat : le papier est déjà dans la main du parent quand
      // cette écriture a lieu. La faire échouer bruyamment ferait croire à une
      // impression ratée ; la perdre en silence fera au pire réapparaître le
      // rattrapage sur un versement déjà servi.
    }
  }

  @override
  Future<bool> hasPrintedTicket(String paymentId) async {
    try {
      return await _dao.hasPrintedTicket(paymentId);
    } catch (_) {
      // Lecture illisible : on répond « pas imprimé ». Offrir un rattrapage
      // inutile vaut mieux que masquer le seul chemin vers un papier manquant.
      return false;
    }
  }

  @override
  Future<bool> awaitsTicketPrint(String paymentId) async {
    try {
      final payment = await _dao.findPayment(paymentId);
      if (payment == null) return false;

      // Encaissé ailleurs : le ticket sortirait sans référence provisoire et
      // avec les codes de frais en guise de libellés. Un papier illisible
      // remis à une famille vaut moins que pas de papier du tout.
      final deviceId = payment.deviceId?.trim();
      if (deviceId == null || deviceId.isEmpty) return false;
      if (deviceId != await _deviceIdentity.getOrCreateDeviceId()) return false;

      return !await _dao.hasPrintedTicket(paymentId);
    } catch (_) {
      // Rien de lisible : on n'offre pas un geste dont on ne sait pas s'il est
      // légitime. Le silence vaut mieux qu'un bouton qui ressortirait un ticket
      // déjà remis.
      return false;
    }
  }

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async {
    try {
      final payment = await _dao.findPayment(paymentId);
      if (payment == null) {
        return const Left(
          NotFoundFailure('Encaissement introuvable en local.'),
        );
      }

      final student = await _dao.findStudent(payment.studentId);
      final school = await _dao.findSchool();
      final classroomName = await _dao.findClassroomName(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
      );
      final allocations = await _dao.findAllocations(paymentId);
      final tenders = await _dao.findTenders(paymentId);
      final reference = await _dao.findProvisionalNumber(paymentId);

      return Right(
        TicketReceiptModel(
          // Une école inconnue n'empêche pas d'imprimer : le ticket vaut par son
          // montant et son caissier, pas par son en-tête.
          schoolName: school?.name ?? '',
          schoolMunicipality: school?.locality,
          studentFullName: student?.fullName ?? '',
          matriculationNumber: student?.matriculationNumber,
          classroomName: classroomName,
          // Sans ligne documentaire (cas anormal mais non bloquant), on retombe
          // sur l'identifiant du paiement : un ticket sans aucune référence
          // serait irrapprochable.
          provisionalReference: reference ?? paymentId,
          paidAt: _parsePaidAt(payment.paidAt),
          cashierFullName: payment.cashierFullName,
          // Ce que le TIROIR a vu, et non ce que les imputations totalisent :
          // c'est toute la correction de ce lot. Le montant reçu du ticket en
          // dérive (`TicketReceiptModel.amountReceived`), il n'est plus posable
          // à la main.
          tenders: [
            for (final tender in tenders)
              TicketTenderLine(
                amountInCents: tender.amountInCents,
                currency: tender.currency,
                rateMicros: tender.rateMicros,
                pivotCurrency: tender.pivotCurrency,
              ),
          ],
          allocations: allocations
              .map(
                (a) => TicketAllocationLine(
                  label: a.label,
                  amountInCents: a.amountInCents,
                  currency: a.currency,
                ),
              )
              .toList(growable: false),
          // Le solde des SEULES devises que ce versement a touchées : imprimer
          // une dette en francs sur un ticket réglé en dollars ferait lire au
          // payeur un chiffre qui ne le concerne pas.
          remainingBalance: await _remainingBalances(
            studentId: payment.studentId,
            academicYearId: payment.academicYearId,
            // Les devises des CRÉANCES que ce versement a touchées : un solde
            // se dit dans la devise où la dette existe, pas dans celle des
            // billets posés. Un ticket réglé en francs sur une créance en
            // dollars affiche donc un reste en dollars — c'est bien ce que le
            // parent doit encore.
            currencies: payment.amounts.currencies,
          ),
          labels: labels,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Ticket illisible en local : $e'));
    }
  }

  /// Reste à payer de l'élève, **dans l'année ET la devise du versement**.
  ///
  /// Les deux filtres sont indispensables, pour deux raisons distinctes :
  ///
  /// - **l'année** : `getCharges` ne filtre que sur l'élève, alors que toute
  ///   l'UI Facturation lit les créances scopées à l'année. Sans ce filtre, un
  ///   élève réinscrit verrait son arriéré N-1 additionné au reste dû N, et le
  ///   ticket imprimerait un solde différent de celui affiché à l'écran au même
  ///   instant — sur un papier remis à un parent ;
  /// - **les devises du versement** : le solde ne porte que sur celles que ce
  ///   paiement a touchées. Imprimer une dette en francs sur un ticket réglé en
  ///   dollars ferait lire au payeur un chiffre qui ne le concerne pas. Et le
  ///   sac les garde séparées : additionner deux unités produirait un chiffre
  ///   faux.
  ///
  /// `null` dès que la lecture échoue, que l'année est inconnue, ou qu'aucune
  /// créance ne correspond : le ticket omet alors la ligne, ce qu'il sait faire.
  Future<MoneyBag?> _remainingBalances({
    required String studentId,
    required String? academicYearId,
    required Iterable<String> currencies,
  }) async {
    if (academicYearId == null || academicYearId.isEmpty) return null;
    if (currencies.isEmpty) return null;

    final charges = await _finance.getCharges(studentId);
    final wanted = {
      for (final currency in currencies) CurrencyCode.normalize(currency),
    };

    return charges.fold<MoneyBag?>((_) => null, (list) {
      // `belongsToYear` et pas une égalité stricte : une créance sans année
      // compte dans TOUTES les années (cf. sa note). L'égalité stricte qui
      // vivait ici imprimait une dette plus petite que celle de l'écran.
      final matching = list
          .where(
            (c) =>
                wanted.contains(CurrencyCode.normalize(c.currency)) &&
                c.belongsToYear(academicYearId),
          )
          .toList(growable: false);
      if (matching.isEmpty) return null;

      return MoneyBag.sumBy(
        matching,
        (c) => Money.parse(c.optimisticRemainingInCents, c.currency),
      );
    });
  }

  /// `paid_at` est une date terrain ISO-8601, écrite en **UTC** à
  /// l'encaissement. Le ticket doit porter l'heure du GUICHET : sans
  /// `toLocal()`, un versement pris à 00 h 30 à Kinshasa (UTC+1) s'imprimerait
  /// daté de la veille, irrapprochable de la caisse du jour.
  ///
  /// Une valeur illisible ne doit pas empêcher l'impression : on retombe sur
  /// l'instant courant, seconde meilleure approximation du geste de caisse.
  static DateTime _parsePaidAt(String raw) =>
      (DateTime.tryParse(raw) ?? DateTime.now()).toLocal();
}
