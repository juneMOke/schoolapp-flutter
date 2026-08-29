import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_sale_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
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
  label: 'Polo Lacoste',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'humanites': 1500},
  currency: 'USD',
);

const _payeur = CartPayer(
  lastName: 'Ndombo',
  middleName: 'Lelo',
  firstName: 'Willy',
  phoneNumber: '0810220145',
);

BoutiqueCart _readyCart({CartBeneficiary? beneficiary}) => BoutiqueCart(
  payer: _payeur,
  lines: [
    CartLine(
      key: 'k0',
      article: _polo,
      beneficiary: beneficiary,
      declaredLevelId: beneficiary == null ? 'humanites' : null,
      quantity: 2,
    ),
  ],
);

void main() {
  late Database db;
  late BoutiqueSaleWriteDao dao;
  late _MockDevice device;

  BoutiqueSaleRepositoryImpl repoWith({
    String? schoolId = 'E1',
    String? uid = 'u1',
  }) => BoutiqueSaleRepositoryImpl(
    dao: dao,
    currentUser: CurrentUserContext()..set(uid, schoolId: schoolId),
    ids: _SeqIds(),
    device: device,
    now: () => 1000,
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSaleWriteDao(db);
    device = _MockDevice();
    when(() => device.getOrCreateDeviceId()).thenAnswer((_) async => 'dev-1');
  });

  tearDown(() async => db.close());

  test('la vente, ses lignes et son outbox arrivent ENSEMBLE', () async {
    // Si l'une des trois manquait, l'argent serait dans un état que rien ne
    // rattrape : une vente sans outbox ne partirait jamais.
    final result = await repoWith().recordSale(
      cart: _readyCart(),
      academicYearId: 'ay-1',
    );

    expect(result.isRight(), isTrue);
    expect(await db.query('boutique_sales'), hasLength(1));
    expect(await db.query('boutique_sale_lines'), hasLength(1));
    final outbox = (await db.query('outbox')).single;
    expect(outbox['aggregate_type'], 'BOUTIQUE_SALE');
    // Sans `school_id`, l'entrée serait inéligible au flush scopé école.
    expect(outbox['school_id'], 'E1');
  });

  test(
    'le payload porte les montants en CENTS et le total du produit',
    () async {
      await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

      final payload =
          jsonDecode((await db.query('outbox')).single['payload'] as String)
              as Map<String, dynamic>;
      final line = (payload['lines'] as List).single as Map<String, dynamic>;

      expect(line['unitPriceInCents'], 1500);
      // Le serveur vérifie `lineTotal == pu × qté` au centime, et rend
      // INCONSISTENT_TOTAL sinon — sur une vente déjà encaissée.
      expect(line['lineTotalInCents'], 3000);
      expect((payload['sale'] as Map)['totalInCents'], 3000);
    },
  );

  test('AUCUN `payerName` ne part sur le fil', () async {
    // Le nom composé est dérivé serveur : en envoyer un laisserait croire que
    // le client décide de ce qui s'imprime.
    await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

    final payload =
        jsonDecode((await db.query('outbox')).single['payload'] as String)
            as Map<String, dynamic>;
    final sale = payload['sale'] as Map<String, dynamic>;

    expect(sale.containsKey('payerName'), isFalse);
    expect(sale['payerLastName'], 'Ndombo');
    expect(sale['payerMiddleName'], 'Lelo');
    expect(sale['payerFirstName'], 'Willy');
  });

  test('le nom composé local suit l\'ordre du serveur', () async {
    // Le ticket imprimé au guichet doit dire la même chose que le reçu scellé.
    await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

    final sale = (await db.query('boutique_sales')).single;
    expect(sale['payer_name'], 'NDOMBO Lelo Willy');
  });

  test('le téléphone est normalisé en E.164', () async {
    // La clé du répertoire : deux écritures du même numéro feraient deux
    // payeurs à la prochaine recherche.
    await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

    final sale = (await db.query('boutique_sales')).single;
    expect(sale['payer_phone_number'], '+243810220145');
  });

  test('le libellé de l\'article est RECOPIÉ sur la ligne', () async {
    // Le catalogue est remplacé en bloc à chaque bundle : une vente d'hier doit
    // rester lisible après le retrait de son article.
    await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

    final line = (await db.query('boutique_sale_lines')).single;
    expect(line['article_label'], 'Polo Lacoste');
    expect(line['article_code'], 'POLO');
  });

  test('le bénéficiaire emporte son niveau sur la ligne', () async {
    await repoWith().recordSale(
      cart: _readyCart(
        beneficiary: const CartBeneficiary(
          studentId: 'elv-1',
          fullName: 'David Mwepu',
          schoolLevelId: 'humanites',
        ),
      ),
      academicYearId: 'ay-1',
    );

    final line = (await db.query('boutique_sale_lines')).single;
    expect(line['beneficiary_student_id'], 'elv-1');
    expect(line['school_level_id'], 'humanites');
    // Le nom est figé : le reçu doit le nommer même si la fiche bouge.
    expect(line['beneficiary_name'], 'David Mwepu');
  });

  group('gardes locales — ne jamais subir un refus serveur', () {
    test('un panier NON prêt est refusé AVANT d\'écrire', () async {
      final result = await repoWith().recordSale(
        cart: const BoutiqueCart(),
        academicYearId: 'ay-1',
      );

      expect(result.isLeft(), isTrue);
      expect(await db.query('boutique_sales'), isEmpty);
      expect(await db.query('outbox'), isEmpty);
    });

    test('sans école : refus — l\'outbox serait inéligible au flush', () async {
      final result = await repoWith(
        schoolId: null,
      ).recordSale(cart: _readyCart(), academicYearId: 'ay-1');

      expect(result.isLeft(), isTrue);
      expect(await db.query('boutique_sales'), isEmpty);
    });

    test('sans utilisateur : refus — le serveur rendrait 403', () async {
      // `authorId` est vérifié côté serveur : on ne pousse que son propre
      // outbox. Pousser sans lui produirait un refus terminal sur de l'argent
      // déjà reçu.
      final result = await repoWith(
        uid: null,
      ).recordSale(cart: _readyCart(), academicYearId: 'ay-1');

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('un appareil sans identité n\'empêche PAS la vente', () async {
      // Best-effort : l'identifiant d'appareil est un confort de diagnostic, pas
      // une condition d'encaissement.
      when(
        () => device.getOrCreateDeviceId(),
      ).thenThrow(StateError('secure storage indisponible'));

      final result = await repoWith().recordSale(
        cart: _readyCart(),
        academicYearId: 'ay-1',
      );

      expect(result.isRight(), isTrue);
      expect((await db.query('boutique_sales')).single['device_id'], isNull);
    });
  });

  test('la vente naît PENDING_SYNC', () async {
    await repoWith().recordSale(cart: _readyCart(), academicYearId: 'ay-1');

    expect(
      (await db.query('boutique_sales')).single['sync_status'],
      'PENDING_SYNC',
    );
  });
}
