import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payer_directory_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';

import '../../offline_full_db.dart';

/// Annuaire local des payeurs : ce que la modale d'encaissement propose pour
/// éviter de ressaisir quatre champs à chaque trimestre.
void main() {
  late Database db;
  late FinancePayerDirectoryDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinancePayerDirectoryDao(db);
  });

  tearDown(() async => db.close());

  var seq = 0;

  Future<void> insertPayment({
    required String studentId,
    required String lastName,
    required String firstName,
    String? middleName,
    String? phone,
    required String paidAt,
  }) {
    final id = 'pay-${seq++}';
    return db.insert('payments', {
      'id': id,
      'client_uuid': id,
      'student_id': studentId,
      'academic_year_id': 'ay-1',
      'amount_in_cents': 100000,
      'currency': 'USD',
      'paid_at': paidAt,
      'payer_last_name': lastName,
      'payer_first_name': firstName,
      'payer_middle_name': middleName,
      'payer_phone_number': phone,
      'updated_at': 0,
    });
  }

  Future<void> linkGuardian({
    required String studentId,
    required String parentId,
    required String lastName,
    required String firstName,
    String? surname,
    String phone = '+243990000000',
  }) async {
    await db.insert('parents', {
      'id': parentId,
      'last_name': lastName,
      'first_name': firstName,
      'surname': surname,
      'phone_number': phone,
      'updated_at': 0,
    });
    await db.insert('student_parent', {
      'student_id': studentId,
      'parent_id': parentId,
      'relationship_type': 'FATHER',
    });
  }

  group('payersForStudent', () {
    test(
      'propose les payeurs de l\'élève, du plus récent au plus ancien',
      () async {
        await insertPayment(
          studentId: 's-1',
          lastName: 'Kabongo',
          firstName: 'Joseph',
          phone: '+243810000001',
          paidAt: '2026-01-10T09:00:00.000Z',
        );
        await insertPayment(
          studentId: 's-1',
          lastName: 'Mbayo',
          firstName: 'Alice',
          phone: '+243810000002',
          paidAt: '2026-08-10T09:00:00.000Z',
        );

        final payers = await dao.payersForStudent('s-1');

        expect(payers.map((p) => p.lastName), ['Mbayo', 'Kabongo']);
        expect(
          payers.every((p) => p.origin == PayerOrigin.previousPayment),
          isTrue,
        );
      },
    );

    test('ne mélange pas les élèves', () async {
      await insertPayment(
        studentId: 's-2',
        lastName: 'Autre',
        firstName: 'Personne',
        phone: '+243810000003',
        paidAt: '2026-08-10T09:00:00.000Z',
      );

      expect(await dao.payersForStudent('s-1'), isEmpty);
    });

    /// Le même payeur écrit deux fois avec une casse ou des accents différents
    /// est UNE personne. Deux lignes, chacune avec la moitié de l'historique,
    /// c'est exactement la ressaisie que l'écran cherche à supprimer.
    test('fond les orthographes d\'un même payeur, accents compris', () async {
      await insertPayment(
        studentId: 's-1',
        lastName: 'KABONGO',
        firstName: 'José',
        phone: '+243810000001',
        paidAt: '2026-01-10T09:00:00.000Z',
      );
      await insertPayment(
        studentId: 's-1',
        lastName: 'Kabongo',
        firstName: 'Jose',
        phone: '+243810000001',
        paidAt: '2026-08-10T09:00:00.000Z',
      );

      final payers = await dao.payersForStudent('s-1');

      expect(payers, hasLength(1));
      expect(payers.single.paymentCount, 2);
      // L'orthographe retenue est celle du versement le PLUS RÉCENT.
      expect(payers.single.firstName, 'Jose');
    });

    /// Un payeur dont le dernier passage est antérieur à la v28 n'a pas de
    /// numéro sur cette ligne-là. Le proposer sans numéro alors qu'on en
    /// connaît un plus ancien serait une régression silencieuse.
    test(
      'récupère le dernier numéro CONNU quand le plus récent est nul',
      () async {
        await insertPayment(
          studentId: 's-1',
          lastName: 'Kabongo',
          firstName: 'Joseph',
          phone: '+243810000001',
          paidAt: '2026-01-10T09:00:00.000Z',
        );
        await insertPayment(
          studentId: 's-1',
          lastName: 'Kabongo',
          firstName: 'Joseph',
          paidAt: '2026-08-10T09:00:00.000Z',
        );

        final payers = await dao.payersForStudent('s-1');

        expect(payers, hasLength(1));
        expect(payers.single.phoneNumber, '+243810000001');
        expect(payers.single.paymentCount, 2);
      },
    );

    test('ajoute les tuteurs APRÈS les payeurs constatés', () async {
      await insertPayment(
        studentId: 's-1',
        lastName: 'Kabongo',
        firstName: 'Joseph',
        phone: '+243810000001',
        paidAt: '2026-08-10T09:00:00.000Z',
      );
      await linkGuardian(
        studentId: 's-1',
        parentId: 'p-1',
        lastName: 'Mbayo',
        firstName: 'Alice',
        surname: 'Nsimba',
      );

      final payers = await dao.payersForStudent('s-1');

      expect(payers.map((p) => p.lastName), ['Kabongo', 'Mbayo']);
      expect(payers.last.origin, PayerOrigin.guardian);
      // `parents.surname` porte le POST-NOM, que le versement nomme
      // `middle_name` : les croiser mettrait le post-nom dans le prénom.
      expect(payers.last.middleName, 'Nsimba');
      expect(payers.last.paymentCount, 0);
    });

    /// Un tuteur qui a déjà payé doit se présenter par ce qui est CONSTATÉ,
    /// pas par sa seule qualité de tuteur — et une seule fois.
    test('un tuteur qui a déjà payé n\'apparaît qu\'une fois', () async {
      await insertPayment(
        studentId: 's-1',
        lastName: 'Mbayo',
        firstName: 'Alice',
        phone: '+243810000002',
        paidAt: '2026-08-10T09:00:00.000Z',
      );
      await linkGuardian(
        studentId: 's-1',
        parentId: 'p-1',
        lastName: 'Mbayo',
        firstName: 'Alice',
      );

      final payers = await dao.payersForStudent('s-1');

      expect(payers, hasLength(1));
      expect(payers.single.origin, PayerOrigin.previousPayment);
    });

    test('ignore un versement sans identité exploitable', () async {
      await insertPayment(
        studentId: 's-1',
        lastName: '  ',
        firstName: '',
        paidAt: '2026-08-10T09:00:00.000Z',
      );

      expect(await dao.payersForStudent('s-1'), isEmpty);
    });
  });

  group('searchPayers', () {
    setUp(() async {
      await insertPayment(
        studentId: 's-1',
        lastName: 'Kabóngo',
        firstName: 'Joseph',
        phone: '+243816939060',
        paidAt: '2026-08-10T09:00:00.000Z',
      );
      await insertPayment(
        studentId: 's-2',
        lastName: 'Mbayo',
        firstName: 'Alice',
        phone: '0997654321',
        paidAt: '2026-08-11T09:00:00.000Z',
      );
    });

    test('sans aucun critère : liste vide', () async {
      expect(await dao.searchPayers(), isEmpty);
      expect(await dao.searchPayers(lastName: '  '), isEmpty);
    });

    /// Le parent paie pour toute la fratrie : le cantonner à l'élève courant le
    /// rendrait introuvable au premier versement d'un cadet.
    test('cherche au-delà de l\'élève courant', () async {
      final found = await dao.searchPayers(lastName: 'Mbayo');

      expect(found.map((p) => p.firstName), ['Alice']);
    });

    test('trouve malgré les accents et la casse', () async {
      final found = await dao.searchPayers(lastName: 'kabongo');

      expect(found, hasLength(1));
      expect(found.single.firstName, 'Joseph');
    });

    /// Un seul mot suffit, et il peut viser n'importe quelle partie du nom : le
    /// guichetier n'a souvent que le prénom sous les yeux.
    test('un prénom seul suffit', () async {
      final found = await dao.searchPayers(firstName: 'joseph');

      expect(found.map((p) => p.lastName), ['Kabóngo']);
    });

    test('les critères d\'identité se combinent en ET', () async {
      expect(
        await dao.searchPayers(lastName: 'Kabongo', firstName: 'Alice'),
        isEmpty,
      );
      expect(
        await dao.searchPayers(lastName: 'Kabongo', firstName: 'Joseph'),
        hasLength(1),
      );
    });

    /// Une bribe suffit, et la colonne peut porter des écritures héritées
    /// (`0997654321`) que le critère E.164 doit quand même rapprocher.
    test(
      'cherche par bribe de numéro, format d\'écriture indifférent',
      () async {
        expect(await dao.searchPayers(phoneNumber: '8169'), hasLength(1));
        expect(
          (await dao.searchPayers(
            phoneNumber: '+243997654321',
          )).single.lastName,
          'Mbayo',
        );
      },
    );

    /// Les jokers SQL saisis par mégarde doivent être cherchés littéralement,
    /// sinon `%` remonterait tout le carnet.
    test('un joker LIKE dans le numéro ne remonte pas tout', () async {
      expect(await dao.searchPayers(phoneNumber: '%'), isEmpty);
    });

    /// Le filtre d'identité étant en Dart, rien côté SQL ne borne le travail :
    /// sans plafond, une recherche par identité matérialise TOUS les payeurs
    /// distincts de la table sur l'isolate de l'UI.
    group('plafond de balayage', () {
      setUp(() async {
        // Trois payeurs de plus, du plus ancien au plus récent.
        for (var i = 0; i < 3; i++) {
          await insertPayment(
            studentId: 's-3',
            lastName: 'Ngoy',
            firstName: 'Payeur$i',
            phone: '+24381000000$i',
            paidAt: '2026-08-0${i + 1}T09:00:00.000Z',
          );
        }
      });

      /// Le plafond porte sur la récence GLOBALE, avant tout filtre
      /// d'identité : les 3 groupes lus ici sont Mbayo (08-11), Kabóngo
      /// (08-10) et le seul Ngoy assez récent pour entrer.
      test('ne ramène que les groupes les plus récemment actifs', () async {
        final found = await dao.searchPayers(lastName: 'Ngoy', scanCap: 3);

        expect(found.map((p) => p.firstName), ['Payeur2']);
      });

      /// Le prix du plafond, dit sans détour : sous le seuil, un payeur
      /// dormant devient introuvable, et rien ne le signale. C'est pourquoi
      /// la valeur par défaut est posée hors d'atteinte d'une base réelle.
      test('sous le plafond, un payeur dormant est hors d\'atteinte', () async {
        final found = await dao.searchPayers(lastName: 'Ngoy', scanCap: 2);

        expect(found, isEmpty);
      });

      test('le plafond par défaut ne coupe rien à cette échelle', () async {
        final found = await dao.searchPayers(lastName: 'Ngoy');

        expect(found.map((p) => p.firstName), [
          'Payeur2',
          'Payeur1',
          'Payeur0',
        ]);
      });
    });
  });
}
