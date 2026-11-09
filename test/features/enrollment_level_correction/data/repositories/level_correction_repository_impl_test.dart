import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/repositories/level_correction_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refused_locally.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

class _FixedIds implements IdGenerator {
  var _n = 0;
  @override
  String newId() => 'g-${++_n}';
}

void main() {
  late Database db;
  late CurrentUserContext user;
  late LevelCorrectionRepositoryImpl repository;

  const request = LevelCorrectionRequest(
    enrollmentId: kEnrollment,
    studentId: kStudent,
    academicYearId: kYear,
    fromSchoolLevelId: 'lvl-m2',
    toSchoolLevelId: 'lvl-p2',
    toSchoolLevelGroupId: 'grp-primaire',
    toClassroomId: 'cls-p2a',
    reason: '  Erreur de saisie  ',
  );

  setUp(() async {
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set(kAuthor, schoolId: kSchool);
    repository = LevelCorrectionRepositoryImpl(
      reader: LevelCorrectionReadDao(db),
      writer: LevelCorrectionWriteDao(db),
      bus: LevelCorrectionChangeBus(),
      currentUser: user,
      ids: _FixedIds(),
      now: () => DateTime.utc(2026, 11, 6, 10, 15).millisecondsSinceEpoch,
    );
  });
  tearDown(() => db.close());

  test(
    'pose le geste : motif rogné, auteur et instant de la session',
    () async {
      expect(
        await repository.correct(request),
        const Right<Failure, bool>(true),
      );

      final latest = (await repository.latestFor(
        kEnrollment,
      )).getOrElse(() => null);
      expect(latest?.reason, 'Erreur de saisie');
      expect(latest?.correctedAt, '2026-11-06T10:15:00.000Z');
      expect(latest?.status, LevelCorrectionStatus.pending);
      expect(
        await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId('g-1')),
        isNotNull,
      );
    },
  );

  test('une seconde correction en attente rend false', () async {
    await repository.correct(request);
    expect(
      await repository.correct(request),
      const Right<Failure, bool>(false),
    );
  });

  test("un versement en vigueur : refus local, avec le code qu'aurait rendu "
      'le serveur', () async {
    await insertPayment(db, id: 'pay-1');
    final result = await repository.correct(request);
    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<LevelCorrectionRefusedLocally>());
    expect(
      (failure! as LevelCorrectionRefusedLocally).refusal,
      LevelCorrectionRefusal.hasPayments,
    );
  });

  test('garde du guichet : retenue tant que la correction attend', () async {
    await insertEnrollment(db);
    expect(
      await repository.holdsCollection(
        studentId: kStudent,
        academicYearId: kYear,
      ),
      const Right<Failure, bool>(false),
    );
    await repository.correct(request);
    expect(
      await repository.holdsCollection(
        studentId: kStudent,
        academicYearId: kYear,
      ),
      const Right<Failure, bool>(true),
    );
  });

  test('motif blanc : refus de validation, rien n\'est écrit', () async {
    final result = await repository.correct(
      const LevelCorrectionRequest(
        enrollmentId: kEnrollment,
        studentId: kStudent,
        academicYearId: kYear,
        fromSchoolLevelId: 'lvl-m2',
        toSchoolLevelId: 'lvl-p2',
        toSchoolLevelGroupId: 'grp-primaire',
        reason: '   ',
      ),
    );
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    expect(
      (await repository.latestFor(kEnrollment)).getOrElse(() => null),
      isNull,
    );
  });

  test('niveau cible identique : refus de validation', () async {
    final result = await repository.correct(
      const LevelCorrectionRequest(
        enrollmentId: kEnrollment,
        studentId: kStudent,
        academicYearId: kYear,
        fromSchoolLevelId: 'lvl-m2',
        toSchoolLevelId: 'lvl-m2',
        toSchoolLevelGroupId: 'grp-maternelle',
        reason: 'Motif',
      ),
    );
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
  });

  test('sans session : refus d\'authentification', () async {
    user.clear();
    final result = await repository.correct(request);
    expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
  });
}
