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
      // Le matricule de l'ANNÉE du versement : il vit sur l'inscription, pas
      // sur l'élève.
      final annualMatriculation = await _dao.findAnnualMatriculationNumber(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
      );
      final allocations = await _dao.findAllocations(paymentId);
      final tenders = await _dao.findTenders(paymentId);
      // Le numéro DÉFINITIF s'il existe localement, le provisoire sinon.
      final definitive = await _dao.findDefinitiveNumber(paymentId);
      final provisional = await _dao.findProvisionalNumber(paymentId);
      // Ce que l'élève a déjà versé cette année, AVANT ce ticket. Le bloc se
      // lit sous le solde : ce que je viens de payer, ce qu'il me reste, ce que
      // j'avais déjà versé.
      final history = await _dao.findPaymentHistory(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
        excludePaymentId: paymentId,
      );

      // Le solde des SEULS frais que ce versement a réglés, une ligne par
      // (nature, devise) — exactement les clés de la répartition juste
      // au-dessus. Un parent qui règle les frais divers vient chercher leur
      // solde : lui imprimer celui du minerval, c'est lui faire lire une dette
      // qu'il n'est pas venu payer, sur la pièce d'un versement qui ne la
      // touche pas.
      //
      // La devise est celle des CRÉANCES touchées, pas des billets posés : un
      // solde se dit dans la devise où la dette existe.
      final remaining = await _remainingByCharge(
        studentId: payment.studentId,
        academicYearId: payment.academicYearId,
        paidFees: {
          for (final allocation in allocations)
            _feeKey(allocation.feeCode, allocation.currency),
        },
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
          schoolTillPhone: school?.tillPhone,
          studentFullName: student?.fullName ?? '',
          matriculationNumber: student?.matriculationNumber,
          annualMatriculationNumber: annualMatriculation,
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
          paymentHistory: _historyEntries(history),
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

  /// Replie les lignes plates du DAO en **un sac de monnaie par versement**.
  ///
  /// L'ordre de la requête est conservé — le plus récent d'abord — parce qu'une
  /// `Map` Dart itère dans l'ordre d'insertion. C'est ce qui fait que deux
  /// tirages du même ticket sortent identiques, là où un regroupement par clé
  /// triée les rendrait dépendants de l'alphabet des uuid.
  ///
  /// Les dates passent par `toLocal()` comme celle du versement courant : sans
  /// elle, un versement pris à 00 h 30 à Kinshasa s'imprimerait daté de la
  /// veille, et l'historique contredirait la ligne « Date : » d'un ticket tiré
  /// ce jour-là.
  ///
  /// ⚠️ **Mais PAS par [_parsePaidAt], et c'est la seule divergence.** Celui-ci
  /// retombe sur l'instant courant quand la chaîne est illisible — juste pour
  /// le versement en cours, dont le geste de caisse a bien lieu maintenant.
  /// Appliqué à un versement ANCIEN, ce repli le daterait d'aujourd'hui : une
  /// date fausse sur un papier remis à un parent, là où l'omission de la ligne
  /// ne coûte qu'un versement de moins sous un total qui reste, lui, la somme
  /// exacte de ce qui est imprimé.
  static List<TicketHistoryEntry> _historyEntries(List<TicketHistoryRow> rows) {
    final byPayment = <String, List<Money>>{};
    final paidAt = <String, DateTime>{};
    for (final row in rows) {
      final at =
          paidAt[row.paymentId] ?? DateTime.tryParse(row.paidAt)?.toLocal();
      if (at == null) continue;
      paidAt[row.paymentId] = at;
      (byPayment[row.paymentId] ??= <Money>[]).add(
        Money.parse(row.amountInCents, row.currency),
      );
    }
    return [
      for (final entry in byPayment.entries)
        TicketHistoryEntry(
          paidAt: paidAt[entry.key]!,
          received: MoneyBag.of(entry.value),
        ),
    ];
  }

  /// Reste à payer des **frais que ce versement a réglés**, dans l'année du
  /// versement.
  ///
  /// Les deux filtres sont indispensables, pour deux raisons distinctes :
  ///
  /// - **l'année** : `getCharges` ne filtre que sur l'élève, alors que toute
  ///   l'UI Facturation lit les créances scopées à l'année. Sans ce filtre, un
  ///   élève réinscrit verrait son arriéré N-1 additionné au reste dû N, et le
  ///   ticket imprimerait un solde différent de celui affiché à l'écran au même
  ///   instant — sur un papier remis à un parent ;
  /// - **les frais réglés** ([paidFees], clés `NATURE|DEVISE` de la
  ///   répartition) : le ticket est la pièce de CE versement. Le filtre sur la
  ///   seule devise qui vivait ici imprimait le minerval sous un versement de
  ///   frais divers dès que les deux étaient en francs. La devise reste dans la
  ///   clé : additionner deux unités produirait un chiffre faux.
  ///
  /// Le reste dû, **une ligne par (nature de frais, devise)**, dans l'ordre où
  /// les créances remontent. La nature regroupe les tranches : c'est « le solde
  /// du minerval » qui s'imprime, pas celui de sa deuxième tranche.
  ///
  /// Le nom vient de `ref_fee_code_sections` s'il existe, du libellé de la
  /// créance sinon — **la même règle que la ventilation juste au-dessus**, et
  /// c'est ce qui compte : deux noms pour un même frais sur le même papier
  /// feraient chercher au parent la différence entre eux.
  ///
  /// ⚠️ **Un frais soldé s'imprime À ZÉRO**, il n'est plus escamoté.
  /// L'omission valait tant que le bloc listait tous les frais de l'élève ; il
  /// ne porte plus que ceux que le parent vient de régler, et « 0 » est
  /// précisément ce qu'il vient lire. Omis, le frais emporterait le bloc
  /// entier au versement qui le solde — et un ticket sans solde se lit comme un
  /// solde inconnu.
  ///
  /// Liste vide dès que la lecture échoue, que l'année est inconnue, ou
  /// qu'aucune créance ne correspond : le ticket omet alors le bloc, ce qu'il
  /// sait faire.
  Future<List<TicketAllocationLine>> _remainingByCharge({
    required String studentId,
    required String? academicYearId,
    required Set<String> paidFees,
  }) async {
    const empty = <TicketAllocationLine>[];
    if (academicYearId == null || academicYearId.isEmpty) return empty;
    if (paidFees.isEmpty) return empty;

    final charges = await _finance.getCharges(studentId);
    final titles = await _dao.feeSectionTitles();

    return charges.fold<List<TicketAllocationLine>>((_) => empty, (list) {
      final grouped = <String, TicketAllocationLine>{};
      for (final c in list) {
        // `belongsToYear` et pas une égalité stricte : une créance sans année
        // compte dans TOUTES les années (cf. sa note). L'égalité stricte qui
        // vivait ici imprimait une dette plus petite que celle de l'écran.
        if (!c.belongsToYear(academicYearId)) continue;
        final key = _feeKey(c.feeCode, c.currency);
        if (!paidFees.contains(key)) continue;
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

  /// La clé d'un frais sur le ticket : sa nature et sa devise, normalisées.
  ///
  /// Partagée par la répartition (ce que le versement a réglé) et les créances
  /// (ce qu'il en reste) : une casse ou une espace de trop d'un seul côté
  /// ferait sortir du solde le frais même qui vient d'être payé.
  static String _feeKey(String feeCode, String currency) =>
      '${feeCode.trim().toUpperCase()}|${CurrencyCode.normalize(currency)}';

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
