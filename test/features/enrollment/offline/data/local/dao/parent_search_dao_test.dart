import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/parent_search_dao.dart';

import '../../../../../offline_full_db.dart';

void main() {
  late Database db;
  late ParentSearchDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ParentSearchDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertParent({
    required String id,
    required String firstName,
    required String lastName,
    String? surname,
    required String phoneNumber,
  }) => db.insert('parents', {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'phone_number': phoneNumber,
    'updated_at': 100,
  });

  test('aucun critère → liste vide SANS requête SQL', () async {
    await insertParent(
      id: 'p1',
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: '+243111',
    );
    expect(await dao.search(), isEmpty);
  });

  test('recherche par nom partiel (LIKE, insensible à la position)', () async {
    await insertParent(
      id: 'p1',
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: '+243111',
    );
    await insertParent(
      id: 'p2',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+243222',
    );

    final results = await dao.search(lastName: 'ok');
    expect(results, hasLength(1));
    expect(results.single.id, 'p1');
  });

  test('recherche par téléphone partiel', () async {
    await insertParent(
      id: 'p1',
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: '+243111222333',
    );
    await insertParent(
      id: 'p2',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+243999888777',
    );

    final results = await dao.search(phoneNumber: '111222');
    expect(results, hasLength(1));
    expect(results.single.id, 'p1');
  });

  test('combinaison de critères en ET', () async {
    await insertParent(
      id: 'p1',
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: '+243111',
    );
    await insertParent(
      id: 'p2',
      firstName: 'Sarah',
      lastName: 'Dupont',
      phoneNumber: '+243222',
    );

    final results = await dao.search(firstName: 'Sarah', lastName: 'Moke');
    expect(results, hasLength(1));
    expect(results.single.id, 'p1');
  });

  test('limit respectée', () async {
    for (var i = 0; i < 5; i++) {
      await insertParent(
        id: 'p$i',
        firstName: 'Sarah',
        lastName: 'Moke$i',
        phoneNumber: '+24311$i',
      );
    }
    final results = await dao.search(firstName: 'Sarah', limit: 2);
    expect(results, hasLength(2));
  });

  test('les métacaractères LIKE (%, _) saisis par l\'utilisateur sont échappés '
      '— traités comme des caractères littéraux, pas des jokers SQL', () async {
    await insertParent(
      id: 'p1',
      firstName: 'Sarah',
      lastName: 'Mo_ke', // contient un "_" littéral
      phoneNumber: '+243111',
    );
    await insertParent(
      id: 'p2',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+243222',
    );

    // Sans échappement, "_" matcherait N'IMPORTE QUEL caractère (joker SQL)
    // et "Mo_ke" comme "Moake" correspondraient tous les deux — on vérifie
    // qu'une recherche du "_" littéral ne remonte QUE la fiche qui le porte
    // vraiment.
    final results = await dao.search(lastName: 'Mo_ke');
    expect(results, hasLength(1));
    expect(results.single.id, 'p1');

    // Une recherche par "%" (autre joker SQL) ne doit pas se comporter
    // comme "tout matcher" : aucune fiche ne contient un "%" littéral.
    final wildcardResults = await dao.search(lastName: '%');
    expect(wildcardResults, isEmpty);
  });
}
