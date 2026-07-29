import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_unassigned_level_enrollments_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';

class MockSearchLocalEnrollmentsUseCase extends Mock
    implements SearchLocalEnrollmentsUseCase {}

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

const tAcademicYearId = 'year-1';
const tSchoolLevelId = 'level-1';

LocalEnrollmentListItem _item({
  required String enrollmentId,
  required String studentId,
  String firstName = 'Awa',
  String lastName = 'Ndiaye',
  OfflineEnrollmentStatus status = OfflineEnrollmentStatus.completed,
  OfflineGender gender = OfflineGender.female,
}) => LocalEnrollmentListItem(
  enrollmentId: enrollmentId,
  studentId: studentId,
  firstName: firstName,
  lastName: lastName,
  surname: 'Fatou',
  dateOfBirth: '2012-05-01',
  gender: gender,
  enrollmentType: EnrollmentType.newEnrollment,
  status: status,
  matriculationNumber: 'MAT-$enrollmentId',
  enrollmentDate: '2026-09-01',
  syncState: SyncState.synced,
);

ClassroomMember _member({required String studentId, String id = 'm1'}) =>
    ClassroomMember(
      id: id,
      studentId: studentId,
      classroomId: 'classroom-1',
      academicYearId: tAcademicYearId,
      studentFirstName: 'X',
      studentLastName: 'Y',
      studentGender: ClassroomMemberGender.male,
    );

void main() {
  late MockSearchLocalEnrollmentsUseCase searchEnrollments;
  late MockClassroomOfflineRepository classroomRepository;
  late GetUnassignedLevelEnrollmentsUseCase usecase;

  setUp(() {
    searchEnrollments = MockSearchLocalEnrollmentsUseCase();
    classroomRepository = MockClassroomOfflineRepository();
    usecase = GetUnassignedLevelEnrollmentsUseCase(
      searchEnrollments: searchEnrollments,
      classroomRepository: classroomRepository,
    );
  });

  void stubEnrolled(List<LocalEnrollmentListItem> items) {
    when(
      () => searchEnrollments.currentYearEnrolled(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => Right(items));
  }

  void stubRosters(Map<String, List<ClassroomMember>> rosters) {
    when(
      () => classroomRepository.getComposedRosters(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => Right(rosters));
  }

  test(
    'soustrait les élèves déjà présents dans les rosters composés (par studentId)',
    () async {
      stubEnrolled([
        _item(enrollmentId: 'e1', studentId: 's1'),
        _item(enrollmentId: 'e2', studentId: 's2'),
      ]);
      stubRosters({
        'classroom-1': [_member(studentId: 's1')],
      });

      final result = await usecase(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      );

      final unassigned = result.getOrElse(() => const []);
      expect(unassigned, hasLength(1));
      expect(unassigned.single.student.id, 's2');
    },
  );

  test('déduplique par studentId (anomalie : deux dossiers actifs pour le même '
      'élève ne doivent jamais gonfler le compte)', () async {
    stubEnrolled([
      _item(enrollmentId: 'e1', studentId: 's1'),
      _item(enrollmentId: 'e1-bis', studentId: 's1'),
      _item(enrollmentId: 'e2', studentId: 's2'),
    ]);
    stubRosters(const {});

    final result = await usecase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    final unassigned = result.getOrElse(() => const []);
    expect(unassigned, hasLength(2));
    expect(unassigned.map((e) => e.student.id).toSet(), {'s1', 's2'});
  });

  test('exclut les dossiers CANCELLED (jamais « à répartir »)', () async {
    stubEnrolled([
      _item(
        enrollmentId: 'e1',
        studentId: 's1',
        status: OfflineEnrollmentStatus.cancelled,
      ),
      _item(enrollmentId: 'e2', studentId: 's2'),
    ]);
    stubRosters(const {});

    final result = await usecase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    final unassigned = result.getOrElse(() => const []);
    expect(unassigned, hasLength(1));
    expect(unassigned.single.student.id, 's2');
  });

  test('mappe correctement genre/nom/statut vers EnrollmentSummary', () async {
    stubEnrolled([
      _item(
        enrollmentId: 'e1',
        studentId: 's1',
        firstName: 'Bob',
        lastName: 'Diop',
        gender: OfflineGender.male,
      ),
    ]);
    stubRosters(const {});

    final result = await usecase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    final summary = result.getOrElse(() => const []).single;
    expect(summary.enrollmentId, 'e1');
    expect(summary.student.firstName, 'Bob');
    expect(summary.student.lastName, 'Diop');
    expect(summary.student.gender.name, 'male');
  });

  test('propage un Left si la recherche inscription échoue', () async {
    when(
      () => searchEnrollments.currentYearEnrolled(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('db')));
    stubRosters(const {});

    final result = await usecase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    expect(result.isLeft(), isTrue);
  });

  test('propage un Left si la lecture des rosters composés échoue', () async {
    stubEnrolled([_item(enrollmentId: 'e1', studentId: 's1')]);
    when(
      () => classroomRepository.getComposedRosters(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('db')));

    final result = await usecase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    expect(result.isLeft(), isTrue);
  });
}
