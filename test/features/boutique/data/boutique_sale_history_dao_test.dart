import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

Future<void> _insertSale(
  Database db, {
  required String id,
  String schoolId = 'E1',
  String year = 'ay-1',
  required String soldAt,
  String? payerName,
  String payerLastName = 'Ndombo',
  String? payerMiddleName,
  String? payerFirstName,
  int total = 1500,
  String currency = 'USD',
  String syncStatus = 'SYNCED',
  String? receiptNumber,
}) => db.insert('boutique_sales', {
  'id': id,
  'school_id': schoolId,
  'academic_year_id': year,
  'payer_name': payerName,
  'payer_last_name': payerLastName,
  'payer_middle_name': payerMiddleName,
  'payer_first_name': payerFirstName,
  'payer_phone_number': '+243810220145',
  'total_in_cents': total,
  'currency': currency,
  'sold_at': soldAt,
  'receipt_number': receiptNumber,
  'sync_status': syncStatus,
  'updated_at': 0,
});

Future<void> _insertLine(
  Database db, {
  required String id,
  required String saleId,
  int quantity = 1,
  int position = 0,
}) => db.insert('boutique_sale_lines', {
  'id': id,
  'sale_id': saleId,
  'article_id': 'art-1',
  'article_label': 'Cahier',
  'quantity': quantity,
  'unit_price_in_cents': 1500,
  'line_total_in_cents': 1500 * quantity,
  'position': position,
});

void main() {
  late Database db;
  late BoutiqueSaleHistoryDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSaleHistoryDao(db);
  });
  tearDown(() async => db.close());

  Future<List<String>> idsSince(String bound, {String school = 'E1'}) async {
    final rows = await dao.salesSince(
      schoolId: school,
      academicYearId: 'ay-1',
      soldAtBound: bound,
    );
    return [for (final row in rows) row.id];
  }

  test('la fenêtre exclut ce qui la précède, garde ce qui la suit', () async {
    await _insertSale(db, id: 's-avant', soldAt: '2026-08-29T18:00:00.000Z');
    await _insertSale(db, id: 's-apres', soldAt: '2026-08-30T09:00:00.000Z');

    expect(await idsSince('2026-08-30T00:00:00'), ['s-apres']);
  });

  test('la plus récente vient EN TÊTE', () async {
    // Le guichet cherche ce qu'il vient d'encaisser, pas ce qu'il a encaissé ce
    // matin.
    await _insertSale(db, id: 's-matin', soldAt: '2026-08-30T08:00:00.000Z');
    await _insertSale(db, id: 's-midi', soldAt: '2026-08-30T12:00:00.000Z');
    await _insertSale(db, id: 's-soir', soldAt: '2026-08-30T17:00:00.000Z');

    expect(await idsSince('2026-08-30T00:00:00'), [
      's-soir',
      's-midi',
      's-matin',
    ]);
  });

  test('les DEUX formats d\'horodatage franchissent la même borne', () async {
    // ⚠️ `sold_at` en mélange deux : l'écriture locale produit `...:00.000Z`,
    // le delta serveur descend `...:00Z`. Or '.' (0x2E) est INFÉRIEUR à 'Z'
    // (0x5A) — une borne suffixée exclurait silencieusement l'un des deux, à
    // minuit pile. La borne est donc un PRÉFIXE de 19 caractères.
    await _insertSale(db, id: 's-local', soldAt: '2026-08-30T00:00:00.000Z');
    await _insertSale(db, id: 's-serveur', soldAt: '2026-08-30T00:00:00Z');

    final ids = await idsSince('2026-08-30T00:00:00');

    expect(ids, containsAll(['s-local', 's-serveur']));
  });

  test('la caisse d\'une AUTRE école n\'est jamais montrée', () async {
    // La conception « une tablette, une école » a déjà produit dix flux à
    // curseur nu : ne pas en ajouter un onzième.
    await _insertSale(db, id: 's-nous', soldAt: '2026-08-30T09:00:00.000Z');
    await _insertSale(
      db,
      id: 's-eux',
      schoolId: 'E2',
      soldAt: '2026-08-30T09:30:00.000Z',
    );

    expect(await idsSince('2026-08-30T00:00:00'), ['s-nous']);
  });

  test('un autre EXERCICE n\'est jamais montré', () async {
    await _insertSale(db, id: 's-cette-annee', soldAt: '2026-08-30T09:00:00Z');
    await _insertSale(
      db,
      id: 's-an-passe',
      year: 'ay-0',
      soldAt: '2026-08-30T09:30:00Z',
    );

    expect(await idsSince('2026-08-30T00:00:00'), ['s-cette-annee']);
  });

  test(
    'le compte d\'articles SOMME les quantités, sans dupliquer la vente',
    () async {
      // Une jointure nue répéterait la vente autant de fois qu'elle a de lignes,
      // et le total de la fenêtre se compterait plusieurs fois.
      await _insertSale(db, id: 's-1', soldAt: '2026-08-30T09:00:00Z');
      await _insertLine(db, id: 'l-1', saleId: 's-1', quantity: 2);
      await _insertLine(db, id: 'l-2', saleId: 's-1', quantity: 3);

      final rows = await dao.salesSince(
        schoolId: 'E1',
        academicYearId: 'ay-1',
        soldAtBound: '2026-08-30T00:00:00',
      );

      expect(rows, hasLength(1));
      expect(rows.single.articleCount, 5);
    },
  );

  test('une vente SANS ligne compte zéro article, et reste visible', () async {
    // `COALESCE` et non `SUM` nu : une sous-requête sans ligne rend `null`, et
    // une vente muette disparaîtrait de la caisse du jour.
    await _insertSale(db, id: 's-vide', soldAt: '2026-08-30T09:00:00Z');

    final rows = await dao.salesSince(
      schoolId: 'E1',
      academicYearId: 'ay-1',
      soldAtBound: '2026-08-30T00:00:00',
    );

    expect(rows.single.articleCount, 0);
  });

  test('le nom du SERVEUR prime sur les champs saisis', () async {
    // Recomposer alors que le serveur a répondu écraserait sa forme d'affichage
    // par la nôtre, et les deux ne coïncident pas.
    await _insertSale(
      db,
      id: 's-1',
      soldAt: '2026-08-30T09:00:00Z',
      payerName: 'Ndombo Lelo Willy',
      payerLastName: 'NDOMBO',
      payerFirstName: 'Willy',
    );

    final rows = await dao.salesSince(
      schoolId: 'E1',
      academicYearId: 'ay-1',
      soldAtBound: '2026-08-30T00:00:00',
    );

    expect(rows.single.payerName, 'Ndombo Lelo Willy');
  });

  test(
    'sans nom composé, les champs saisis se rejoignent dans l\'ordre',
    () async {
      await _insertSale(
        db,
        id: 's-1',
        soldAt: '2026-08-30T09:00:00Z',
        payerLastName: 'Ndombo',
        payerMiddleName: 'Lelo',
        payerFirstName: 'Willy',
      );

      final rows = await dao.salesSince(
        schoolId: 'E1',
        academicYearId: 'ay-1',
        soldAtBound: '2026-08-30T00:00:00',
      );

      expect(rows.single.payerName, 'Ndombo Lelo Willy');
    },
  );

  group('la fiche d\'une vente', () {
    test('rend l\'en-tête ET ses lignes, dans l\'ordre du ticket', () async {
      // Relire la vente dans un autre ordre que le papier remis au client
      // ferait douter des deux.
      await _insertSale(db, id: 's-1', soldAt: '2026-08-30T09:00:00Z');
      await _insertLine(db, id: 'l-2', saleId: 's-1', position: 1);
      await _insertLine(db, id: 'l-1', saleId: 's-1', position: 0);

      final detail = await dao.saleById(schoolId: 'E1', saleId: 's-1');

      expect(detail, isNotNull);
      expect([for (final line in detail!.lines) line.id], ['l-1', 'l-2']);
    });

    test('la vente d\'une AUTRE école n\'est jamais ouverte', () async {
      // Un identifiant deviné ouvrirait la caisse de l'établissement voisin sur
      // une tablette partagée.
      await _insertSale(
        db,
        id: 's-eux',
        schoolId: 'E2',
        soldAt: '2026-08-30T09:00:00Z',
      );

      expect(await dao.saleById(schoolId: 'E1', saleId: 's-eux'), isNull);
    });

    test('une vente absente rend null, jamais une fiche vide', () async {
      expect(await dao.saleById(schoolId: 'E1', saleId: 'jamais-vue'), isNull);
    });

    test('« encaissé par » descend jusqu\'à la fiche', () async {
      // Sur une caisse tenue à plusieurs, c'est la seule ligne qui dit QUI a
      // pris l'argent.
      await _insertSale(db, id: 's-1', soldAt: '2026-08-30T09:00:00Z');
      await db.update(
        'boutique_sales',
        {'collected_by_name': 'Mbala Céline'},
        where: 'id = ?',
        whereArgs: ['s-1'],
      );

      final detail = await dao.saleById(schoolId: 'E1', saleId: 's-1');

      expect(detail!.sale.collectedByName, 'Mbala Céline');
    });
  });

  group('la trace d\'impression', () {
    test('une vente jamais imprimée ne porte aucune date', () async {
      await _insertSale(db, id: 's-1', soldAt: '2026-08-30T09:00:00Z');

      expect(await dao.ticketPrintedAt(schoolId: 'E1', saleId: 's-1'), isNull);
    });

    test('marquer l\'impression pose la date, et rien d\'autre', () async {
      // La trace n'est PAS de l'argent : elle ne doit toucher aucun montant, et
      // elle ne part jamais au serveur.
      await _insertSale(db, id: 's-1', soldAt: '2026-08-30T09:00:00Z');
      final at = DateTime.utc(2026, 8, 30, 10, 15);

      await dao.markTicketPrinted(
        saleId: 's-1',
        atMs: at.millisecondsSinceEpoch,
      );

      expect(
        await dao.ticketPrintedAt(schoolId: 'E1', saleId: 's-1'),
        DateTime.fromMillisecondsSinceEpoch(at.millisecondsSinceEpoch),
      );
      final rows = await db.query(
        'boutique_sales',
        where: 'id = ?',
        whereArgs: ['s-1'],
      );
      expect(rows.single['total_in_cents'], 1500);
      expect(rows.single['sync_status'], 'SYNCED');
    });

    test('la trace d\'une AUTRE école ne se lit pas', () async {
      await _insertSale(
        db,
        id: 's-eux',
        schoolId: 'E2',
        soldAt: '2026-08-30T09:00:00Z',
      );
      await dao.markTicketPrinted(saleId: 's-eux', atMs: 1);

      expect(
        await dao.ticketPrintedAt(schoolId: 'E1', saleId: 's-eux'),
        isNull,
      );
    });
  });

  test('une vente NON PARTIE est visible, et se dit en attente', () async {
    // C'est la raison d'être d'une lecture locale : le serveur ne la connaît
    // pas encore, et le guichet doit la voir avant d'éteindre la tablette.
    await _insertSale(
      db,
      id: 's-attente',
      soldAt: '2026-08-30T09:00:00Z',
      syncStatus: 'PENDING_SYNC',
    );

    final rows = await dao.salesSince(
      schoolId: 'E1',
      academicYearId: 'ay-1',
      soldAtBound: '2026-08-30T00:00:00',
    );

    expect(rows.single.isPending, isTrue);
  });
}
