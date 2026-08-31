import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reduction_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/reduction_grant_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_aggregate_request.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_payload.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/reduction_selection_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_charge_seed_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/reduction_catalog_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/reduction_catalog_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';

import '../../offline_full_db.dart';

/// La chaîne de RD-F2 : cocher → persister → envoyer.
///
/// Ce qui est protégé ici, dans l'ordre de ce que ça coûterait :
///
///  1. **Un payload d'outbox écrit AVANT le champ doit se relire.** Une
///     inscription confirmée dort peut-être déjà dans la file sans la clé ; un
///     `as List` y lèverait et bloquerait la file ENTIÈRE — donc les
///     encaissements et les inscriptions derrière — pour un champ qui ne vaut
///     aucun centime.
///  2. **Le champ ne part que s'il porte quelque chose.** Un `[]` systématique
///     dirait « retire tout » à un serveur qui, aujourd'hui, ne connaît pas
///     encore le champ.
///  3. **Décocher retire.** Un remplacement, jamais un ajout.
void main() {
  late Database db;

  EnrollmentPayload payload({List<String> codes = const []}) =>
      EnrollmentPayload(
        id: 'e1',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'PENDING',
        academicYearId: 'ay-1',
        enrollmentDate: '2026-08-31',
        reductionCodes: codes,
      );

  group('EnrollmentPayload — le champ sur le fil', () {
    test('payload legacy sans la clé → liste vide, pas une exception', () {
      final json = payload().toJson()..remove('reductionCodes');

      expect(EnrollmentPayload.fromJson(json).reductionCodes, isEmpty);
    });

    test('valeur non-liste ne fait pas lever la file', () {
      final json = payload().toJson();
      json['reductionCodes'] = <dynamic>['STAFF_CHILD', 42, null];

      // Ce qui n'est pas une chaîne est ignoré ; ce qui l'est passe. La file
      // ne s'arrête pas sur un serveur qui aurait servi un élément inattendu.
      expect(EnrollmentPayload.fromJson(json).reductionCodes, ['STAFF_CHILD']);
    });

    test('aller-retour des codes', () {
      final json = payload(codes: const ['SIBLING', 'STAFF_CHILD']).toJson();

      expect(EnrollmentPayload.fromJson(json).reductionCodes, [
        'SIBLING',
        'STAFF_CHILD',
      ]);
    });

    test('vide → clé absente du payload ET de la requête réseau', () {
      expect(payload().toJson().containsKey('reductionCodes'), isFalse);

      final wire = EnrollmentAggregateRequest(
        EnrollmentCommand(
          enrollment: payload(),
          student: const StudentPayload(
            id: 's1',
            firstName: 'A',
            lastName: 'B',
            surname: 'C',
            gender: 'MALE',
            dateOfBirth: '2015-01-01',
            birthPlace: '',
            nationality: '',
          ),
          parents: const [],
        ),
      ).toJson();

      expect(
        (wire['enrollment'] as Map<String, dynamic>).containsKey(
          'reductionCodes',
        ),
        isFalse,
      );
    });

    test('non vide → présent dans la requête réseau', () {
      final wire = EnrollmentAggregateRequest(
        EnrollmentCommand(
          enrollment: payload(codes: const ['STAFF_CHILD']),
          student: const StudentPayload(
            id: 's1',
            firstName: 'A',
            lastName: 'B',
            surname: 'C',
            gender: 'MALE',
            dateOfBirth: '2015-01-01',
            birthPlace: '',
            nationality: '',
          ),
          parents: const [],
        ),
      ).toJson();

      expect((wire['enrollment'] as Map<String, dynamic>)['reductionCodes'], [
        'STAFF_CHILD',
      ]);
    });
  });

  group('EnrollmentReductionDao', () {
    late EnrollmentReductionDao dao;

    setUp(() async {
      db = await openFullOfflineDb();
      dao = EnrollmentReductionDao(db);
    });
    tearDown(() async => db.close());

    test('décocher retire : c\'est un remplacement, pas un ajout', () async {
      await dao.replaceFor('e1', const ['A', 'B'], nowMs: 1);
      await dao.replaceFor('e1', const ['B'], nowMs: 2);

      expect(await dao.codesFor('e1'), ['B']);
    });

    test('un doublon ne fait pas perdre TOUS les octrois', () async {
      // Sans le `toSet()`, la clé primaire ferait échouer la transaction
      // entière — donc effacer les octrois pour un doublon sans conséquence.
      await dao.replaceFor('e1', const ['A', 'A', 'B'], nowMs: 1);

      expect(await dao.codesFor('e1'), ['A', 'B']);
    });

    test('les octrois d\'une autre inscription ne bougent pas', () async {
      await dao.replaceFor('e1', const ['A'], nowMs: 1);
      await dao.replaceFor('e2', const ['B'], nowMs: 1);

      await dao.replaceFor('e1', const [], nowMs: 2);

      expect(await dao.codesFor('e1'), isEmpty);
      expect(await dao.codesFor('e2'), ['B']);
    });
  });

  // ── L'invariant de la V1 ─────────────────────────────────────────────────
  //
  // « Mémoire seule » : la déclaration ne vaut aucun centime. Le semis local
  // ignore les octrois et sème au TARIF PLEIN, et il faut que ça reste vrai —
  // appliquer la remise « juste pour l'affichage » ferait annoncer au guichet
  // un net que le serveur régénère au plein tarif à l'ACK, après validation.
  group('aucun montant ne bouge', () {
    test('le semis est identique avec et sans réductions déclarées', () async {
      db = await openFullOfflineDb();
      addTearDown(() async => db.close());

      await db.insert('ref_fee_tariffs', {
        'id': 'tar-1',
        'academic_year_id': 'ay-1',
        'school_level_id': 'lvl-1',
        'fee_code': 'MINERVAL',
        'label': 'Minerval',
        'amount_in_cents': 150000,
        'currency': 'CDF',
        'updated_at': 0,
      });

      final seed = FinanceChargeSeedDao(db, const IdGenerator(Uuid()));

      final sans = await seed.initializeChargesForStudent(
        studentId: 's1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      // Le même élève, cette fois avec une réduction de 50 % déclarée.
      await EnrollmentReductionDao(
        db,
      ).replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1000);
      final avec = await seed.initializeChargesForStudent(
        studentId: 's2',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        nowMs: 1000,
      );

      expect(sans.single.expectedAmountInCents, 150000);
      expect(
        avec.single.expectedAmountInCents,
        sans.single.expectedAmountInCents,
      );
    });
  });

  group('ReductionSelectionCubit', () {
    late ReductionGrantRepositoryImpl repository;
    late EnrollmentReductionDao dao;

    setUp(() async {
      db = await openFullOfflineDb();
      dao = EnrollmentReductionDao(db);
      final catalog = ReductionCatalogDao(db);
      await catalog.replaceForSchool(
        const [
          ReductionTypeLocalModel(
            schoolId: 'A',
            code: 'STAFF_CHILD',
            label: 'Enfant du personnel',
          ),
        ],
        const [
          ReductionLineLocalModel(
            schoolId: 'A',
            reductionCode: 'STAFF_CHILD',
            feeCode: 'MINERVAL',
            percentage: 50,
          ),
        ],
        schoolId: 'A',
      );
      repository = ReductionGrantRepositoryImpl(
        dao: dao,
        readGrantable: catalog.grantableForSchool,
        currentUser: CurrentUserContext()..set('u1', schoolId: 'A'),
        now: () => 42,
      );
    });
    tearDown(() async => db.close());

    test(
      'cocher persiste immédiatement — il n\'y a pas d\'enregistrement',
      () async {
        final cubit = ReductionSelectionCubit(repository);
        await cubit.load('e1');

        await cubit.toggle('e1', 'STAFF_CHILD');

        // L'étape Frais n'a pas de bouton « Enregistrer » (PARCOURS 21) : une
        // case qui attendrait une validation d'étape se perdrait en silence.
        expect(await dao.codesFor('e1'), ['STAFF_CHILD']);
        expect(cubit.state.selected, {'STAFF_CHILD'});
        await cubit.close();
      },
    );

    test('décocher persiste aussi', () async {
      await dao.replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1);
      final cubit = ReductionSelectionCubit(repository);
      await cubit.load('e1');
      expect(cubit.state.selected, {'STAFF_CHILD'});

      await cubit.toggle('e1', 'STAFF_CHILD');

      expect(await dao.codesFor('e1'), isEmpty);
      await cubit.close();
    });

    test(
      'un octroi dont le type a quitté le barème reste sélectionné',
      () async {
        await dao.replaceFor('e1', const ['DISPARU'], nowMs: 1);
        final cubit = ReductionSelectionCubit(repository);

        await cubit.load('e1');

        // Il ne se propose plus — mais le retirer d'office reviendrait à
        // révoquer une réduction parce qu'une liste a changé.
        expect(cubit.state.options.map((o) => o.code), ['STAFF_CHILD']);
        expect(cubit.state.selected, {'DISPARU'});
        // …et il reste VISIBLE, sous son code faute de libellé. Ne montrer que
        // le barème le cacherait : la réduction existerait en base, partirait
        // dans l'agrégat, et l'écran n'en dirait rien.
        expect(cubit.state.entries.map((e) => e.code), [
          'STAFF_CHILD',
          'DISPARU',
        ]);
        expect(cubit.state.entries.last.label, 'DISPARU');
        await cubit.close();
      },
    );

    test(
      'barème non communiqué mais octroi présent → la section s\'affiche',
      () async {
        await dao.replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1);
        // `finance.grid.read` manquant : le serveur caviarde le barème, donc
        // aucune option ne descend. La réduction, elle, est bien là.
        final withheld = ReductionGrantRepositoryImpl(
          dao: dao,
          readGrantable: (_) async => const <GrantableReduction>[],
          currentUser: CurrentUserContext()..set('u1', schoolId: 'A'),
        );
        final cubit = ReductionSelectionCubit(withheld);

        await cubit.load('e1');

        expect(cubit.state.isEmpty, isFalse);
        expect(cubit.state.entries.single.code, 'STAFF_CHILD');
        await cubit.close();
      },
    );

    test('barème vide → la section n\'a rien à afficher', () async {
      final empty = ReductionGrantRepositoryImpl(
        dao: dao,
        readGrantable: (_) async => const <GrantableReduction>[],
        currentUser: CurrentUserContext()..set('u1', schoolId: 'A'),
      );
      final cubit = ReductionSelectionCubit(empty);

      await cubit.load('e1');

      expect(cubit.state.isEmpty, isTrue);
      await cubit.close();
    });
  });
}
