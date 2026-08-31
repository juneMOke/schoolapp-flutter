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
    Map<String, dynamic> yearBundleJson({
      required String yearId,
      required bool current,
    }) => {
      'academicYear': {'id': yearId, 'name': '2025-2026', 'current': current},
      'schoolLevelGroups': [
        {
          'id': 'grp-1',
          'name': 'Secondaire',
          'code': 'SEC',
          'periodType': 'TRIMESTRE',
          'academicYearId': yearId,
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
          'academicYearId': yearId,
        },
      ],
    };

    Map<String, dynamic> schoolJson() => {
      'id': 'sch-1',
      'name': 'Ecole Etoile',
      'country': 'RDC',
      'city': 'Goma',
      'district': 'Karisimbi',
      'municipality': 'Katindo',
      'address': 'Avenue du Lac',
      'phone': '+243900000000',
      'email': 'contact@etoile.cd',
    };

    test(
      'parse school + current + previous + serverTime (clé wire `current`)',
      () {
        final bundle = ReferentialBundleDto.fromJson({
          'school': schoolJson(),
          'current': yearBundleJson(yearId: 'ay-2', current: true),
          'previous': yearBundleJson(yearId: 'ay-1', current: false),
          'serverTime': '2026-07-08T10:00:00Z',
        });

        expect(bundle.serverTime, '2026-07-08T10:00:00Z');
        expect(bundle.school.id, 'sch-1');
        expect(bundle.school.name, 'Ecole Etoile');
        expect(bundle.school.city, 'Goma');

        expect(bundle.current.academicYear.id, 'ay-2');
        // Clé wire `current` (et non `isCurrent`) → champ Dart `isCurrent`.
        expect(bundle.current.academicYear.isCurrent, isTrue);
        expect(bundle.current.schoolLevelGroups.single.displayOrder, 2);
        expect(bundle.current.schoolLevels.single.splitIntoClassrooms, isTrue);
        // Argent en centimes entiers.
        final tariff = bundle.current.feeTariffs!.single;
        expect(tariff.amountInCents, isA<int>());
        expect(tariff.amountInCents, 1500000);
        expect(tariff.label, isNull);

        expect(bundle.previous, isNotNull);
        expect(bundle.previous!.academicYear.id, 'ay-1');
        expect(bundle.previous!.academicYear.isCurrent, isFalse);
      },
    );

    test('`previous` absent/null → null (première année de l\'école, D3)', () {
      final bundle = ReferentialBundleDto.fromJson({
        'school': schoolJson(),
        'current': yearBundleJson(yearId: 'ay-1', current: true),
        'previous': null,
        'serverTime': 't',
      });
      expect(bundle.previous, isNull);
    });

    // ADR-014 §4 — la portion tarifaire est retirée du bundle pour qui n'a pas
    // `finance.grid.read`. `null` (non communiquée) et `[]` (réellement aucune)
    // ne doivent PAS se confondre : la purge locale se décide dessus.
    test('`feeTariffs` absent → null, jamais liste vide', () {
      final json = yearBundleJson(yearId: 'ay-1', current: true)
        ..remove('feeTariffs');
      final bundle = ReferentialBundleDto.fromJson({
        'school': schoolJson(),
        'current': json,
        'serverTime': 't',
      });
      expect(bundle.current.feeTariffs, isNull);
    });

    test('`feeTariffs` à null → null', () {
      final json = yearBundleJson(yearId: 'ay-1', current: true);
      json['feeTariffs'] = null;
      final bundle = ReferentialBundleDto.fromJson({
        'school': schoolJson(),
        'current': json,
        'serverTime': 't',
      });
      expect(bundle.current.feeTariffs, isNull);
    });

    test('`feeTariffs` à [] → liste vide (l\'école n\'a aucun tarif)', () {
      final json = yearBundleJson(yearId: 'ay-1', current: true);
      json['feeTariffs'] = <dynamic>[];
      final bundle = ReferentialBundleDto.fromJson({
        'school': schoolJson(),
        'current': json,
        'serverTime': 't',
      });
      expect(bundle.current.feeTariffs, isEmpty);
    });

    test(
      'clé `isCurrent` héritée ignorée → isCurrent = false (contrat = `current`)',
      () {
        final bundle = ReferentialBundleDto.fromJson({
          'school': schoolJson(),
          'current': {
            'academicYear': {
              'id': 'ay-1',
              'name': '2025-2026',
              'isCurrent': true,
            },
          },
          'serverTime': 't',
        });
        expect(bundle.current.academicYear.isCurrent, isFalse);
      },
    );

    test(
      'listes absentes dans un slot année → collections vides (défensif)',
      () {
        final bundle = ReferentialBundleDto.fromJson({
          'school': schoolJson(),
          'current': {
            'academicYear': {
              'id': 'ay-1',
              'name': '2025-2026',
              'current': true,
            },
          },
          'serverTime': 't',
        });
        expect(bundle.current.schoolLevelGroups, isEmpty);
        expect(bundle.current.schoolLevels, isEmpty);
        // `feeTariffs` fait exception depuis ADR-014 §4 : la portion peut être
        // RETIRÉE par le serveur, et l'absence doit rester distinguable d'une
        // grille vide — sans quoi la purge locale l'effacerait.
        expect(bundle.current.feeTariffs, isNull);
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
            'previousBalances': [
              {'amountInCents': 250000, 'currency': 'USD'},
              {'amountInCents': 9000000, 'currency': 'CDF'},
            ],
            'medicalNotes': 'Asthme — inhalateur dans le cartable.',
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
      // Une entrée PAR DEVISE. Le scalaire d'avant valait la somme de tous les
      // postes, étiquetée de la devise du premier : un élève devant 2 500,00 $
      // et 90 000 FC s'entendait annoncer « 92 500,00 $ ».
      expect(c.previousBalances, hasLength(2));
      expect(c.previousBalances.first.amountInCents, 250000);
      expect(c.previousBalances.first.currency, 'USD');
      expect(c.previousBalances.last.currency, 'CDF');
      // Pagination statique par studentId (ni watermark ni 304).
      expect(page.nextCursorId, 'stu-N1');
      expect(page.bootstrapComplete, isFalse);
      expect(page.totalCount, 120);
      expect(page.serverTime, '2026-07-08T09:00:00Z');
      // Fiche santé N-1 : une PROPOSITION. Elle ne vaudra pour le nouveau
      // dossier que si le poste la repousse dans son agrégat — sans quoi
      // l'enfant perd ses allergies à chaque changement d'année.
      expect(c.medicalNotes, 'Asthme — inhalateur dans le cartable.');
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

    test('bootstrapComplete/previousBalances absents → défauts sûrs', () {
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
      // Absent = ne doit rien. JAMAIS un `[Money(0, 'USD')]` de repli : personne
      // n'a choisi cette unité.
      expect(page.items.single.previousBalances, isEmpty);
      // Le dossier N-1 n'avait rien de renseigné : rien à proposer.
      expect(page.items.single.medicalNotes, isNull);
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
                'formerStudent': true,
                'medicalNotes': 'Allergie aux arachides.',
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
                  'emergencyContact': true,
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
        // Le payload ci-dessus porte bien un `email` — le serveur l'envoie
        // toujours. Le DTO ne le décode plus (ADR-015 F8) et doit l'IGNORER
        // sans lever : un décodeur qui se braquerait sur une clé de trop
        // figerait la ressource entière au prochain champ ajouté côté back.
        // C'est le parsing tolérant exigé partout ici.
        expect(agg.parents.single.relationshipType, 'FATHER');
        expect(agg.enrollment.formerStudent, isTrue);
        expect(agg.enrollment.medicalNotes, 'Allergie aux arachides.');
        expect(agg.parents.single.emergencyContact, isTrue);
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
      // Le contrat donne `formerStudent` non nul, mais un back antérieur au
      // champ ne doit pas faire tomber le pull entier : repli sur le type,
      // ici NEW_ENROLLMENT.
      expect(agg.enrollment.formerStudent, isFalse);
      expect(agg.enrollment.medicalNotes, isNull);
    });

    test(
      'snapshot d\'une RÉINSCRIPTION sans formerStudent → replié sur le type',
      () {
        final dto = EnrollmentSnapshotPageDto.fromJson({
          'items': [
            {
              'enrollment': {
                'id': 'enr-3',
                'studentId': 'stu-3',
                'academicYearId': 'ay-1',
                'status': 'IN_PROGRESS',
                'enrollmentType': 'RE_ENROLLMENT',
                'enrollmentCode': 'ETL-2026-0003',
                'enrollmentDate': '2026-07-03',
                'firstName': 'A',
                'lastName': 'B',
                'surname': 'C',
                'dateOfBirth': '2016-01-01',
                'gender': 'MALE',
              },
              'student': {
                'id': 'stu-3',
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

        expect(dto.items.single.enrollment.formerStudent, isTrue);
      },
    );

    /// Le drapeau décrit le couple (élève, tuteur) : le serveur le rend nul
    /// dans les vues sans élève de référence. Ici l'agrégat EN A un, mais un
    /// back antérieur au champ n'envoie rien — et `null` doit rester `null`,
    /// jamais devenir `false`, qui est une désignation retirée.
    test('tuteur sans emergencyContact → null, pas false', () {
      final dto = EnrollmentSnapshotPageDto.fromJson({
        'items': [
          {
            'enrollment': {
              'id': 'enr-4',
              'studentId': 'stu-4',
              'academicYearId': 'ay-1',
              'status': 'IN_PROGRESS',
              'enrollmentType': 'NEW_ENROLLMENT',
              'enrollmentCode': 'ETL-2026-0004',
              'enrollmentDate': '2026-07-04',
              'firstName': 'A',
              'lastName': 'B',
              'surname': 'C',
              'dateOfBirth': '2016-01-01',
              'gender': 'MALE',
            },
            'student': {
              'id': 'stu-4',
              'firstName': 'A',
              'lastName': 'B',
              'surname': 'C',
              'gender': 'MALE',
              'dateOfBirth': '2016-01-01',
            },
            'parents': [
              {
                'id': 'par-4',
                'firstName': 'Joseph',
                'lastName': 'Ilunga',
                'phoneNumber': '+243900000004',
                'relationshipType': 'FATHER',
              },
            ],
            'serverUpdatedAt': '2026-07-08T10:00:00Z',
          },
        ],
        'hasMore': false,
        'serverTime': '2026-07-08T10:00:01Z',
      });

      expect(dto.items.single.parents.single.emergencyContact, isNull);
    });
  });
}
