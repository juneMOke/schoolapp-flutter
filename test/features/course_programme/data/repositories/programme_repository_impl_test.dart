import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_online_reader.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../programme_test_fakes.dart';

class _MockOnline extends Mock implements ProgrammeOnlineReader {}

class _MockIds extends Mock implements IdGenerator {}

/// Local d'abord ; un cours absent de la tablette se lit en ligne.
void main() {
  late Database db;
  late _MockOnline online;
  late ProgrammeRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    online = _MockOnline();
    repository = ProgrammeRepositoryImpl(
      dao: ChapitreDao(db),
      writer: ChapitreWriteDao(db: db, blobs: FakeProgrammeBlobs()),
      evaluations: AcademicsLocalDataSource(db),
      cours: AcademicsRefLocalDataSource(db),
      online: online,
      ids: _MockIds(),
      currentUser: CurrentUserContext(),
      now: () => DateTime.utc(2026, 10, 6).millisecondsSinceEpoch,
    );
  });
  tearDown(() => db.close());

  Future<void> seedCours() => db.insert('ref_cours', {
    'id': 'c-1',
    'classroom_id': 'class-1',
    'ligne_bareme_id': 'lb-1',
    'synced_at': 1,
  });

  test('un cours de la tablette se lit en local', () async {
    await seedCours();
    final result = await repository.loadProgramme('c-1');
    expect(result.isRight(), isTrue);
    verifyNever(() => online.readProgramme(any()));
  });

  test('un cours absent se lit en ligne', () async {
    when(() => online.readProgramme('c-9')).thenAnswer(
      (_) async => const Right(Programme(coursId: 'c-9', chapitres: [])),
    );
    final result = await repository.loadProgramme('c-9');
    expect(result.isRight(), isTrue);
  });

  test('un chapitre absent se lit en ligne', () async {
    when(() => online.readChapitre('ch-9')).thenAnswer(
      (_) async => const Right(
        ChapitreDetail(
          chapitre: Chapitre(id: 'ch-9', coursId: 'c-9', ordre: 0, titre: 'X'),
          numero: 1,
        ),
      ),
    );
    final result = await repository.loadChapitre('ch-9');
    expect(result.isRight(), isTrue);
  });

  test('enregistrer horodate la fiche et ne garde pas un bloc vide', () async {
    final result = await repository.saveChapitre(
      const Chapitre(
        id: 'ch-1',
        coursId: 'c-1',
        ordre: 0,
        titre: 'Fractions',
        blocs: [
          ChapitreBloc(
            id: 'b-1',
            type: ChapitreBlocType.paragraphe,
            texte: ' ',
          ),
          ChapitreBloc(id: 'b-2', type: ChapitreBlocType.titre, texte: 'Intro'),
        ],
      ),
      create: true,
    );
    final saved = result.getOrElse(() => fail('Left'));
    expect(saved.clientUpdatedAt, DateTime.utc(2026, 10, 6));
    expect(saved.blocs.map((b) => b.id), ['b-2']);
  });

  test('une ébauche pas encore descendue ne s\'enregistre pas', () async {
    final result = await repository.saveChapitre(
      const Chapitre(
        id: 'ch-1',
        coursId: 'c-1',
        ordre: 0,
        titre: 'Fractions',
        awaitingDownload: true,
      ),
    );
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
  });
}
