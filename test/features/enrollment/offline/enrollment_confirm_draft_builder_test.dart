import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/enrollment_confirm_draft_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

void main() {
  EnrollmentDetail detail({String studentId = 'stu-canonique'}) =>
      EnrollmentDetail(
        studentDetail: StudentDetail(
          id: studentId,
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          dateOfBirth: '2015-04-02',
          gender: Gender.female,
          birthPlace: 'Kinshasa',
          nationality: 'CD',
          city: 'Kinshasa',
          district: 'Gombe',
          municipality: 'Gombe',
          neighborhood: 'Q1',
          address: 'Av. X',
          schoolLevel: const SchoolLevel(
            id: 'lvl-1',
            name: '1ère',
            code: 'P1',
            displayOrder: 1,
            splitIntoClassrooms: false,
          ),
          schoolLevelGroup: const SchoolLevelGroup(
            id: 'grp-1',
            name: 'Primaire',
            code: 'PRIM',
          ),
        ),
        parentDetails: const [
          ParentSummary(
            id: 'p1',
            firstName: 'Sarah',
            lastName: 'Moke',
            surname: 'M',
            identificationNumber: '',
            phoneNumber: '+243111',
            email: 'sarah@x.cd',
            relationshipType: RelationshipType.mother,
          ),
        ],
        enrollmentDetail: const EnrollmentSchoolDetail(
          id: 'e1',
          status: EnrollmentStatus.inProgress,
          academicYearId: 'ay-2026',
          enrollmentCode: 'ENR-1',
          previousSchoolName: 'EP Aiglons',
          previousAcademicYear: '2024-2025',
          previousSchoolLevelGroup: 'Primaire',
          previousSchoolLevel: '6ème',
          previousRate: 14.5,
          previousRank: 3,
          validatedPreviousYear: true,
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-1',
        ),
      );

  group('type/statut par origine', () {
    test('NEW → NEW_ENROLLMENT/IN_PROGRESS, studentId null', () {
      final draft = EnrollmentConfirmDraftBuilder.fromDetail(
        detail: detail(),
        origin: EnrollmentDetailOrigin.newFirstRegistration,
      );
      expect(draft.enrollmentType, 'NEW_ENROLLMENT');
      expect(draft.status, 'IN_PROGRESS');
      expect(draft.studentId, isNull); // le repo génère l'uuid client
    });

    test('RE → RE_ENROLLMENT/PRE_REGISTERED, studentId canonique conservé', () {
      final draft = EnrollmentConfirmDraftBuilder.fromDetail(
        detail: detail(),
        origin: EnrollmentDetailOrigin.reRegistration,
      );
      expect(draft.enrollmentType, 'RE_ENROLLMENT');
      expect(draft.status, 'PRE_REGISTERED');
      expect(draft.studentId, 'stu-canonique'); // pas de doublon élève
    });

    test('PRE → PRE_ENROLLMENT/PRE_REGISTERED, studentId conservé', () {
      final draft = EnrollmentConfirmDraftBuilder.fromDetail(
        detail: detail(),
        origin: EnrollmentDetailOrigin.preRegistration,
      );
      expect(draft.enrollmentType, 'PRE_ENROLLMENT');
      expect(draft.status, 'PRE_REGISTERED');
      expect(draft.studentId, 'stu-canonique');
    });

    test(
      'reprise firstRegistration → NEW_ENROLLMENT/IN_PROGRESS mais studentId '
      'CONSERVÉ (élève serveur existant, pas de doublon)',
      () {
        final draft = EnrollmentConfirmDraftBuilder.fromDetail(
          detail: detail(),
          origin: EnrollmentDetailOrigin.firstRegistration,
        );
        expect(draft.enrollmentType, 'NEW_ENROLLMENT');
        expect(draft.status, 'IN_PROGRESS');
        expect(draft.studentId, 'stu-canonique');
      },
    );
  });

  test('sourceRef passe en clair (matricule RE / id préinscription PRE)', () {
    final draft = EnrollmentConfirmDraftBuilder.fromDetail(
      detail: detail(),
      origin: EnrollmentDetailOrigin.preRegistration,
      sourceRef: 'pre-server-1',
    );
    expect(draft.sourceRef, 'pre-server-1');
  });

  test('sourceRef absent → null (pas de référence d\'origine)', () {
    final draft = EnrollmentConfirmDraftBuilder.fromDetail(
      detail: detail(),
      origin: EnrollmentDetailOrigin.newFirstRegistration,
    );
    expect(draft.sourceRef, isNull);
  });

  test('projette identité, adresse, niveau visé, antécédents et tuteurs', () {
    final draft = EnrollmentConfirmDraftBuilder.fromDetail(
      detail: detail(),
      origin: EnrollmentDetailOrigin.reRegistration,
    );

    expect(draft.firstName, 'Amina');
    expect(draft.gender, 'FEMALE');
    expect(draft.city, 'Kinshasa');
    expect(draft.schoolLevelId, 'lvl-1');
    expect(draft.schoolLevelGroupId, 'grp-1');
    expect(draft.previousSchoolName, 'EP Aiglons');
    expect(draft.previousRate, 14.5);
    expect(draft.validatedPreviousYear, isTrue);
    expect(draft.parents, hasLength(1));
    expect(draft.parents.single.phoneNumber, '+243111');
    expect(draft.parents.single.relationshipType, 'MOTHER');
  });

  group('fromReenrollmentCandidate (seed RE local)', () {
    const candidate = ReenrollmentCandidate(
      studentId: 'stu-canonique',
      matriculationNumber: 'KIN-2025-0001',
      firstName: 'Amina',
      lastName: 'Moke',
      surname: 'Junior',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      birthPlace: 'Kinshasa',
      guardianName: 'Jean Pierre Moke',
      guardianPhone: '+243900000000',
    );

    test('RE_ENROLLMENT/PRE_REGISTERED, élève canonique conservé', () {
      final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: candidate,
        academicYearId: 'ay-2026',
      );
      expect(draft.enrollmentType, 'RE_ENROLLMENT');
      expect(draft.status, 'PRE_REGISTERED');
      expect(draft.studentId, 'stu-canonique');
      expect(draft.academicYearId, 'ay-2026');
    });

    test('matricule → matriculationNumber ET source_ref', () {
      final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: candidate,
        academicYearId: 'ay-2026',
      );
      expect(draft.matriculationNumber, 'KIN-2025-0001');
      expect(draft.sourceRef, 'KIN-2025-0001');
    });

    test('tuteur dénormalisé → 1 parent (prénom = 1er mot, nom = reste)', () {
      final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: candidate,
        academicYearId: 'ay-2026',
      );
      expect(draft.parents, hasLength(1));
      expect(draft.parents.single.firstName, 'Jean');
      expect(draft.parents.single.lastName, 'Pierre Moke');
      expect(draft.parents.single.phoneNumber, '+243900000000');
      expect(draft.parents.single.relationshipType, 'OTHER');
    });

    test('sans téléphone → aucun tuteur projeté (clé de dédup absente)', () {
      const noPhone = ReenrollmentCandidate(
        studentId: 's1',
        matriculationNumber: 'M1',
        firstName: 'A',
        lastName: 'B',
        gender: 'MALE',
        dateOfBirth: '2015-04-02',
        guardianName: 'Sans Téléphone',
      );
      final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: noPhone,
        academicYearId: 'ay-2026',
      );
      expect(draft.parents, isEmpty);
    });

    test('genre inconnu → MALE par défaut (Gender à 2 valeurs, cf. B1)', () {
      const weird = ReenrollmentCandidate(
        studentId: 's1',
        matriculationNumber: 'M1',
        firstName: 'A',
        lastName: 'B',
        gender: 'X',
        dateOfBirth: '2015-04-02',
      );
      final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: weird,
        academicYearId: 'ay-2026',
      );
      expect(draft.gender, 'MALE');
    });

    test(
      'previousSchoolLevelId propagé (alimente le calcul auto de la classe cible)',
      () {
        const withPreviousLevel = ReenrollmentCandidate(
          studentId: 's1',
          matriculationNumber: 'M1',
          firstName: 'A',
          lastName: 'B',
          gender: 'MALE',
          dateOfBirth: '2015-04-02',
          previousSchoolLevelId: 'lvl-6e',
        );
        final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
          candidate: withPreviousLevel,
          academicYearId: 'ay-2026',
        );
        expect(draft.previousSchoolLevelId, 'lvl-6e');
      },
    );

    test(
      'previousSchoolLevelId absent → null (pas de calcul auto possible)',
      () {
        final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
          candidate: candidate,
          academicYearId: 'ay-2026',
        );
        expect(draft.previousSchoolLevelId, isNull);
      },
    );

    test(
      'établissement/cycle/niveau précédents (libellés résolus localement) '
      'préremplissent le brouillon — pas de saisie manuelle from scratch',
      () {
        const withLabels = ReenrollmentCandidate(
          studentId: 's1',
          matriculationNumber: 'M1',
          firstName: 'A',
          lastName: 'B',
          gender: 'MALE',
          dateOfBirth: '2015-04-02',
          previousSchoolLevelId: 'lvl-6e',
          previousSchoolLevelName: '6e Primaire',
          previousSchoolLevelGroupName: 'Primaire',
          previousSchoolName: 'Ecole Etoile',
        );
        final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
          candidate: withLabels,
          academicYearId: 'ay-2026',
        );
        expect(draft.previousSchoolLevel, '6e Primaire');
        expect(draft.previousSchoolLevelGroup, 'Primaire');
        expect(draft.previousSchoolName, 'Ecole Etoile');
      },
    );

    test(
      'libellés absents (référentiel N-1 purgé) → null, pas de valeur inventée',
      () {
        final draft = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
          candidate: candidate,
          academicYearId: 'ay-2026',
        );
        expect(draft.previousSchoolLevel, isNull);
        expect(draft.previousSchoolLevelGroup, isNull);
        expect(draft.previousSchoolName, isNull);
      },
    );
  });

  group('fromPreEnrollment (seed PRE local)', () {
    const pre = PreEnrollmentCandidate(
      id: 'pre-1',
      firstName: 'Amina',
      lastName: 'Moke',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      desiredSchoolLevelId: 'lvl-9',
      guardianName: 'Sarah',
      guardianPhone: '+243111',
    );

    test('PRE_ENROLLMENT/PRE_REGISTERED, id → source_ref, élève null', () {
      final draft = EnrollmentConfirmDraftBuilder.fromPreEnrollment(
        pre: pre,
        academicYearId: 'ay-2026',
      );
      expect(draft.enrollmentType, 'PRE_ENROLLMENT');
      expect(draft.status, 'PRE_REGISTERED');
      expect(draft.sourceRef, 'pre-1');
      expect(draft.studentId, isNull); // élève créé au seed (uuid client)
      expect(draft.schoolLevelId, 'lvl-9');
      expect(draft.parents.single.firstName, 'Sarah');
    });

    test('date de naissance absente → chaîne vide (complétée au wizard)', () {
      const noDob = PreEnrollmentCandidate(
        id: 'pre-2',
        firstName: 'A',
        lastName: 'B',
      );
      final draft = EnrollmentConfirmDraftBuilder.fromPreEnrollment(
        pre: noDob,
        academicYearId: 'ay-2026',
      );
      expect(draft.dateOfBirth, '');
    });
  });
}
