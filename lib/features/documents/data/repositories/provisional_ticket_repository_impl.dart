import 'package:dartz/dartz.dart';
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

  // ⚠️ Plus de `DeviceIdentityService` ici. Il ne servait qu'à refuser le
  // rattrapage hors du poste d'encaissement ; la réimpression étant libre et la
  // pièce se composant entière depuis un versement descendu par pull, la
  // dépendance n'avait plus d'objet — la garder aurait laissé croire que
  // l'appareil décide encore de quelque chose.
  const ProvisionalTicketRepositoryImpl({
    required ProvisionalTicketDao dao,
    required FinanceOfflineRepository finance,
  }) : _dao = dao,
       _finance = finance;

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
  Future<DateTime?> ticketPrintedAt(String paymentId) async {
    try {
      return await _dao.findTicketPrintedAt(paymentId);
    } catch (_) {
      // Lecture illisible : on répond « aucun papier connu ». Le bouton reste
      // offert de toute façon — seule la phrase qui l'accompagne s'appauvrit,
      // et une phrase muette vaut mieux qu'une date inventée.
      return null;
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
      // Le numéro DÉFINITIF s'il existe localement, le provisoire sinon.
      final definitive = await _dao.findDefinitiveNumber(paymentId);
      final provisional = await _dao.findProvisionalNumber(paymentId);
      // Le solde des SEULES devises que ce versement a touchées, détaillé par
      // nature : imprimer une dette en francs sur un ticket réglé en dollars
      // ferait lire au payeur un chiffre qui ne le concerne pas.
      //
      // Les devises retenues sont celles des CRÉANCES touchées, pas des billets
      // posés : un solde se dit dans la devise où la dette existe.
      final remaining = await _remainingByCharge(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
        currencies: payment.amounts.currencies,
      );

      return Right(
        TicketReceiptModel(
          // Une école inconnue n'empêche pas d'imprimer : le ticket vaut par son
          // montant et son caissier, pas par son en-tête. Chaque ligne absente
          // s'escamote d'elle-même, donc un référentiel non pullé produit un
          // en-tête COURT, jamais un en-tête troué.
          schoolName: school?.name ?? '',
          schoolLocality: school?.locality,
          schoolAddress: school?.address,
          schoolEmail: school?.email,
          schoolPhone: school?.phone,
          studentFullName: student?.fullName ?? '',
          matriculationNumber: student?.matriculationNumber,
          classroomName: classroomName,
          // Sans ligne documentaire (cas anormal mais non bloquant, et cas
          // NORMAL d'un versement encaissé sur une autre caisse), on retombe sur
          // l'identifiant du paiement : un ticket sans aucune référence serait
          // irrapprochable.
          reference: definitive ?? provisional ?? paymentId,
          // ⚠️ Lu AFFIRMATIVEMENT sur l'absence de `receipt_id`, jamais par
          // négation d'un numéro. `definitive == null` serait vrai aussi quand
          // aucune ligne `generated_documents` locale n'existe — cas normal d'un
          // versement encaissé ailleurs et descendu par pull. La mention
          // « provisoire » s'imprimerait alors sur des tickets scellés, soit
          // exactement l'inverse de ce qui est voulu. `receipt_id`, lui, descend.
          isProvisional: (payment.receiptId?.trim().isEmpty ?? true),
          paidAt: _parsePaidAt(payment.paidAt),
          // Les `cashier_*` de ce poste, puis l'attribution serveur : le patch
          // de pull ne réécrit jamais les premiers, donc un versement encaissé
          // sur une AUTRE caisse n'a que la seconde. Sans ce repli, son ticket
          // sortirait sans personne à qui l'imputer (RG-012-11).
          cashierFullName: payment.cashierFullName,
          // `null`, jamais `''` — c'est ce que le gabarit lit pour escamoter le
          // bloc payeur entier plutôt que d'imprimer un cadre vide.
          payerFullName: payment.payerFullName,
          payerPhoneNumber: payment.payerPhoneNumber,
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
          remainingByCharge: remaining,
          // ⚠️ Le total **dérive des lignes imprimées**, il n'est pas recalculé
          // à côté. Un parent additionne ce qu'il lit : deux chemins de calcul
          // finiraient par diverger, et l'écart apparaîtrait sur le papier —
          // exactement ce que la ligne d'avance ferme déjà dans la ventilation.
          remainingBalance: remaining.isEmpty
              ? null
              : MoneyBag.sumBy(
                  remaining,
                  (l) => Money.parse(l.amountInCents, l.currency),
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
  /// Le reste dû, **une ligne par (nature de frais, devise)**, dans l'ordre où
  /// les créances remontent.
  ///
  /// Le nom vient de `ref_fee_code_sections` s'il existe, du libellé de la
  /// créance sinon — **la même règle que la ventilation juste au-dessus**, et
  /// c'est ce qui compte : deux noms pour un même frais sur le même papier
  /// feraient chercher au parent la différence entre eux.
  ///
  /// Les frais **soldés sont absents**, jamais imprimés à zéro : même règle que
  /// le bloc payeur, une mention à zéro se lit comme une mention effacée.
  Future<List<TicketAllocationLine>> _remainingByCharge({
    required String studentId,
    required String? academicYearId,
    required Iterable<String> currencies,
  }) async {
    const empty = <TicketAllocationLine>[];
    if (academicYearId == null || academicYearId.isEmpty) return empty;
    if (currencies.isEmpty) return empty;

    final charges = await _finance.getCharges(studentId);
    final titles = await _dao.feeSectionTitles();
    final wanted = {
      for (final currency in currencies) CurrencyCode.normalize(currency),
    };

    return charges.fold<List<TicketAllocationLine>>((_) => empty, (list) {
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
      final grouped = <String, TicketAllocationLine>{};
      for (final c in matching) {
        // Un frais soldé n'a rien à faire sur le papier.
        if (c.optimisticRemainingInCents <= 0) continue;
        final key = '${c.feeCode.toUpperCase()}|${c.currency}';
        final existing = grouped[key];
        grouped[key] = TicketAllocationLine(
          // Premier nom du groupe, comme la ventilation : titre de section s'il
          // existe, libellé de la créance sinon.
          label:
              existing?.label ??
              (titles[c.feeCode.trim().toUpperCase()] ?? c.label),
          amountInCents:
              (existing?.amountInCents ?? 0) + c.optimisticRemainingInCents,
          currency: c.currency,
        );
      }
      return grouped.values.toList(growable: false);
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
