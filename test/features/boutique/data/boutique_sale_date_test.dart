import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
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
import 'package:school_app_flutter/features/boutique/domain/entities/cart_tender.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
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
  unitPriceInCents: 5000,
  currency: 'USD',
);

/// La date de vente choisie au panier (BQ-19).
///
/// Elle part dans `soldAt` — l'heure MÉTIER, celle sur laquelle le serveur
/// range la vente dans la caisse d'un jour. Rien d'autre ne change sur le fil.
void main() {
  // Mardi 21 octobre 2026, 14 h 30, heure du guichet.
  final collectedAt = DateTime(2026, 10, 21, 14, 30, 5);

  late Database db;
  late _MockDevice device;

  BoutiqueSaleRepositoryImpl repo({DateTime? at}) => BoutiqueSaleRepositoryImpl(
    dao: BoutiqueSaleWriteDao(db),
    currentUser: CurrentUserContext()..set('u1', schoolId: 'E1'),
    ids: _SeqIds(),
    device: device,
    now: () => 1000,
    wallClock: () => at ?? collectedAt,
    rates: ExchangeRateReader(
      dao: ExchangeRateDao(db),
      currentUser: CurrentUserContext()..set('u1', schoolId: 'E1'),
    ),
  );

  BoutiqueCart cart({DateTime? saleDate, CartTender? tender}) => BoutiqueCart(
    lines: const [CartLine(key: 'k0', article: _polo)],
    tenders: tender == null ? const {} : {'USD': tender},
  ).withSaleDate(saleDate);

  Future<Map<String, dynamic>> pushedSale() async {
    final entry = (await db.query('outbox')).single;
    final payload =
        jsonDecode(entry['payload'] as String) as Map<String, dynamic>;
    return payload['sale'] as Map<String, dynamic>;
  }

  setUp(() async {
    db = await openFullOfflineDb();
    device = _MockDevice();
    when(() => device.getOrCreateDeviceId()).thenAnswer((_) async => 'dev-1');
  });

  tearDown(() async => db.close());

  test(
    'sans date choisie : `soldAt` est l\'instant de l\'encaissement',
    () async {
      final result = await repo().recordSale(
        cart: cart(),
        academicYearId: 'ay-1',
      );

      final expected = collectedAt.toUtc().toIso8601String();
      expect(result.isRight(), isTrue);
      expect((await pushedSale())['soldAt'], expected);
      expect((await db.query('boutique_sales')).single['sold_at'], expected);
    },
  );

  test('antidatée : le JOUR choisi, à l\'heure RÉELLE de l\'encaissement — '
      'sur le fil, en base et sur la vente rendue au ticket', () async {
    final result = await repo().recordSale(
      cart: cart(saleDate: DateTime(2026, 10, 19)),
      academicYearId: 'ay-1',
    );

    final expected = DateTime(
      2026,
      10,
      19,
      14,
      30,
      5,
    ).toUtc().toIso8601String();
    expect((await pushedSale())['soldAt'], expected);
    expect((await db.query('boutique_sales')).single['sold_at'], expected);
    // Le ticket imprime `RecordedSale.sale.soldAt` : c'est lui qui doit porter
    // le jour choisi, sinon le client repart avec la date du jour.
    final recorded = result.getOrElse(() => throw 'attendu Right');
    expect(recorded, isA<RecordedSale>());
    expect(recorded.sale.soldAt, expected);
  });

  test('un jour FUTUR est refusé avant toute écriture', () async {
    // Le sélecteur ne le propose pas : seule une horloge qui recule entre le
    // choix et l'encaissement le produit. Le serveur ramènerait la vente à son
    // heure à lui, en silence.
    final result = await repo().recordSale(
      cart: cart(saleDate: DateTime(2026, 10, 22)),
      academicYearId: 'ay-1',
    );

    expect(result, isA<Left<Failure, RecordedSale>>());
    expect(
      result.fold((failure) => failure, (_) => null),
      isA<ValidationFailure>(),
    );
    expect(await db.query('boutique_sales'), isEmpty);
    expect(await db.query('outbox'), isEmpty);
  });

  test('antidatée, le taux appliqué reste celui de l\'ENCAISSEMENT', () async {
    // Deux points : l'ancien taux, et celui entré en vigueur une heure avant
    // l'encaissement. Une vente antidatée de deux jours résolue sur `soldAt`
    // prendrait l'ancien — alors que les francs entrent dans le tiroir
    // aujourd'hui, au taux du jour.
    await ExchangeRateDao(db).replaceForSchool([
      const ExchangeRateLocalModel(
        schoolId: 'E1',
        base: 'USD',
        quote: 'CDF',
        effectiveFrom: '2020-01-01T00:00:00Z',
        rateMicros: 2800000000,
      ),
      ExchangeRateLocalModel(
        schoolId: 'E1',
        base: 'USD',
        quote: 'CDF',
        effectiveFrom: collectedAt
            .subtract(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
        rateMicros: 3000000000,
      ),
    ], schoolId: 'E1');

    final result = await repo().recordSale(
      cart: cart(
        saleDate: DateTime(2026, 10, 19),
        tender: const CartTender(currency: 'CDF'),
      ),
      academicYearId: 'ay-1',
    );

    expect(result.isRight(), isTrue);
    final tender = (await db.query('boutique_sale_tenders')).single;
    expect(tender['currency'], 'CDF');
    expect(tender['rate_micros'], 3000000000);
  });
}
