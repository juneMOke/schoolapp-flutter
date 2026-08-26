import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_labels.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

/// Référentiel de test : deux cycles, un niveau chacun.
final _bundles = <SchoolLevelGroupBundle>[
  const SchoolLevelGroupBundle(
    group: SchoolLevelGroup(id: 'g-prim', name: 'Primaire', code: 'PRIM'),
    levels: [
      SchoolLevel(
        id: 'lvl-5p',
        name: '5e primaire',
        code: '5P',
        displayOrder: 5,
        splitIntoClassrooms: true,
      ),
    ],
  ),
  const SchoolLevelGroupBundle(
    group: SchoolLevelGroup(id: 'g-sec', name: 'Secondaire', code: 'SEC'),
    levels: [
      SchoolLevel(
        id: 'lvl-3s',
        name: '3e secondaire',
        code: '3S',
        displayOrder: 3,
        splitIntoClassrooms: true,
      ),
    ],
  ),
];

EnrollmentSummary _summary({
  String? schoolLevelId,
  String? schoolLevelName,
  String? schoolLevelGroupName,
}) => EnrollmentSummary(
  enrollmentId: 'enr-1',
  enrollmentCode: 'M-001',
  status: 'COMPLETED',
  schoolLevelId: schoolLevelId,
  schoolLevelName: schoolLevelName,
  schoolLevelGroupName: schoolLevelGroupName,
  student: const StudentSummary(
    id: 's-1',
    firstName: 'Joseph',
    lastName: 'Kabongo',
    surname: '',
    dateOfBirth: '2014-03-02',
    gender: Gender.male,
  ),
);

void main() {
  group('resolveEnrollmentLevelLabels', () {
    test('la ligne l\'emporte : une recherche par identité dit quand même la '
        'classe', () {
      // Le cas qui produisait « Facturation · - » : aucun critère de niveau,
      // donc rien à chercher dans le référentiel — mais la ligne, elle, sait.
      final labels = resolveEnrollmentLevelLabels(
        _summary(
          schoolLevelId: 'lvl-5p',
          schoolLevelName: '5e primaire',
          schoolLevelGroupName: 'Primaire',
        ),
        bundles: _bundles,
        searchedLevelId: null,
      );

      expect(labels.levelName, '5e primaire');
      expect(labels.levelGroupName, 'Primaire');
    });

    test('la ligne l\'emporte sur un critère de recherche divergent', () {
      final labels = resolveEnrollmentLevelLabels(
        _summary(
          schoolLevelId: 'lvl-5p',
          schoolLevelName: '5e primaire',
          schoolLevelGroupName: 'Primaire',
        ),
        bundles: _bundles,
        searchedLevelId: 'lvl-3s',
      );

      expect(labels.levelName, '5e primaire');
      expect(labels.levelGroupName, 'Primaire');
    });

    test('référentiel pas encore descendu : la ligne suffit', () {
      // La lecture est offline-first ; les libellés du DAO viennent du même
      // référentiel local, mais le contexte académique peut être vide au
      // premier démarrage.
      final labels = resolveEnrollmentLevelLabels(
        _summary(
          schoolLevelId: 'lvl-5p',
          schoolLevelName: '5e primaire',
          schoolLevelGroupName: 'Primaire',
        ),
        bundles: const [],
      );

      expect(labels.levelName, '5e primaire');
      expect(labels.levelGroupName, 'Primaire');
    });

    test('cycle absent de la ligne : complété par le niveau DE LA LIGNE', () {
      // `enrollments.school_level_group_id` est nullable : le LEFT JOIN rend
      // alors un cycle vide. Le référentiel le retrouve à partir du niveau de
      // la ligne — jamais emprunté à un autre élève.
      final labels = resolveEnrollmentLevelLabels(
        _summary(schoolLevelId: 'lvl-3s', schoolLevelName: '3e secondaire'),
        bundles: _bundles,
        searchedLevelId: 'lvl-5p',
      );

      expect(labels.levelName, '3e secondaire');
      expect(labels.levelGroupName, 'Secondaire');
    });

    test('ligne muette : le critère de recherche reste la source de repli', () {
      // Un résumé venu du RÉSEAU ne porte aucun niveau (le DTO serveur ne
      // l'expose pas) : le comportement d'avant doit être intact.
      final labels = resolveEnrollmentLevelLabels(
        _summary(),
        bundles: _bundles,
        searchedLevelId: 'lvl-5p',
      );

      expect(labels.levelName, '5e primaire');
      expect(labels.levelGroupName, 'Primaire');
    });

    test('ni ligne ni critère : deux libellés vides, pas une exception', () {
      final labels = resolveEnrollmentLevelLabels(
        _summary(),
        bundles: _bundles,
      );

      expect(labels.levelName, isEmpty);
      expect(labels.levelGroupName, isEmpty);
    });

    test(
      'niveau inconnu du référentiel : vides plutôt qu\'un faux libellé',
      () {
        final labels = resolveEnrollmentLevelLabels(
          _summary(schoolLevelId: 'lvl-inconnu'),
          bundles: _bundles,
          searchedLevelId: 'lvl-aussi-inconnu',
        );

        expect(labels.levelName, isEmpty);
        expect(labels.levelGroupName, isEmpty);
      },
    );

    test('libellés blancs de la ligne traités comme absents', () {
      final labels = resolveEnrollmentLevelLabels(
        _summary(
          schoolLevelId: 'lvl-5p',
          schoolLevelName: '   ',
          schoolLevelGroupName: '',
        ),
        bundles: _bundles,
      );

      expect(labels.levelName, '5e primaire');
      expect(labels.levelGroupName, 'Primaire');
    });
  });

  group('lookupLevelLabels', () {
    test('id vide ou nul : rien à chercher', () {
      expect(lookupLevelLabels(_bundles, null).levelName, isEmpty);
      expect(lookupLevelLabels(_bundles, '  ').levelGroupName, isEmpty);
    });

    test('rend le niveau et le cycle qui le porte', () {
      final labels = lookupLevelLabels(_bundles, 'lvl-3s');

      expect(labels.levelName, '3e secondaire');
      expect(labels.levelGroupName, 'Secondaire');
    });
  });
}
