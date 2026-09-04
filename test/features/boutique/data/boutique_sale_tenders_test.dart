import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/exchange_rate_reader.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_dao.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_local_model.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_sale_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_tender.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../offline_full_db.dart';

class _MockDevice extends Mock implements DeviceIdentityService {}

class _SeqIds extends IdGenerator {
  _SeqIds() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 5000, // 50,00 $
  currency: 'USD',
);

const _payeur = CartPayer(
  lastName: 'Ndombo',
  middleName: 'Lelo',
  firstName: 'Willy',
  phoneNumber: '0810220145',
);

/// Ce que le tiroir a pris, à côté de ce qui a été vendu.
///
/// Le pendant boutique du guichet : la question « le client règle en quoi ? » se
/// pose par devise du panier, et ce que le comptoir a réellement encaissé est
/// écrit **avec** la vente, dans la même transaction. Sans quoi la caisse du
/// soir annoncerait des dollars sur une journée où le tiroir n'a vu que des
/// francs.
void main() {
  late Database db;
  late BoutiqueSaleWriteDao dao;
  late _MockDevice device;

  BoutiqueCart cart({CartTender? tender}) => BoutiqueCart(
    payer: _payeur,
    lines: const [CartLine(key: 'k0', article: _polo)],
    tenders: tender == null ? const {} : {'USD': tender},
  );

  BoutiqueSaleRepositoryImpl repo() => BoutiqueSaleRepositoryImpl(
    dao: dao,
    currentUser: CurrentUserContext()..set('u1', schoolId: 'E1'),
    ids: _SeqIds(),
    device: device,
    now: () => 1000,
    rates: ExchangeRateReader(
      dao: ExchangeRateDao(db),
      currentUser: CurrentUserContext()..set('u1', schoolId: 'E1'),
    ),
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSaleWriteDao(db);
    device = _MockDevice();
    when(() => device.getOrCreateDeviceId()).thenAnswer((_) async => 'dev-1');
    await ExchangeRateDao(db).replaceForSchool(const [
      ExchangeRateLocalModel(
        schoolId: 'E1',
        base: 'USD',
        quote: 'CDF',
        effectiveFrom: '2020-01-01T00:00:00Z',
        rateMicros: 2800000000, // 2 800 FC pour 1 $
      ),
    ], schoolId: 'E1');
  });

  tearDown(() async => db.close());

  Future<List<Map<String, Object?>>> tendersOf(String saleId) => db.query(
    'boutique_sale_tenders',
    where: 'sale_id = ?',
    whereArgs: [saleId],
  );

  Future<Map<String, dynamic>> pushedSale() async {
    final entry = (await db.query('outbox')).single;
    final payload =
        jsonDecode(entry['payload'] as String) as Map<String, dynamic>;
    return payload['sale'] as Map<String, dynamic>;
  }

  test(
    'sans choix de devise : identité, taux 1, et rien de plus à l’écran',
    () async {
      final recorded = await repo().recordSale(
        cart: cart(),
        academicYearId: 'ay-1',
      );
      final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

      final rows = await tendersOf(saleId);
      expect(rows, hasLength(1));
      expect(rows.single['amount_in_cents'], 5000);
      expect(rows.single['currency'], 'USD');
      expect(rows.single['pivot_currency'], 'USD');
      expect(rows.single['rate_micros'], ExchangeRate.scale);
    },
  );

  /// ⚠️ Le test voisin éprouve la table LOCALE ; celui-ci éprouve le FIL, et ce
  /// n'est pas la même promesse. Depuis le contrat du 2026-09-04, une vente qui
  /// ne déclare rien se voit écrire l'identité par le serveur, marquée
  /// `DERIVED` : un postulat indiscernable d'un constat, qui vaut une ligne
  /// d'arbitrage `TENDER_UNDECLARED` partout où l'école publie un taux de
  /// guichet. Déclarer l'identité est ce qui transforme la ligne en observation.
  test('l\'identité part sur le FIL — se taire la ferait écrire au serveur, '
      'et elle ne vaudrait plus constat', () async {
    await repo().recordSale(cart: cart(), academicYearId: 'ay-1');

    final sale = await pushedSale();
    final tender = (sale['tenders'] as List).single as Map<String, dynamic>;

    expect(tender['amountInCents'], 5000);
    expect(tender['currency'], 'USD');
    expect(tender['pivotCurrency'], 'USD');
    expect(tender['rate'], closeTo(1, 1e-9));
  });

  test(
    'réglé en francs : le tiroir garde des FRANCS, la vente reste en dollars',
    () async {
      final recorded = await repo().recordSale(
        cart: cart(tender: const CartTender(currency: 'CDF')),
        academicYearId: 'ay-1',
      );
      final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

      final rows = await tendersOf(saleId);
      expect(rows.single['currency'], 'CDF');
      expect(rows.single['amount_in_cents'], 14000000); // 140 000 FC
      expect(rows.single['pivot_currency'], 'USD');
      expect(rows.single['rate_micros'], 2800000000);

      // La vente, elle, ne change pas d'unité : elle vaut toujours 50,00 $.
      final sale = await pushedSale();
      expect((sale['amounts'] as List).single, {
        'amountInCents': 5000,
        'currency': 'USD',
      });
    },
  );

  test('le fil porte le taux en DÉCIMAL, jamais en micro-unités', () async {
    await repo().recordSale(
      cart: cart(tender: const CartTender(currency: 'CDF')),
      academicYearId: 'ay-1',
    );

    final tender = ((await pushedSale())['tenders'] as List).single;
    expect(tender, {
      'amountInCents': 14000000,
      'currency': 'CDF',
      'rate': 2800.0,
      'pivotCurrency': 'USD',
    });
  });

  test(
    'un billet posé au-dessus du dû : le tiroir garde le dû, l’excédent repart',
    () async {
      // 150 000 FC posés pour 140 000 dus (50,00 \$ à 2 800). Le tiroir garde
      // 140 000 : la monnaie rendue n'est pas de la recette.
      final recorded = await repo().recordSale(
        cart: cart(
          tender: const CartTender(currency: 'CDF', tenderedCents: 15000000),
        ),
        academicYearId: 'ay-1',
      );
      final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

      final rows = await tendersOf(saleId);
      expect(rows.single['amount_in_cents'], 14000000);
    },
  );

  test(
    'un billet posé EN DESSOUS du dû ne fabrique pas une vente à moitié payée',
    () async {
      // Une vente est comptant intégral — il n'existe aucune colonne de reste
      // sur `boutique_sales`. Le tiroir garde donc le prix du panier converti,
      // jamais le montant incomplet : c'est l'écran qui dit ce qui manque.
      final recorded = await repo().recordSale(
        cart: cart(
          tender: const CartTender(currency: 'CDF', tenderedCents: 13900000),
        ),
        academicYearId: 'ay-1',
      );
      final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

      final rows = await tendersOf(saleId);
      expect(rows.single['amount_in_cents'], 14000000);
    },
  );

  test('sans taux paramétré, régler en francs n’a aucun effet', () async {
    await db.delete('ref_exchange_rates');

    final recorded = await repo().recordSale(
      cart: cart(tender: const CartTender(currency: 'CDF')),
      academicYearId: 'ay-1',
    );
    final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

    // Aucun taux ⇒ aucune conversion inventée : le tiroir prend des dollars.
    final rows = await tendersOf(saleId);
    expect(rows.single['currency'], 'USD');
    expect(rows.single['rate_micros'], ExchangeRate.scale);
  });

  test('la vente et ses lignes d’encaissement sont écrites ensemble', () async {
    final recorded = await repo().recordSale(
      cart: cart(tender: const CartTender(currency: 'CDF')),
      academicYearId: 'ay-1',
    );
    final saleId = recorded.getOrElse(() => throw 'attendu Right').sale.id;

    expect(await db.query('boutique_sales'), hasLength(1));
    expect(await tendersOf(saleId), hasLength(1));
    expect(
      await db.query('outbox'),
      hasLength(1),
      reason: 'une vente, une maille d’outbox — jamais deux',
    );
  });
}
