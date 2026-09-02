import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_dao.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_local_model.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/configuration/data/datasources/provisioning_remote_data_source.dart';
import 'package:school_app_flutter/features/configuration/data/models/fee_code_model.dart';
import 'package:school_app_flutter/features/configuration/data/repositories/fee_code_section_cache_repository_impl.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _MockRemote extends Mock implements ProvisioningRemoteDataSource {}

/// Un DAO dont l'écriture échoue — une base momentanément illisible.
class _ThrowingDao extends Mock implements FeeCodeSectionDao {}

/// Le cache des titres de sections (GF-0) : ce qui descend, et ce qui n'écrase
/// jamais rien.
void main() {
  late Database db;
  late FeeCodeSectionDao dao;
  late _MockRemote remote;
  late CurrentUserContext currentUser;
  late FeeCodeSectionCacheRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<FeeCodeSectionLocalModel>[]);
  });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FeeCodeSectionDao(db);
    remote = _MockRemote();
    currentUser = CurrentUserContext()..set('u-1', schoolId: 'school-A');
    repository = FeeCodeSectionCacheRepositoryImpl(
      remote: remote,
      dao: dao,
      currentUser: currentUser,
      requiredAuth: const {},
      clock: () => DateTime.utc(2026, 9, 2),
    );
  });
  tearDown(() async => db.close());

  FeeCodeModel model(String code, String? label, {bool? active, int? order}) =>
      FeeCodeModel(code: code, label: label, active: active, sortOrder: order);

  group('ensureFeeSectionTitles', () {
    test('demande le catalogue COMPLET, masquées comprises', () async {
      when(
        () => remote.getFeeCodes(any(), any()),
      ).thenAnswer((_) async => [model('TUITION', 'Frais scolaires')]);

      await repository.ensureFeeSectionTitles();

      // Le piège de SF-4 : sans `includeHidden`, une créance posée sur une
      // nature depuis masquée retomberait sur la nature localisée alors que
      // l'école l'a nommée.
      verify(() => remote.getFeeCodes(any(), true)).called(1);
      verifyNever(() => remote.getFeeCodes(any(), false));
    });

    test('range les titres sous l\'école de la session', () async {
      when(() => remote.getFeeCodes(any(), any())).thenAnswer(
        (_) async => [
          model('TUITION', 'Frais scolaires', order: 0),
          model('BOARDING', 'Internat', active: false, order: 1),
        ],
      );

      final result = await repository.ensureFeeSectionTitles();

      expect(result.getOrElse(() => -1), 2);
      expect(await dao.titlesForSchool('school-A'), {
        'TUITION': 'Frais scolaires',
        'BOARDING': 'Internat',
      });
      expect(await dao.titlesForSchool('school-B'), isEmpty);
    });

    test('un titre absent retombe sur le CODE, jamais sur du blanc', () async {
      when(
        () => remote.getFeeCodes(any(), any()),
      ).thenAnswer((_) async => [model('CANTEEN', null)]);

      await repository.ensureFeeSectionTitles();

      // `FeeCodeModel.toEntity` replie déjà l'absence sur le code : mieux vaut
      // « CANTEEN » qu'une ligne vide — et surtout, la ligne reste écrite, donc
      // le compte servi reste vérifiable.
      expect(await dao.titlesForSchool('school-A'), {'CANTEEN': 'CANTEEN'});
    });

    test('sans école résolue : rien tiré, rien écrit, aucun échec', () async {
      currentUser.clear();

      final result = await repository.ensureFeeSectionTitles();

      expect(result.getOrElse(() => -1), 0);
      verifyNever(() => remote.getFeeCodes(any(), any()));
    });

    test('un échec réseau laisse le cache EN PLACE', () async {
      // Le cache d'une session précédente, écrit directement : c'est l'état
      // réel d'une tablette qui rouvre l'application hors couverture.
      await dao.replaceForSchool([
        const FeeCodeSectionLocalModel(
          schoolId: 'school-A',
          code: 'TUITION',
          label: 'Frais scolaires',
        ),
      ], schoolId: 'school-A');

      when(() => remote.getFeeCodes(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/finance/fee-codes'),
          type: DioExceptionType.connectionError,
        ),
      );
      final result = await repository.ensureFeeSectionTitles();

      expect(result.isLeft(), isTrue);
      expect(
        await dao.titlesForSchool('school-A'),
        {'TUITION': 'Frais scolaires'},
        reason:
            'Un titre d\'hier vaut mieux qu\'un écran qui se renomme tout '
            'seul parce que le réseau a manqué.',
      );
    });

    test('un 403 est un échec typé, pas un cache vidé', () async {
      when(() => remote.getFeeCodes(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/finance/fee-codes'),
          response: Response(
            requestOptions: RequestOptions(path: '/finance/fee-codes'),
            statusCode: 403,
          ),
        ),
      );

      final result = await repository.ensureFeeSectionTitles();

      expect(
        result.swap().getOrElse(() => const NetworkFailure()),
        isA<ServerFailure>(),
      );
      expect(await dao.titlesForSchool('school-A'), isEmpty);
    });
  });

  group('cacheFeeCodeSections', () {
    test(
      'écrit ce qu\'on vient de recevoir, sans rappeler le serveur',
      () async {
        final result = await repository.cacheFeeCodeSections(const [
          FeeCodeOption(
            code: 'TUITION',
            label: 'Frais de scolarité',
            sortOrder: 0,
          ),
        ]);

        expect(result.isRight(), isTrue);
        expect(await dao.titlesForSchool('school-A'), {
          'TUITION': 'Frais de scolarité',
        });
        verifyNever(() => remote.getFeeCodes(any(), any()));
      },
    );

    test('sans école résolue : rien écrit, et surtout aucun échec', () async {
      currentUser.clear();

      final result = await repository.cacheFeeCodeSections(const [
        FeeCodeOption(code: 'TUITION', label: 'Frais scolaires', sortOrder: 0),
      ]);

      // Ce chemin suit un enregistrement RÉUSSI côté serveur : faire remonter
      // un échec ferait passer pour raté un renommage qui a bien eu lieu.
      expect(result.isRight(), isTrue);
    });
  });

  group('la garde de session', () {
    test('ne tire qu\'UNE fois par session', () async {
      when(
        () => remote.getFeeCodes(any(), any()),
      ).thenAnswer((_) async => [model('TUITION', 'Frais scolaires')]);

      final first = await repository.ensureFeeSectionTitles();
      final second = await repository.ensureFeeSectionTitles();

      expect(first.getOrElse(() => -1), 1);
      expect(
        second.getOrElse(() => -1),
        0,
        reason: 'Un titre de section ne change pas dans la journée.',
      );
      verify(() => remote.getFeeCodes(any(), any())).called(1);
    });

    test(
      'un ÉCHEC ne referme pas la porte : la session peut retenter',
      () async {
        // Une tablette démarrée hors couverture nommerait sinon ses frais par la
        // nature jusqu'à la déconnexion.
        when(() => remote.getFeeCodes(any(), any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/finance/fee-codes'),
            type: DioExceptionType.connectionError,
          ),
        );
        expect((await repository.ensureFeeSectionTitles()).isLeft(), isTrue);

        when(
          () => remote.getFeeCodes(any(), any()),
        ).thenAnswer((_) async => [model('TUITION', 'Frais scolaires')]);
        final retry = await repository.ensureFeeSectionTitles();

        expect(retry.getOrElse(() => -1), 1);
        expect(await dao.titlesForSchool('school-A'), {
          'TUITION': 'Frais scolaires',
        });
      },
    );

    test('une ÉCRITURE en échec ne referme pas la porte non plus', () async {
      // La garde est armée après l'écriture, pas après la réponse du serveur.
      // Armée trop tôt, une base momentanément illisible laisserait la session
      // avec un cache vide ET une garde fermée : les frais nommés par la nature
      // jusqu'à la déconnexion, alors que le serveur avait répondu.
      //
      // Le DAO est doublé plutôt que la base fermée : `openFullOfflineDb` ouvre
      // `inMemoryDatabasePath`, dont le cycle de vie est partagé entre tests —
      // une fermeture y est verte en isolé et rouge dans la suite complète.
      final dao = _ThrowingDao();
      when(
        () => dao.replaceForSchool(any(), schoolId: any(named: 'schoolId')),
      ).thenThrow(StateError('base illisible'));
      final fragile = FeeCodeSectionCacheRepositoryImpl(
        remote: remote,
        dao: dao,
        currentUser: currentUser,
        requiredAuth: const {},
      );
      when(
        () => remote.getFeeCodes(any(), any()),
      ).thenAnswer((_) async => [model('TUITION', 'Frais scolaires')]);

      expect((await fragile.ensureFeeSectionTitles()).isLeft(), isTrue);

      // LA vérification : la garde n'a pas claqué, donc le serveur est réinterrogé.
      expect((await fragile.ensureFeeSectionTitles()).isLeft(), isTrue);
      verify(() => remote.getFeeCodes(any(), any())).called(2);
    });

    test('un renommage arme la garde : plus rien à tirer ensuite', () async {
      await repository.cacheFeeCodeSections(const [
        FeeCodeOption(code: 'TUITION', label: 'Frais annuels', sortOrder: 0),
      ]);

      final result = await repository.ensureFeeSectionTitles();

      expect(result.getOrElse(() => -1), 0);
      verifyNever(() => remote.getFeeCodes(any(), any()));
    });
  });
}
