import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_detail_mapper.dart';

void main() {
  const levels = <SchoolLevel>[
    SchoolLevel(
      id: 'level-1',
      name: '6eme',
      code: '6E',
      displayOrder: 1,
      splitIntoClassrooms: true,
    ),
  ];
  const groups = <SchoolLevelGroup>[
    SchoolLevelGroup(id: 'group-1', name: 'Collège', code: 'COL'),
  ];

  LocalEnrollmentDetail buildLocal({
    String? schoolLevelId = 'level-1',
    String? schoolLevelGroupId = 'group-1',
    List<LocalParent> parents = const [],
  }) {
    return LocalEnrollmentDetail(
      enrollment: LocalEnrollment(
        id: 'enr-1',
        studentId: 'stu-1',
        enrollmentType: EnrollmentType.newEnrollment,
        status: OfflineEnrollmentStatus.inProgress,
        academicYearId: 'ay-1',
        schoolLevelId: schoolLevelId,
        schoolLevelGroupId: schoolLevelGroupId,
        enrollmentDate: '2026-07-01',
        previousSchoolName: 'Ancienne école',
        previousAcademicYear: '2024-2025',
        previousSchoolLevelGroup: 'Primaire',
        previousSchoolLevel: 'CM2',
        previousRate: 13.5,
        previousRank: 3,
        validatedPreviousYear: true,
      ),
      student: const LocalStudent(
        id: 'stu-1',
        firstName: 'Awa',
        lastName: 'Traoré',
        surname: 'Junior',
        gender: OfflineGender.female,
        dateOfBirth: '2015-03-02',
        birthPlace: 'Abidjan',
        nationality: 'ivoirienne',
        city: 'Abidjan',
        district: 'Cocody',
        municipality: 'Riviera',
        neighborhood: 'Riviera 2',
        address: 'lot 10',
      ),
      parents: parents,
    );
  }

  group('mapLocalToEnrollmentDetail', () {
    test('projette élève / adresse / antécédents et résout le niveau visé', () {
      final detail = mapLocalToEnrollmentDetail(
        buildLocal(),
        levels: levels,
        groups: groups,
      );

      final student = detail.studentDetail;
      expect(student.id, 'stu-1');
      expect(student.firstName, 'Awa');
      expect(student.surname, 'Junior');
      expect(student.gender, Gender.female);
      expect(student.city, 'Abidjan');
      expect(student.neighborhood, 'Riviera 2');
      // Niveau visé résolu en objet complet via les listes bootstrap.
      expect(student.schoolLevel, levels.first);
      expect(student.schoolLevelGroup, groups.first);

      final enrollment = detail.enrollmentDetail;
      expect(enrollment.id, 'enr-1');
      expect(enrollment.status, EnrollmentStatus.inProgress);
      expect(enrollment.academicYearId, 'ay-1');
      expect(enrollment.previousSchoolName, 'Ancienne école');
      expect(enrollment.previousRate, 13.5);
      expect(enrollment.previousRank, 3);
      expect(enrollment.validatedPreviousYear, isTrue);
      expect(enrollment.schoolLevelId, 'level-1');
      expect(enrollment.schoolLevelGroupId, 'group-1');
    });

    /// **Le mapper est le dernier endroit où un « on ne sait pas » peut se
    /// déguiser en valeur.** Il portait un `?? 0` et un `?? false` : le résumé
    /// imprimait alors « 0% » et « Non » pour un dossier où personne n'avait
    /// rien saisi — exactement la fabrication que le serveur a cessé de
    /// produire, reproduite un cran plus bas.
    ///
    /// Les rendus ont leurs propres tests, mais ils construisent leur détail à
    /// la main : sans ce cas-ci, réintroduire le repli ICI ne ferait rougir
    /// personne.
    test(
      'un dossier sans antécédents projette des `null`, jamais des zéros',
      () {
        final detail = mapLocalToEnrollmentDetail(
          LocalEnrollmentDetail(
            enrollment: const LocalEnrollment(
              id: 'enr-1',
              studentId: 'stu-1',
              enrollmentType: EnrollmentType.newEnrollment,
              status: OfflineEnrollmentStatus.inProgress,
              academicYearId: 'ay-1',
              enrollmentDate: '2026-07-01',
            ),
            student: buildLocal().student,
            parents: const [],
          ),
          levels: const [],
          groups: const [],
        );

        final enrollment = detail.enrollmentDetail;
        expect(enrollment.previousRate, isNull);
        expect(enrollment.previousRank, isNull);
        expect(enrollment.validatedPreviousYear, isNull);
        // « Ancien élève » et la fiche santé traversent aussi, sans défaut
        // inventé : faux et vide sont ici les valeurs réelles du dossier.
        expect(enrollment.formerStudent, isFalse);
        expect(enrollment.medicalNotes, isNull);
      },
    );

    test('les champs de guichet remontent tels quels', () {
      final detail = mapLocalToEnrollmentDetail(
        LocalEnrollmentDetail(
          enrollment: const LocalEnrollment(
            id: 'enr-1',
            studentId: 'stu-1',
            enrollmentType: EnrollmentType.newEnrollment,
            status: OfflineEnrollmentStatus.inProgress,
            academicYearId: 'ay-1',
            enrollmentDate: '2026-07-01',
            formerStudent: true,
            medicalNotes: 'Asthme.',
          ),
          student: buildLocal().student,
          parents: const [],
        ),
        levels: const [],
        groups: const [],
      );

      expect(detail.enrollmentDetail.formerStudent, isTrue);
      expect(detail.enrollmentDetail.medicalNotes, 'Asthme.');
    });

    test('fallback objet minimal quand le niveau est absent des listes', () {
      final detail = mapLocalToEnrollmentDetail(
        buildLocal(schoolLevelId: 'inconnu', schoolLevelGroupId: null),
        levels: levels,
        groups: groups,
      );

      expect(detail.studentDetail.schoolLevel.id, 'inconnu');
      expect(detail.studentDetail.schoolLevel.name, '');
      expect(detail.studentDetail.schoolLevelGroup.id, '');
      expect(detail.studentDetail.schoolLevelGroup.name, '');
    });

    test('mappe les tuteurs (lien de parenté + nullabilité)', () {
      final detail = mapLocalToEnrollmentDetail(
        buildLocal(
          parents: const [
            LocalParent(
              id: 'par-1',
              firstName: 'Koffi',
              lastName: 'Traoré',
              phoneNumber: '+2250102030405',
              email: 'koffi@example.com',
              relationshipType: OfflineRelationshipType.father,
            ),
          ],
        ),
        levels: levels,
        groups: groups,
      );

      expect(detail.parentDetails, hasLength(1));
      final parent = detail.parentDetails.first;
      expect(parent.id, 'par-1');
      expect(parent.relationshipType, RelationshipType.father);
      expect(parent.email, 'koffi@example.com');
      expect(parent.identificationNumber, '');
    });
  });

  group('buildDraftSeedDetail', () {
    test('porte les ids client + année courante, reste vide ailleurs', () {
      final detail = buildDraftSeedDetail(
        enrollmentId: 'enr-9',
        studentId: 'stu-9',
        academicYearId: 'ay-9',
      );

      expect(detail.studentDetail.id, 'stu-9');
      expect(detail.enrollmentDetail.id, 'enr-9');
      expect(detail.enrollmentDetail.academicYearId, 'ay-9');
      expect(detail.enrollmentDetail.status, EnrollmentStatus.inProgress);
      expect(detail.studentDetail.firstName, '');
      expect(detail.studentDetail.schoolLevel.id, '');
      expect(detail.parentDetails, isEmpty);
    });
  });
}
