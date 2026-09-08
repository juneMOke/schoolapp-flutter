import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';

import '../../offline_full_db.dart';

/// Ce que le DAO du ticket doit désormais RAMENER : l'en-tête complet de
/// l'établissement, le payeur, et un caissier qui survit hors du poste
/// d'encaissement.
///
/// Ces trois blocs ont le même défaut d'origine : la donnée était en base et
/// descendait par le pull, mais la requête ne la sélectionnait pas. Un champ
/// manquant ici ne se voit qu'au papier, sur une ligne absente que rien ne
/// signale — d'où des tests au niveau de la requête, et pas seulement du rendu.
void main() {
  late Database db;
  late ProvisionalTicketDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ProvisionalTicketDao(db);
  });
  tearDown(() async => db.close());

  Future<void> seedSchool({
    String? address = '12, avenue de la Liberation',
    String? municipality = 'Ngaliema',
    String? city = 'Kinshasa',
    String? email = 'secretariat@lacolombe.cd',
    String? phone = '+243900000000',
  }) => db.insert('ref_school', {
    'id': 'sc-1',
    'name': 'Complexe scolaire La Colombe',
    'address': address,
    'municipality': municipality,
    'city': city,
    'email': email,
    'phone': phone,
  });

  Future<void> seedPayment({
    String? cashierFirstName,
    String? cashierLastName,
    String? collectedByName,
    String? payerFirstName,
    String? payerLastName,
    String? payerMiddleName,
    String? payerPhoneNumber,
    String? receiptId,
  }) => db.insert('payments', {
    'id': 'p-1',
    'client_uuid': 'p-1',
    'student_id': 's-1',
    'academic_year_id': 'y-1',
    'method': 'CASH',
    'paid_at': '2026-09-08T09:30:00.000',
    'cashier_first_name': cashierFirstName,
    'cashier_last_name': cashierLastName,
    'collected_by_name': collectedByName,
    'payer_first_name': payerFirstName,
    'payer_last_name': payerLastName,
    'payer_middle_name': payerMiddleName,
    'payer_phone_number': payerPhoneNumber,
    'receipt_id': receiptId,
    'device_id': 'dev-1',
    'sync_status': 'PENDING_SYNC',
    'updated_at': 0,
  });

  group('en-tête de l\'établissement', () {
    test('les six champs remontent', () async {
      await seedSchool();
      final school = await dao.findSchool();

      expect(school!.name, 'Complexe scolaire La Colombe');
      expect(school.address, '12, avenue de la Liberation');
      expect(school.email, 'secretariat@lacolombe.cd');
      expect(school.phone, '+243900000000');
    });

    /// La ville d'abord, la commune à défaut — l'inverse de l'ancien `locality`.
    ///
    /// L'en-tête demande « la ville », et `School.locality`, qui titre la
    /// bannière d'accueil, prenait déjà la ville en premier. Les deux
    /// divergeaient : la même tablette pouvait imprimer « Ngaliema » et
    /// afficher « Kinshasa ».
    test('la localité prend la ville avant la commune', () async {
      await seedSchool();
      expect((await dao.findSchool())!.locality, 'Kinshasa');
    });

    /// Le repli existe parce que le référentiel autorise l'un sans l'autre :
    /// une école qui ne renseigne que sa commune perdrait sa localité.
    test('sans ville, la commune tient la ligne', () async {
      await seedSchool(city: null);
      expect((await dao.findSchool())!.locality, 'Ngaliema');
    });

    test('sans ville ni commune, la ligne disparaît', () async {
      await seedSchool(city: null, municipality: null);
      expect((await dao.findSchool())!.locality, isNull);
    });

    /// Une chaîne vide n'est pas une localité. Sans ce filtre, la ligne
    /// s'imprimerait blanche et se lirait comme une mention effacée.
    test('une chaîne vide ne tient pas la ligne', () async {
      await seedSchool(city: '   ', municipality: null);
      expect((await dao.findSchool())!.locality, isNull);
    });

    test('référentiel non pullé : aucune école, et pas de levée', () async {
      expect(await dao.findSchool(), isNull);
    });
  });

  group('le caissier', () {
    test('les cashier_* de CE poste font autorité', () async {
      await seedPayment(
        cashierFirstName: 'Joseph',
        cashierLastName: 'Kabongo',
        collectedByName: 'Attribution Serveur',
      );
      expect((await dao.findPayment('p-1'))!.cashierFullName, 'Joseph Kabongo');
    });

    /// Le cas d'un versement encaissé sur une AUTRE caisse : le patch de pull ne
    /// touche jamais aux `cashier_*`, donc ils sont nuls, et sans ce repli le
    /// ticket sortirait sans personne à qui l'imputer (RG-012-11).
    test('hors du poste, l\'attribution serveur prend le relais', () async {
      await seedPayment(collectedByName: 'Marie Nsimba');
      expect((await dao.findPayment('p-1'))!.cashierFullName, 'Marie Nsimba');
    });

    test('aucun des deux : la ligne disparaît', () async {
      await seedPayment();
      expect((await dao.findPayment('p-1'))!.cashierFullName, isNull);
    });
  });

  group('le payeur', () {
    test('le nom se compose dans l\'ordre d\'usage', () async {
      await seedPayment(
        payerFirstName: 'Papa',
        payerLastName: 'Mbala',
        payerMiddleName: 'Kasa',
      );
      final row = await dao.findPayment('p-1');
      expect(row!.payerFullName, 'Mbala Kasa Papa');
      expect(row.hasPayer, isTrue);
    });

    /// `null`, jamais `''` : c'est cette distinction que le gabarit lit pour
    /// escamoter le bloc ENTIER. Une chaîne vide lui ferait imprimer un cadre
    /// vide, qui se lit comme une mention effacée.
    test('aucun payeur nommé rend null, jamais une chaîne vide', () async {
      await seedPayment();
      final row = await dao.findPayment('p-1');
      expect(row!.payerFullName, isNull);
      expect(row.hasPayer, isFalse);
    });

    /// Un numéro seul a été TAPÉ, donc il désigne quelqu'un. Même règle que le
    /// ticket de vente boutique — deux pièces du même acte qui divergent se
    /// paient au rapprochement de caisse.
    test('un téléphone seul garde le bloc', () async {
      await seedPayment(payerPhoneNumber: '+243810000000');
      final row = await dao.findPayment('p-1');
      expect(row!.payerFullName, isNull);
      expect(row.hasPayer, isTrue);
    });

    test('un téléphone vide ne garde rien', () async {
      await seedPayment(payerPhoneNumber: '   ');
      expect((await dao.findPayment('p-1'))!.hasPayer, isFalse);
    });
  });

  group('la pièce scellée', () {
    /// `receipt_id` est le signal qui décidera du bandeau, et il doit être lu
    /// AFFIRMATIVEMENT. Il descend par le pull, donc il est disponible sur un
    /// versement encaissé ailleurs — là justement où aucune ligne
    /// `generated_documents` locale n'existe.
    test('l\'UUID du reçu remonte quand il existe', () async {
      await seedPayment(receiptId: 'rc-42');
      expect((await dao.findPayment('p-1'))!.receiptId, 'rc-42');
    });

    test('il est nul tant que rien n\'est scellé', () async {
      await seedPayment();
      expect((await dao.findPayment('p-1'))!.receiptId, isNull);
    });
  });
}
