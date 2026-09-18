import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_summary_sorter.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

EnrollmentSummary _summary({
  required String id,
  String lastName = 'Ndiaye',
  String surname = '',
  String firstName = 'Awa',
  String dateOfBirth = '2012-05-01',
}) => EnrollmentSummary(
  enrollmentId: id,
  enrollmentCode: id,
  status: 'IN_PROGRESS',
  student: StudentSummary(
    id: 's-$id',
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    gender: Gender.female,
  ),
);

List<String> _ids(
  List<EnrollmentSummary> items,
  EnrollmentSummarySortField field, {
  bool ascending = true,
}) => EnrollmentSummarySorter.sort(
  items,
  field,
  ascending: ascending,
).map((s) => s.enrollmentId).toList();

void main() {
  group('EnrollmentSummarySorter — identité', () {
    test('cascade Nom → Post-nom → Prénom', () {
      final items = [
        _summary(id: 'c', lastName: 'Kabongo', surname: 'Tshibangu'),
        _summary(id: 'a', lastName: 'Diop'),
        _summary(id: 'b', lastName: 'Kabongo', surname: 'Mwamba'),
      ];

      expect(_ids(items, EnrollmentSummarySortField.identity), ['a', 'b', 'c']);
    });

    test('les accents ne rejettent pas un nom en fin d’alphabet', () {
      final items = [
        _summary(id: 'z', lastName: 'Zacharie'),
        _summary(id: 'e', lastName: 'Émile'),
      ];

      expect(_ids(items, EnrollmentSummarySortField.identity), ['e', 'z']);
    });
  });

  group('EnrollmentSummarySorter — colonne cliquée', () {
    test('le champ trié passe devant, la cascade départage', () {
      final items = [
        _summary(id: 'b', lastName: 'Zoulou', firstName: 'Awa'),
        _summary(id: 'a', lastName: 'Diop', firstName: 'Awa'),
        _summary(id: 'c', lastName: 'Kabongo', firstName: 'Bob'),
      ];

      expect(
        _ids(items, EnrollmentSummarySortField.firstName),
        ['a', 'b', 'c'],
        reason:
            'Awa avant Bob ; entre les deux Awa, le nom départage '
            '(Diop avant Zoulou)',
      );
    });

    test('la date de naissance s’ordonne chronologiquement', () {
      final items = [
        _summary(id: 'vieux', dateOfBirth: '2010-01-01'),
        _summary(id: 'jeune', dateOfBirth: '2014-12-31'),
      ];

      expect(_ids(items, EnrollmentSummarySortField.dateOfBirth), [
        'vieux',
        'jeune',
      ]);
    });
  });

  group('EnrollmentSummarySorter — champs vides', () {
    test('une fiche sans le champ trié ferme la marche', () {
      final items = [
        _summary(id: 'sans', surname: ''),
        _summary(id: 'avec', surname: 'Mwamba'),
      ];

      expect(_ids(items, EnrollmentSummarySortField.surname), ['avec', 'sans']);
    });

    test('elle y reste même en ordre DESCENDANT', () {
      final items = [
        _summary(id: 'sans', surname: ''),
        _summary(id: 'mwamba', surname: 'Mwamba'),
        _summary(id: 'tshibangu', surname: 'Tshibangu'),
      ];

      expect(
        _ids(items, EnrollmentSummarySortField.surname, ascending: false),
        ['tshibangu', 'mwamba', 'sans'],
        reason:
            "inverser le tri n'est pas une raison de promouvoir en tête les "
            'fiches dont on ne sait rien — même convention que les non classés '
            'de la table Résultats',
      );
    });
  });

  group('EnrollmentSummarySorter — sens du tri', () {
    test('descendant inverse bien les fiches renseignées', () {
      final items = [
        _summary(id: 'a', lastName: 'Diop'),
        _summary(id: 'b', lastName: 'Kabongo'),
        _summary(id: 'c', lastName: 'Ndiaye'),
      ];

      expect(
        _ids(items, EnrollmentSummarySortField.identity, ascending: false),
        ['c', 'b', 'a'],
      );
    });

    test('la liste reçue n’est jamais mutée', () {
      final items = [
        _summary(id: 'b', lastName: 'Zoulou'),
        _summary(id: 'a', lastName: 'Diop'),
      ];

      EnrollmentSummarySorter.sort(
        items,
        EnrollmentSummarySortField.identity,
        ascending: true,
      );

      expect(items.map((s) => s.enrollmentId), ['b', 'a']);
    });
  });
}
