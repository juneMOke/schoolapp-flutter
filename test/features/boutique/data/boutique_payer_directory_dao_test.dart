import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_payer_directory_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

void main() {
  late Database db;
  late BoutiquePayerDirectoryDao dao;

  Future<void> sell({
    required String id,
    String schoolId = 'E1',
    String? lastName = 'Ndombo',
    String? middleName = 'Lelo',
    String? firstName = 'Willy',
    String? payerName,
    String? phone = '+243810220145',
    String soldAt = '2026-08-29T11:42:00Z',
  }) => db.insert('boutique_sales', {
    'id': id,
    'school_id': schoolId,
    'academic_year_id': 'ay-1',
    'payer_last_name': lastName ?? '',
    'payer_middle_name': middleName,
    'payer_first_name': firstName,
    'payer_name': payerName,
    'payer_phone_number': phone,
    'total_in_cents': 1000,
    'currency': 'USD',
    'sold_at': soldAt,
  });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiquePayerDirectoryDao(db);
  });
  tearDown(() async => db.close());

  test('un payeur déjà venu est retrouvé, avec son compte de ventes', () async {
    await sell(id: 'v1');
    await sell(id: 'v2', soldAt: '2026-08-30T09:00:00Z');

    final payers = await dao.findByPhone(
      schoolId: 'E1',
      phoneNumber: '+243810220145',
    );

    expect(payers.single.displayName, 'Ndombo Lelo Willy');
    expect(payers.single.saleCount, 2);
  });

  test('le format d\'écriture du numéro n\'a aucune importance', () async {
    // `0810220145`, `+243 810 220 145` et `243810220145` désignent la même
    // personne : un payeur = un numéro, pas une écriture.
    await sell(id: 'v1', phone: '0810220145');

    for (final written in const [
      '+243810220145',
      '+243 810 220 145',
      '0810220145',
      '243810220145',
    ]) {
      final payers = await dao.findByPhone(
        schoolId: 'E1',
        phoneNumber: written,
      );
      expect(payers, hasLength(1), reason: written);
    }
  });

  test('⚠ deux indicatifs voisins ne se confondent PAS', () async {
    // Le `LIKE` du SQL est un pré-filtre : `+242…` et `+243…` partagent leurs
    // derniers chiffres, de part et d'autre du fleuve. Sans la confirmation en
    // Dart, une vente s'attacherait au payeur d'un autre pays.
    await sell(id: 'v1', phone: '+242810220145', lastName: 'Brazza');

    final payers = await dao.findByPhone(
      schoolId: 'E1',
      phoneNumber: '+243810220145',
    );

    expect(payers, isEmpty);
  });

  test('le répertoire d\'une AUTRE école n\'est jamais proposé', () async {
    await sell(id: 'v1', schoolId: 'E2');

    final payers = await dao.findByPhone(
      schoolId: 'E1',
      phoneNumber: '+243810220145',
    );

    expect(payers, isEmpty);
  });

  test('un numéro trop court ne cherche rien', () async {
    await sell(id: 'v1');

    expect(await dao.findByPhone(schoolId: 'E1', phoneNumber: ''), isEmpty);
  });

  test('une vente descendue du delta remplit le champ Nom', () async {
    // Le serveur dérive `payer_name` du triplet et ne le redescend pas découpé
    // sur les ventes d'avant l'alignement. Le redécouper serait une invention :
    // on le pose entier dans « Nom », ce qui vaut mieux que de tout retaper.
    await sell(
      id: 'v1',
      lastName: '',
      middleName: null,
      firstName: null,
      payerName: 'NDOMBO Lelo Willy',
    );

    final payer = (await dao.findByPhone(
      schoolId: 'E1',
      phoneNumber: '+243810220145',
    )).single;

    expect(payer.lastName, 'NDOMBO Lelo Willy');
    expect(payer.isSplit, isFalse);
  });

  test('l\'entrée DÉCOUPÉE gagne sur celle du delta, et les ventes '
      's\'additionnent', () async {
    // Deux lignes du même payeur : l'une saisie ici, l'autre descendue. C'est
    // la découpée qui remplit les trois champs — tout l'intérêt du répertoire.
    await sell(
      id: 'v1',
      lastName: '',
      middleName: null,
      firstName: null,
      payerName: 'NDOMBO Lelo Willy',
      soldAt: '2026-08-28T10:00:00Z',
    );
    await sell(id: 'v2', soldAt: '2026-08-29T10:00:00Z');

    final payer = (await dao.findByPhone(
      schoolId: 'E1',
      phoneNumber: '+243810220145',
    )).single;

    expect(payer.isSplit, isTrue);
    expect(payer.firstName, 'Willy');
    expect(payer.saleCount, 2);
  });
}
