import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/grades_referential_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockGradesReferentialPullApi extends Mock
    implements GradesReferentialPullApi {}

void main() {
  late Database db;
  late MockGradesReferentialPullApi api;
  late SyncMetaDao syncMeta;
  late AcademicsRefLocalDataSource refLocal;
  late GradesReferentialPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockGradesReferentialPullApi();
    syncMeta = SyncMetaDao(db);
    refLocal = AcademicsRefLocalDataSource(db);
    repo = GradesReferentialPullRepositoryImpl(
      api: api,
      refLocalDataSource: refLocal,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  CoursPullOutcome right(Either<Failure, CoursPullOutcome> e) =>
      e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

  HttpResponse<GradesReferentialBundleDto> httpOk(
    GradesReferentialBundleDto bundle, {
    String? etag,
  }) => HttpResponse(
    bundle,
    Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      headers: etag == null
          ? Headers()
          : Headers.fromMap({
              'etag': [etag],
            }),
    ),
  );

  DioException status(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  GradesReferentialBundleDto bundle({
    List<BrancheDto> branches = const [],
    List<LigneBaremeDto> ligneBaremes = const [],
    List<ChapitreDto> chapitres = const [],
    List<PeriodeDto> periodes = const [],
    List<SousPeriodeDto> sousPeriodes = const [],
  }) => GradesReferentialBundleDto(
    branches: branches,
    ligneBaremes: ligneBaremes,
    chapitres: chapitres,
    periodes: periodes,
    sousPeriodes: sousPeriodes,
  );

  test(
    '200 : remplace les 4 tables vivantes, persiste le nouvel ETag',
    () async {
      when(() => api.pullGradesReferential(auth, null)).thenAnswer(
        (_) async => httpOk(
          bundle(
            branches: const [BrancheDto(id: 'b1', nom: 'Maths')],
            ligneBaremes: const [
              LigneBaremeDto(
                id: 'lb1',
                grilleId: 'g1',
                rubriqueId: 'r1',
                brancheId: 'b1',
                ordre: 1,
                maxJournalierParSousPeriode: 2,
                maxExamenParPeriodeScolaire: null,
              ),
            ],
            chapitres: const [
              ChapitreDto(id: 'ch1', coursId: 'co1', titre: 'Ch1', ordre: 1),
            ],
            periodes: const [
              PeriodeDto(
                id: 'p1',
                academicYearId: 'ay1',
                schoolLevelGroupId: 'g1',
                ordre: 1,
                statut: 'CLOTUREE',
              ),
            ],
            sousPeriodes: const [
              SousPeriodeDto(
                id: 'sp1',
                periodeScolaireId: 'p1',
                ordre: 1,
                statut: 'OUVERTE',
              ),
            ],
          ),
          etag: '"abc"',
        ),
      );

      final outcome = right(await repo.syncGradesReferential());

      expect(outcome.upserted, 4);
      expect(outcome.notModified, isFalse);
      expect(await syncMeta.getCursor(kGradesReferentialResource), '"abc"');
      expect(await db.query('ref_branche'), hasLength(1));
      expect(await db.query('ref_ligne_bareme'), hasLength(1));
      // Les chapitres viennent du flux du programme de cours depuis la v61.
      expect(await db.query('ref_chapitre'), isEmpty);
      expect(await db.query('ref_periode'), hasLength(1));
      expect(await db.query('ref_sous_periode'), hasLength(1));
    },
  );

  test('200 après un précédent bundle : remplacement d\'ensemble (l\'ancien '
      'disparaît, pas de delta)', () async {
    when(() => api.pullGradesReferential(auth, null)).thenAnswer(
      (_) async => httpOk(
        bundle(
          branches: const [BrancheDto(id: 'b-old', nom: 'Ancien')],
        ),
        etag: '"v1"',
      ),
    );
    await repo.syncGradesReferential();

    when(() => api.pullGradesReferential(auth, '"v1"')).thenAnswer(
      (_) async => httpOk(
        bundle(
          branches: const [BrancheDto(id: 'b-new', nom: 'Nouveau')],
        ),
        etag: '"v2"',
      ),
    );
    await repo.syncGradesReferential();

    final rows = await db.query('ref_branche');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'b-new');
    expect(await syncMeta.getCursor(kGradesReferentialResource), '"v2"');
  });

  test('200 : les grilles et le rang des sous-périodes sont rangés', () async {
    when(() => api.pullGradesReferential(auth, null)).thenAnswer(
      (_) async => httpOk(
        GradesReferentialBundleDto.fromJson({
          'branches': [],
          'ligneBaremes': [],
          'chapitres': [],
          'periodes': [],
          'sousPeriodes': [
            {
              'id': 'sp3',
              'periodeScolaireId': 'p2',
              'ordre': 1,
              'statut': 'OUVERTE',
              'rang': 3,
            },
          ],
          'grilles': [
            {
              'id': 'g1',
              'intituleSousPeriode': 'Étape {n}',
              'intituleCourtSousPeriode': 'É{n}',
              'intituleExamen': 'Examen',
              'intituleCourtExamen': 'Exam.',
            },
            // Un motif manquant : la grille est écartée, pas le bundle.
            {'id': 'g2', 'intituleSousPeriode': 'P{n}'},
          ],
        }),
        etag: '"v229"',
      ),
    );

    final outcome = right(await repo.syncGradesReferential());

    expect(outcome.upserted, 2);
    final grille = await refLocal.getGrille('g1', ownerUid: null);
    expect(grille?.intituleSousPeriode, 'Étape {n}');
    expect(grille?.intituleCourtExamen, 'Exam.');
    expect(await refLocal.getGrille('g2', ownerUid: null), isNull);
    final sousPeriode = (await refLocal.getSousPeriodesForPeriodes(const [
      'p2',
    ], ownerUid: null)).single;
    expect(sousPeriode.rang, 3);
  });

  group('copie sans grilles : pas d\'ETag envoyé', () {
    Future<void> seed({required bool withGrille}) async {
      await db.insert('ref_ligne_bareme', {
        'id': 'lb1',
        'owner_uid': '',
        'grille_id': 'g1',
        'rubrique_id': 'r1',
        'branche_id': 'b1',
        'max_journalier_par_sous_periode': 20,
      });
      if (withGrille) {
        await db.insert('ref_grille', {
          'id': 'g1',
          'owner_uid': '',
          'intitule_sous_periode': 'P{n}',
          'intitule_court_sous_periode': 'P{n}',
          'intitule_examen': 'Examen',
          'intitule_court_examen': 'Exam.',
        });
      }
      await syncMeta.setCursor(
        kGradesReferentialResource,
        cursor: '"old"',
        syncedAt: 1,
      );
    }

    test('une ligne de barème sans sa grille : relue en entier', () async {
      await seed(withGrille: false);
      when(
        () => api.pullGradesReferential(auth, null),
      ).thenAnswer((_) async => httpOk(bundle(), etag: '"new"'));

      right(await repo.syncGradesReferential());

      verify(() => api.pullGradesReferential(auth, null)).called(1);
    });

    test('grilles présentes : l\'ETag part comme avant', () async {
      await seed(withGrille: true);
      when(
        () => api.pullGradesReferential(auth, '"old"'),
      ).thenThrow(status(304));

      final outcome = right(await repo.syncGradesReferential());

      expect(outcome.notModified, isTrue);
    });
  });

  test('getGrille et le remplacement restent bornés au compte', () async {
    await refLocal.replaceGradesReferential(
      GradesReferentialBundleDto.fromJson({
        'grilles': [
          {
            'id': 'g1',
            'intituleSousPeriode': 'Étape {n}',
            'intituleCourtSousPeriode': 'É{n}',
            'intituleExamen': 'Examen',
            'intituleCourtExamen': 'Exam.',
          },
        ],
      }),
      ownerUid: 'uA',
    );
    await refLocal.replaceGradesReferential(
      GradesReferentialBundleDto.fromJson(const {}),
      ownerUid: 'uB',
    );

    expect(await refLocal.getGrille('g1', ownerUid: 'uB'), isNull);
    expect(
      (await refLocal.getGrille('g1', ownerUid: 'uA'))?.intituleSousPeriode,
      'Étape {n}',
    );
  });

  test('304 : notModified, cache local et ETag conservés', () async {
    await syncMeta.setCursor(
      kGradesReferentialResource,
      cursor: '"prev"',
      syncedAt: 1,
    );
    await refLocal.replaceGradesReferential(
      bundle(
        branches: const [BrancheDto(id: 'b1', nom: 'Maths')],
      ),
      ownerUid: null,
    );
    when(
      () => api.pullGradesReferential(auth, '"prev"'),
    ).thenThrow(status(304));

    final outcome = right(await repo.syncGradesReferential());

    expect(outcome.notModified, isTrue);
    expect(await syncMeta.getCursor(kGradesReferentialResource), '"prev"');
    expect(await db.query('ref_branche'), hasLength(1));
  });

  test(
    '404 (compte non lié à un enseignant) → notModified, jamais une erreur',
    () async {
      when(() => api.pullGradesReferential(auth, null)).thenThrow(status(404));

      final outcome = right(await repo.syncGradesReferential());

      expect(outcome.notModified, isTrue);
      verify(() => api.pullGradesReferential(auth, null)).called(1);
    },
  );

  test('échec réseau (503) → Left, le coordinateur re-tentera', () async {
    when(() => api.pullGradesReferential(auth, null)).thenThrow(status(503));

    final result = await repo.syncGradesReferential();

    expect(result.isLeft(), isTrue);
  });

  test('tolérance par élément : une branche malformée n\'annule pas le reste '
      'du bundle', () async {
    when(() => api.pullGradesReferential(auth, null)).thenAnswer(
      (_) async => httpOk(
        GradesReferentialBundleDto.fromJson({
          'branches': [
            {'id': 'b1', 'nom': 'Maths'},
            {'id': 'b-bad'}, // 'nom' manquant → écarté
          ],
          'ligneBaremes': [],
          'chapitres': [],
          'periodes': [],
          'sousPeriodes': [],
        }),
        etag: '"abc"',
      ),
    );

    final outcome = right(await repo.syncGradesReferential());

    expect(outcome.upserted, 1);
    expect(await db.query('ref_branche'), hasLength(1));
  });

  test(
    'maxJournalierParSousPeriode absent → défaut 0 (tolérant, comme tous les '
    'autres champs numériques du bundle), la ligne de barème est conservée '
    '(pas droppée)',
    () async {
      when(() => api.pullGradesReferential(auth, null)).thenAnswer(
        (_) async => httpOk(
          GradesReferentialBundleDto.fromJson({
            'branches': [],
            'ligneBaremes': [
              {
                'id': 'lb1',
                'grilleId': 'g1',
                'rubriqueId': 'r1',
                'brancheId': 'b1',
                'ordre': 1,
                // 'maxJournalierParSousPeriode' volontairement omis.
                'maxExamenParPeriodeScolaire': null,
              },
            ],
            'chapitres': [],
            'periodes': [],
            'sousPeriodes': [],
          }),
          etag: '"abc"',
        ),
      );

      final outcome = right(await repo.syncGradesReferential());

      expect(outcome.upserted, 1);
      final rows = await db.query('ref_ligne_bareme');
      expect(rows, hasLength(1));
      expect(rows.single['max_journalier_par_sous_periode'], 0);
    },
  );
}
