import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_projector.dart';

LocalEnrollmentListItem _item({
  String enrollmentId = 'e1',
  String studentId = 's1',
  String firstName = 'Awa',
  String lastName = 'Ndiaye',
  String? surname,
  String dateOfBirth = '2012-05-01',
  OfflineGender gender = OfflineGender.female,
  OfflineEnrollmentStatus status = OfflineEnrollmentStatus.inProgress,
  EnrollmentType type = EnrollmentType.newEnrollment,
  String? matriculationNumber,
}) => LocalEnrollmentListItem(
  enrollmentId: enrollmentId,
  studentId: studentId,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  dateOfBirth: dateOfBirth,
  gender: gender,
  enrollmentType: type,
  status: status,
  matriculationNumber: matriculationNumber,
  enrollmentDate: '2025-09-01',
  syncState: SyncState.pendingSync,
);

void main() {
  group('EnrollmentLocalListProjector.project', () {
    final items = [
      _item(enrollmentId: 'e1', firstName: 'Awa', lastName: 'Ndiaye'),
      _item(enrollmentId: 'e2', firstName: 'Bob', lastName: 'Diop'),
      _item(
        enrollmentId: 'e3',
        firstName: 'Awa',
        lastName: 'Sarr',
        surname: 'Fatou',
        dateOfBirth: '2010-01-01',
      ),
    ];

    test('sans critère → projette tout, dans l’ordre', () {
      final result = EnrollmentLocalListProjector.project(items);
      expect(result.map((s) => s.enrollmentId), ['e1', 'e2', 'e3']);
    });

    test('filtre prénom « contient » insensible à la casse', () {
      final result = EnrollmentLocalListProjector.project(
        items,
        firstName: 'awa',
      );
      expect(result.map((s) => s.enrollmentId), ['e1', 'e3']);
    });

    test('filtre nom', () {
      final result = EnrollmentLocalListProjector.project(
        items,
        lastName: 'diop',
      );
      expect(result.map((s) => s.enrollmentId), ['e2']);
    });

    test('filtre surnom (null exclu)', () {
      final result = EnrollmentLocalListProjector.project(
        items,
        surname: 'fatou',
      );
      expect(result.map((s) => s.enrollmentId), ['e3']);
    });

    test('filtre date de naissance exacte', () {
      final result = EnrollmentLocalListProjector.project(
        items,
        dateOfBirth: '2010-01-01',
      );
      expect(result.map((s) => s.enrollmentId), ['e3']);
    });

    test('critères combinés (ET)', () {
      final result = EnrollmentLocalListProjector.project(
        items,
        firstName: 'awa',
        lastName: 'sarr',
      );
      expect(result.map((s) => s.enrollmentId), ['e3']);
    });

    test('projette matricule et statut dans le résumé', () {
      final result = EnrollmentLocalListProjector.project([
        _item(
          matriculationNumber: 'MAT-1',
          status: OfflineEnrollmentStatus.preRegistered,
        ),
      ]);
      expect(result.single.enrollmentCode, 'MAT-1');
      expect(result.single.status, 'PRE_REGISTERED');
    });

    test('matricule null → code vide (en cours d’attribution)', () {
      final result = EnrollmentLocalListProjector.project([_item()]);
      expect(result.single.enrollmentCode, '');
    });
  });

  group('EnrollmentLocalListProjector.projectReenrollment', () {
    ReenrollmentCandidate cand({
      required String studentId,
      String firstName = 'Awa',
      String lastName = 'Ndiaye',
      String matriculationNumber = 'MAT-1',
      String dateOfBirth = '2012-05-01',
    }) => ReenrollmentCandidate(
      studentId: studentId,
      matriculationNumber: matriculationNumber,
      firstName: firstName,
      lastName: lastName,
      gender: 'FEMALE',
      dateOfBirth: dateOfBirth,
    );

    test('candidat sans dossier → summary candidat (id vide, code=matricule, '
        'statut PENDING)', () {
      final result = EnrollmentLocalListProjector.projectReenrollment(
        candidates: [cand(studentId: 'stu-A', matriculationNumber: 'MAT-A')],
        localDossiers: const [],
      );
      final s = result.single;
      expect(s.enrollmentId, ''); // pas encore de dossier → tap = seed
      expect(s.enrollmentCode, 'MAT-A');
      expect(s.status, 'PENDING');
      expect(s.syncState, isNull);
      expect(s.student.id, 'stu-A');
    });

    test('dossier local du même studentId → prime le candidat (dédup)', () {
      final result = EnrollmentLocalListProjector.projectReenrollment(
        candidates: [
          cand(studentId: 'stu-A'),
          cand(studentId: 'stu-B'),
        ],
        localDossiers: [
          _item(
            enrollmentId: 'dossierA',
            studentId: 'stu-A',
            type: EnrollmentType.reEnrollment,
          ),
        ],
      );
      // Ordre du vivier préservé ; stu-A rendu via son dossier, stu-B candidat.
      expect(result.map((s) => s.student.id), ['stu-A', 'stu-B']);
      expect(result.first.enrollmentId, 'dossierA'); // dossier prime
      expect(result.last.enrollmentId, ''); // candidat frais
    });

    test(
      'dossier local sans candidat correspondant → ignoré (hors vivier)',
      () {
        final result = EnrollmentLocalListProjector.projectReenrollment(
          candidates: [cand(studentId: 'stu-A')],
          localDossiers: [_item(enrollmentId: 'orphan', studentId: 'stu-Z')],
        );
        expect(result.map((s) => s.student.id), ['stu-A']);
      },
    );

    test('raffinage nom appliqué au vivier superposé', () {
      final result = EnrollmentLocalListProjector.projectReenrollment(
        candidates: [
          cand(studentId: 'stu-A', firstName: 'Awa'),
          cand(studentId: 'stu-B', firstName: 'Bob'),
        ],
        localDossiers: const [],
        firstName: 'Awa',
      );
      expect(result.map((s) => s.student.id), ['stu-A']);
    });
  });

  group('EnrollmentLocalListProjector.paginate', () {
    final all = EnrollmentLocalListProjector.project([
      _item(enrollmentId: 'e1'),
      _item(enrollmentId: 'e2'),
      _item(enrollmentId: 'e3'),
      _item(enrollmentId: 'e4'),
      _item(enrollmentId: 'e5'),
    ]);

    test('première page', () {
      final page = EnrollmentLocalListProjector.paginate(all, page: 0, size: 2);
      expect(page.content.map((s) => s.enrollmentId), ['e1', 'e2']);
      expect(page.page, 0);
      expect(page.totalElements, 5);
      expect(page.totalPages, 3);
    });

    test('dernière page partielle', () {
      final page = EnrollmentLocalListProjector.paginate(all, page: 2, size: 2);
      expect(page.content.map((s) => s.enrollmentId), ['e5']);
      expect(page.page, 2);
    });

    test('page hors borne → ramenée à la dernière', () {
      final page = EnrollmentLocalListProjector.paginate(all, page: 9, size: 2);
      expect(page.page, 2);
      expect(page.content.map((s) => s.enrollmentId), ['e5']);
    });

    test('liste vide → 0 page, 0 élément', () {
      final page = EnrollmentLocalListProjector.paginate(
        const [],
        page: 0,
        size: 2,
      );
      expect(page.content, isEmpty);
      expect(page.totalElements, 0);
      expect(page.totalPages, 0);
      expect(page.page, 0);
    });

    test('size <= 0 est borné à 1', () {
      final page = EnrollmentLocalListProjector.paginate(all, page: 0, size: 0);
      expect(page.size, 1);
      expect(page.totalPages, 5);
      expect(page.content.map((s) => s.enrollmentId), ['e1']);
    });
  });
}
