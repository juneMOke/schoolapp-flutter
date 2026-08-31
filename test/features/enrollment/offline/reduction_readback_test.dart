import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reduction_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_aggregate_response.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_snapshot_pull_models.dart';

import '../../offline_full_db.dart';

/// La relecture (RD-F3) : ce que le serveur a gravé redescend, ce qu'il tait ne
/// détruit rien.
///
/// **Le tri-état est ici plus dangereux qu'ailleurs.** Un octroi vit dans une
/// table sans flux propre : personne ne le repousse, personne ne le rejoue. Si
/// un agrégat muet l'effaçait, il serait perdu pour de bon — et il serait muet
/// exactement aujourd'hui, puisque le back ne porte pas encore la section.
void main() {
  late Database db;
  late EnrollmentReductionDao grants;

  EnrollmentAggregateSnapshotDto snapshot({List<String>? codes}) =>
      EnrollmentAggregateSnapshotDto(
        enrollment: EnrollmentSnapshotDto(
          id: 'e1',
          studentId: 's1',
          academicYearId: 'ay-1',
          status: 'CONFIRMED',
          enrollmentType: 'NEW_ENROLLMENT',
          enrollmentCode: 'INS-1',
          enrollmentDate: '2026-08-31',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          dateOfBirth: '2015-04-02',
          gender: 'FEMALE',
          reductionCodes: codes,
        ),
        student: const StudentSnapshotDto(
          id: 's1',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          gender: 'FEMALE',
          dateOfBirth: '2015-04-02',
        ),
        parents: const [],
        serverUpdatedAt: '2026-08-31T10:00:00Z',
      );

  setUp(() async {
    db = await openFullOfflineDb();
    grants = EnrollmentReductionDao(db);
  });
  tearDown(() async => db.close());

  group('EnrollmentSnapshotDto.fromJson', () {
    Map<String, dynamic> json({Object? codes = #absent}) => {
      'id': 'e1',
      'studentId': 's1',
      'academicYearId': 'ay-1',
      'status': 'CONFIRMED',
      'enrollmentType': 'NEW_ENROLLMENT',
      'enrollmentCode': 'INS-1',
      'enrollmentDate': '2026-08-31',
      'firstName': 'Amina',
      'lastName': 'Moke',
      'surname': 'Junior',
      'dateOfBirth': '2015-04-02',
      'gender': 'FEMALE',
      if (codes != #absent) 'reductionCodes': codes,
    };

    test('section absente → null, pas liste vide', () {
      expect(EnrollmentSnapshotDto.fromJson(json()).reductionCodes, isNull);
    });

    test('section vide → [], une information', () {
      final dto = EnrollmentSnapshotDto.fromJson(
        json(codes: <dynamic>[]),
      );
      expect(dto.reductionCodes, isNotNull);
      expect(dto.reductionCodes, isEmpty);
    });

    test('codes parsés, éléments non-chaîne ignorés', () {
      expect(
        EnrollmentSnapshotDto.fromJson(
          json(codes: <dynamic>['STAFF_CHILD', 7]),
        ).reductionCodes,
        ['STAFF_CHILD'],
      );
    });
  });

  group('pull hydratant', () {
    Future<void> apply(EnrollmentAggregateSnapshotDto agg) =>
        EnrollmentReconciliationDao(db).upsertEnrollmentSnapshots(
          [agg],
          syncedAt: 2000,
        );

    test('agrégat MUET n\'efface pas un octroi déclaré localement', () async {
      await grants.replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1000);

      await apply(snapshot());

      // C'est le cas d'AUJOURD'HUI : le serveur ne porte pas la section. Un
      // effacement ici perdrait la déclaration du guichet avant même son push,
      // et sans flux propre elle ne reviendrait jamais.
      expect(await grants.codesFor('e1'), ['STAFF_CHILD']);
    });

    test('agrégat porteur d\'une liste vide efface', () async {
      await grants.replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1000);

      await apply(snapshot(codes: const []));

      expect(await grants.codesFor('e1'), isEmpty);
    });

    test('agrégat porteur remplace, il ne cumule pas', () async {
      await grants.replaceFor('e1', const ['ANCIEN'], nowMs: 1000);

      await apply(snapshot(codes: const ['SIBLING', 'STAFF_CHILD']));

      expect(await grants.codesFor('e1'), ['SIBLING', 'STAFF_CHILD']);
    });
  });

  group('ACK', () {
    Future<void> ack({List<String>? codes}) async {
      await db.insert('enrollments', {
        'id': 'e1',
        'student_id': 's1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'PENDING',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-08-31',
        'sync_status': 'PENDING_SYNC',
        'updated_at': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await EnrollmentAckDao(db).applyEnrollmentAck(
        EnrollmentAggregateResponse(
          enrollment: ResponseEnrollment(id: 'e1', reductionCodes: codes),
          student: const ResponseStudent(id: 's1'),
          parents: const [],
          documents: const [],
        ),
        enrollmentId: 'e1',
        nowMs: 3000,
      );
    }

    test('le serveur fait foi : il retire ce qu\'il n\'a pas gravé', () async {
      await grants.replaceFor('e1', const ['STAFF_CHILD', 'REFUSE'], nowMs: 1);

      await ack(codes: const ['STAFF_CHILD']);

      // Un code qui avait quitté le barème pendant que la tablette était hors
      // ligne : le garder afficherait une réduction que personne n'a accordée,
      // et le pull suivant dirait le contraire.
      expect(await grants.codesFor('e1'), ['STAFF_CHILD']);
    });

    test('accusé MUET → la déclaration locale est conservée', () async {
      await grants.replaceFor('e1', const ['STAFF_CHILD'], nowMs: 1);

      await ack();

      expect(await grants.codesFor('e1'), ['STAFF_CHILD']);
    });
  });
}
