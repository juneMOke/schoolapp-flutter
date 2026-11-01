import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/ref_cote_cours_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_delta_dto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';

void main() {
  late Database db;
  late RefCoteCoursLocalDataSource local;

  setUp(() async {
    db = await openFullOfflineDb();
    local = RefCoteCoursLocalDataSource(db);
  });
  tearDown(() => db.close());

  CoteDeltaDto delta(String col, double? valeur, {String cours = 'fr'}) =>
      CoteDeltaDto(
        studentId: 'e1',
        coursId: cours,
        colonneId: col,
        examen: false,
        valeur: valeur,
      );

  test('une page se lit : la colonne d\'une sous-période ou d\'un examen', () {
    final page = CotePageDto.fromJson({
      'items': [
        {
          'studentId': 'e1',
          'coursId': 'fr',
          'sousPeriodeId': 'P1',
          'periodeScolaireId': null,
          'valeur': 14.5,
          'updatedAt': '2026-11-01T10:42:00Z',
        },
        {
          'studentId': 'e1',
          'coursId': 'fr',
          'sousPeriodeId': null,
          'periodeScolaireId': 'S1',
          'valeur': null,
          'updatedAt': '2026-11-01T10:42:00Z',
        },
        {'studentId': 'sans colonne'},
      ],
      'nextCursor': 'c',
      'nextWatermark': 'w',
      'hasMore': false,
      'totalCount': 3,
      'serverTime': '2026-11-01T10:43:00Z',
    });

    expect(page.items, hasLength(2));
    expect(page.items.first.colonneId, 'P1');
    expect(page.items.first.examen, isFalse);
    expect(page.items.last.colonneId, 'S1');
    expect(page.items.last.examen, isTrue);
    expect(page.items.last.valeur, isNull);
  });

  test('la lecture rend les cotes, la dernière page gagne', () async {
    await local.applyPulled([delta('P1', 12)]);
    await local.applyPulled([delta('P1', 14)]);

    expect(await local.readForCours('fr'), {
      'P1': {'e1': 14.0},
    });
  });

  test('une cote vidée sort de la lecture', () async {
    await local.applyPulled([delta('P1', 12)]);
    await local.applyPulled([delta('P1', null)]);

    expect(await local.readForCours('fr'), isEmpty);
  });

  test('évincer un cours retire ses cotes, et lui seul', () async {
    await local.applyPulled([delta('P1', 12), delta('P1', 8, cours: 'an')]);

    await local.evictCours('fr');

    expect(await local.readForCours('fr'), isEmpty);
    expect(await local.readForCours('an'), isNotEmpty);
  });

  test('un cours évincé ne touche pas la saisie en attente', () async {
    await db.insert('cote_saisie', {
      'student_id': 'e1',
      'cours_id': 'fr',
      'colonne_id': 'P1',
      'classroom_id': 'c1',
      'has_draft': 1,
      'draft_valeur': 15.0,
      'draft_updated_at': 1,
      'sync_status': 'PENDING_SYNC',
    });

    await local.evictCours('fr');

    expect(await db.query('cote_saisie'), hasLength(1));
  });
}
