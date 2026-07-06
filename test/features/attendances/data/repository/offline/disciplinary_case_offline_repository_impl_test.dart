import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_case_offline_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockIdGenerator extends Mock implements IdGenerator {}

void main() {
  late Database db;
  late DisciplinaryLocalDataSource local;
  late OutboxDao outbox;
  late MockIdGenerator idGen;
  late DisciplinaryCaseOfflineRepositoryImpl repo;

  const yearId = 'year-1';
  var clock = 3000;

  setUp(() async {
    db = await openFullOfflineDb();
    local = DisciplinaryLocalDataSource(db);
    outbox = OutboxDao(db);
    idGen = MockIdGenerator();
    clock = 3000;
    when(() => idGen.newId()).thenReturn('case-1');
    repo = DisciplinaryCaseOfflineRepositoryImpl(
      localDataSource: local,
      idGenerator: idGen,
      now: () => clock,
    );
  });

  tearDown(() async => db.close());

  Future<void> createSample() => repo.createCase(
    studentId: 's1',
    studentFirstName: 'Jean',
    studentLastName: 'Dupont',
    studentGender: StudentGender.male,
    disciplinaryCaseDate: DateTime.utc(2026, 6, 10),
    academicYearId: yearId,
    title: 'Bagarre',
    content: 'Contenu sensible',
    category: DisciplinaryCategory.fighting,
    severity: DisciplinarySeverity.serious,
    sanction: DisciplinarySanction.detention,
  );

  test('createCase : FAIT local OPEN + outbox CREATE (id client)', () async {
    final result = await repo.createCase(
      studentId: 's1',
      studentFirstName: 'Jean',
      studentLastName: 'Dupont',
      studentGender: StudentGender.male,
      disciplinaryCaseDate: DateTime.utc(2026, 6, 10),
      academicYearId: yearId,
      title: 'Bagarre',
      content: 'Contenu sensible',
      category: DisciplinaryCategory.fighting,
      severity: DisciplinarySeverity.serious,
      sanction: DisciplinarySanction.detention,
    );
    expect(result.isRight(), isTrue);

    final row = await local.getCase('case-1');
    expect(row, isNotNull);
    expect(row!.status, 'OPEN');
    expect(row.category, 'FIGHTING');
    expect(row.severity, 'SERIOUS');
    expect(row.content, 'Contenu sensible');
    expect(row.disciplinaryCaseDate, '2026-06-10');
    expect(row.syncStatus, SyncState.pendingSync.dbValue);

    expect(await outbox.pendingCount(), 1);
    final entry = (await outbox.pendingReady(clock + 1)).first;
    expect(entry.aggregateType, 'DISCIPLINARY_CASE');
    expect(entry.aggregateId, 'case-1');
    expect(entry.payload, contains('"id":"case-1"'));
  });

  test(
    'updateCase : traitement LWW + outbox UPDATE avec sanction courante',
    () async {
      await createSample();
      clock = 4000;

      await repo.updateCase(
        caseId: 'case-1',
        status: DisciplinaryStatus.resolved,
        sanction: DisciplinarySanction.parentsSummoned,
      );

      final row = await local.getCase('case-1');
      expect(row!.status, 'RESOLVED');
      expect(row.sanction, 'PARENTS_SUMMONED');
      expect(row.updatedAt, 4000);

      // CREATE + UPDATE = 2 entrées distinctes (create part avant update en FIFO).
      expect(await outbox.pendingCount(), 2);
      final entries = await outbox.pendingReady(clock + 1);
      final updateEntry = entries.firstWhere(
        (e) => e.operation.dbValue == 'UPDATE',
      );
      expect(updateEntry.aggregateId, 'case-1');
      expect(updateEntry.payload, contains('"sanction":"PARENTS_SUMMONED"'));
    },
  );

  test(
    'updateCase renvoie toujours la sanction (garde-fou effacement)',
    () async {
      await createSample();
      // Mise à jour SANS re-préciser la sanction courante → payload sanction=null.
      await repo.updateCase(
        caseId: 'case-1',
        status: DisciplinaryStatus.pending,
      );
      final entries = await outbox.pendingReady(clock + 1);
      final updateEntry = entries.firstWhere(
        (e) => e.operation.dbValue == 'UPDATE',
      );
      // La clé 'sanction' est TOUJOURS présente (même à null) — jamais omise.
      expect(updateEntry.payload, contains('"sanction":null'));
    },
  );

  test('getCasesForStudent renvoie les cas locaux', () async {
    await createSample();
    final result = await repo.getCasesForStudent(
      studentId: 's1',
      academicYearId: yearId,
    );
    final cases = result.getOrElse(() => []);
    expect(cases, hasLength(1));
    expect(cases.first.status, DisciplinaryStatus.open);
    expect(cases.first.sanction, DisciplinarySanction.detention);
  });

  test('createCase idempotent : même id → 1 seule ligne', () async {
    await createSample();
    await createSample();
    final result = await repo.getCasesForStudent(
      studentId: 's1',
      academicYearId: yearId,
    );
    expect(result.getOrElse(() => []), hasLength(1));
  });
}
