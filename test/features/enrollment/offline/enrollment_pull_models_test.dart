import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

void main() {
  group('KeysetPageEnvelope', () {
    test('hasMore → cursorToPersist = nextCursor (progression du cycle)', () {
      final env = KeysetPageEnvelope.fromJson({
        'nextCursor': 'CUR-2',
        'nextWatermark': null,
        'hasMore': true,
        'serverTime': '2026-07-08T10:00:00Z',
      });
      expect(env.hasMore, isTrue);
      expect(env.nextCursor, 'CUR-2');
      expect(env.cursorToPersist, 'CUR-2');
    });

    test('dernière page → cursorToPersist = nextWatermark (Δ appliqué)', () {
      final env = KeysetPageEnvelope.fromJson({
        'nextCursor': null,
        'nextWatermark': 'WM-9',
        'hasMore': false,
        'totalCount': 42,
        'serverTime': '2026-07-08T10:00:01Z',
      });
      expect(env.hasMore, isFalse);
      expect(env.totalCount, 42);
      expect(env.cursorToPersist, 'WM-9');
    });

    test(
      'page vide de fin (ni watermark) → cursorToPersist null (conserver)',
      () {
        final env = KeysetPageEnvelope.fromJson({
          'hasMore': false,
          'serverTime': 't',
        });
        expect(env.hasMore, isFalse);
        expect(env.nextWatermark, isNull);
        expect(env.cursorToPersist, isNull);
      },
    );
  });

  group('ReferentialBundleDto.fromJson', () {
    test(
      'parse années/cycles/niveaux/tarifs + serverTime (clé wire `current`)',
      () {
        final bundle = ReferentialBundleDto.fromJson({
          'academicYears': [
            {'id': 'ay-1', 'name': '2025-2026', 'current': true},
          ],
          'schoolLevelGroups': [
            {
              'id': 'grp-1',
              'name': 'Secondaire',
              'code': 'SEC',
              'periodType': 'TRIMESTRE',
              'academicYearId': 'ay-1',
              'displayOrder': 2,
            },
          ],
          'schoolLevels': [
            {
              'id': 'lvl-1',
              'name': '3ème Scientifique',
              'code': '3SC',
              'levelGroupId': 'grp-1',
              'displayOrder': 5,
              'splitIntoClassrooms': true,
            },
          ],
          'feeTariffs': [
            {
              'id': 'ft-1',
              'feeCode': 'INSCRIPTION',
              'schoolLevelGroupId': 'grp-1',
              'schoolLevelId': 'lvl-1',
              'amountInCents': 1500000,
              'currency': 'USD',
              'academicYearId': 'ay-1',
            },
          ],
          'serverTime': '2026-07-08T10:00:00Z',
        });

        expect(bundle.serverTime, '2026-07-08T10:00:00Z');
        // Clé wire `current` (et non `isCurrent`) → champ Dart `isCurrent`.
        expect(bundle.academicYears.single.isCurrent, isTrue);
        expect(bundle.schoolLevelGroups.single.displayOrder, 2);
        expect(bundle.schoolLevels.single.splitIntoClassrooms, isTrue);
        // Argent en centimes entiers.
        final tariff = bundle.feeTariffs.single;
        expect(tariff.amountInCents, isA<int>());
        expect(tariff.amountInCents, 1500000);
        expect(tariff.label, isNull);
      },
    );

    test(
      'clé `isCurrent` héritée ignorée → isCurrent = false (contrat = `current`)',
      () {
        final bundle = ReferentialBundleDto.fromJson({
          'academicYears': [
            {'id': 'ay-1', 'name': '2025-2026', 'isCurrent': true},
          ],
          'serverTime': 't',
        });
        expect(bundle.academicYears.single.isCurrent, isFalse);
      },
    );
  });

  group('ReenrollmentCohortPageDto.fromJson', () {
    test('studentId canonique + arriérés cents + pagination statique', () {
      final page = ReenrollmentCohortPageDto.fromJson({
        'items': [
          {
            'studentId': 'stu-N1',
            'matriculationNumber': 'ETL-2025-000042',
            'firstName': 'Awa',
            'lastName': 'Kone',
            'surname': 'M',
            'gender': 'FEMALE',
            'dateOfBirth': '2013-05-02',
            'birthPlace': 'Kinshasa',
            'previousSchoolLevelId': 'lvl-6e',
            'previousBalanceInCents': 250000,
            'currency': 'USD',
          },
        ],
        'nextCursorId': 'stu-N1',
        'bootstrapComplete': false,
        'totalCount': 120,
        'serverTime': '2026-07-08T09:00:00Z',
      });

      final c = page.items.single;
      expect(c.studentId, 'stu-N1');
      expect(c.matriculationNumber, 'ETL-2025-000042');
      expect(c.previousBalanceInCents, isA<int>());
      expect(c.previousBalanceInCents, 250000);
      // Pagination statique par studentId (ni watermark ni 304).
      expect(page.nextCursorId, 'stu-N1');
      expect(page.bootstrapComplete, isFalse);
      expect(page.totalCount, 120);
      expect(page.serverTime, '2026-07-08T09:00:00Z');
    });

    test('dernière page → bootstrapComplete=true, nextCursorId null', () {
      final page = ReenrollmentCohortPageDto.fromJson({
        'items': const [],
        'nextCursorId': null,
        'bootstrapComplete': true,
        'serverTime': 't',
      });
      expect(page.bootstrapComplete, isTrue);
      expect(page.nextCursorId, isNull);
    });

    test('bootstrapComplete/previousBalanceInCents absents → défauts sûrs', () {
      final page = ReenrollmentCohortPageDto.fromJson({
        'items': [
          {
            'studentId': 's',
            'matriculationNumber': 'M',
            'firstName': 'A',
            'lastName': 'B',
            'surname': 'C',
            'gender': 'MALE',
            'dateOfBirth': '2014-01-01',
            'birthPlace': 'X',
          },
        ],
        'serverTime': 't',
      });
      expect(page.items.single.previousBalanceInCents, 0);
      // Absence de bootstrapComplete → false (ne JAMAIS marquer complet à tort).
      expect(page.bootstrapComplete, isFalse);
    });
  });

  group('PreEnrollmentsPageDto.fromJson', () {
    test('champs optionnels null-safe + updatedAt + enveloppe keyset', () {
      final dto = PreEnrollmentsPageDto.fromJson({
        'items': [
          {
            'id': 'pre-1',
            'firstName': 'Ndeye',
            'lastName': 'Sarr',
            'surname': 'F',
            'updatedAt': '2026-07-07T12:00:00Z',
          },
        ],
        'nextWatermark': 'WM-PRE',
        'hasMore': false,
        'serverTime': '2026-07-08T00:00:00Z',
      });
      final p = dto.items.single;
      expect(p.id, 'pre-1');
      expect(p.gender, isNull);
      expect(p.desiredSchoolLevelId, isNull);
      expect(p.updatedAt, '2026-07-07T12:00:00Z');
      expect(dto.page.serverTime, '2026-07-08T00:00:00Z');
      expect(dto.page.cursorToPersist, 'WM-PRE');
    });
  });

  group('EnrollmentDeltaPageDto.fromJson', () {
    test('distingue updatedAt (LWW) et serverUpdatedAt + enveloppe keyset', () {
      final dto = EnrollmentDeltaPageDto.fromJson({
        'items': [
          {
            'id': 'enr-1',
            'studentId': 'stu-1',
            'academicYearId': 'ay-1',
            'status': 'ACTIVE',
            'updatedAt': '2026-07-08T10:00:00Z',
            'serverUpdatedAt': '2026-07-08T12:00:00Z',
          },
        ],
        'nextCursor': 'CUR-2',
        'hasMore': true,
        'serverTime': '2026-07-08T12:00:00Z',
      });
      final d = dto.items.single;
      expect(d.updatedAt, '2026-07-08T10:00:00Z');
      expect(d.serverUpdatedAt, '2026-07-08T12:00:00Z');
      expect(d.matriculationNumber, isNull);
      expect(dto.page.serverTime, '2026-07-08T12:00:00Z');
      expect(dto.page.hasMore, isTrue);
      expect(dto.page.cursorToPersist, 'CUR-2');
    });
  });

  group('EnrollmentSnapshotPageDto.fromJson', () {
    test(
      'agrégat complet imbriqué (enrollment/student/parents) + enveloppe',
      () {
        final dto = EnrollmentSnapshotPageDto.fromJson({
          'items': [
            {
              'enrollment': {
                'id': 'enr-1',
                'studentId': 'stu-1',
                'academicYearId': 'ay-1',
                'status': 'IN_PROGRESS',
                'enrollmentType': 'RE_ENROLLMENT',
                'enrollmentCode': 'ETL-2026-0001',
                'enrollmentDate': '2026-07-01',
                'firstName': 'Grace',
                'lastName': 'Ilunga',
                'surname': 'Divine',
                'dateOfBirth': '2015-05-05',
                'gender': 'FEMALE',
                'previousRate': 82.5,
                'validatedPreviousYear': true,
                'updatedAt': '2026-07-08T09:00:00Z',
              },
              'student': {
                'id': 'stu-1',
                'matriculationNumber': 'KIN-2026-0001',
                'firstName': 'Grace',
                'lastName': 'Ilunga',
                'surname': 'Divine',
                'gender': 'FEMALE',
                'dateOfBirth': '2015-05-05',
                'email': 'grace@school.local',
              },
              'parents': [
                {
                  'id': 'par-1',
                  'firstName': 'Joseph',
                  'lastName': 'Ilunga',
                  'phoneNumber': '+243900000001',
                  'relationshipType': 'FATHER',
                },
              ],
              'serverUpdatedAt': '2026-07-08T10:00:00Z',
            },
          ],
          'nextWatermark': 'WM-SNAP',
          'hasMore': false,
          'serverTime': '2026-07-08T10:00:01Z',
        });

        expect(dto.page.serverTime, '2026-07-08T10:00:01Z');
        expect(dto.page.cursorToPersist, 'WM-SNAP');
        final agg = dto.items.single;
        expect(agg.serverUpdatedAt, '2026-07-08T10:00:00Z');
        expect(agg.enrollment.enrollmentCode, 'ETL-2026-0001');
        expect(agg.enrollment.previousRate, 82.5);
        expect(agg.enrollment.validatedPreviousYear, isTrue);
        expect(agg.enrollment.updatedAt, '2026-07-08T09:00:00Z');
        expect(agg.student.matriculationNumber, 'KIN-2026-0001');
        expect(agg.student.email, 'grace@school.local');
        expect(agg.parents.single.relationshipType, 'FATHER');
      },
    );

    test('champs optionnels absents → null / parents absent → [] défensif', () {
      final dto = EnrollmentSnapshotPageDto.fromJson({
        'items': [
          {
            'enrollment': {
              'id': 'enr-2',
              'studentId': 'stu-2',
              'academicYearId': 'ay-1',
              'status': 'IN_PROGRESS',
              'enrollmentType': 'NEW_ENROLLMENT',
              'enrollmentCode': 'ETL-2026-0002',
              'enrollmentDate': '2026-07-02',
              'firstName': 'A',
              'lastName': 'B',
              'surname': 'C',
              'dateOfBirth': '2016-01-01',
              'gender': 'MALE',
            },
            'student': {
              'id': 'stu-2',
              'firstName': 'A',
              'lastName': 'B',
              'surname': 'C',
              'gender': 'MALE',
              'dateOfBirth': '2016-01-01',
            },
            'serverUpdatedAt': '2026-07-08T10:00:00Z',
          },
        ],
        'hasMore': false,
        'serverTime': '2026-07-08T10:00:01Z',
      });
      final agg = dto.items.single;
      expect(agg.enrollment.previousRate, isNull);
      expect(agg.enrollment.updatedAt, isNull);
      expect(agg.enrollment.cancellationReason, isNull);
      expect(agg.student.matriculationNumber, isNull);
      expect(agg.parents, isEmpty); // 'parents' absent → [] (pullList défensif)
    });
  });

  test('listes absentes → collections vides (défensif)', () {
    final bundle = ReferentialBundleDto.fromJson({'serverTime': 't'});
    expect(bundle.academicYears, isEmpty);
    expect(bundle.feeTariffs, isEmpty);
  });
}
