import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';

/// Le rôle dédié `GRADE_CLERK` : la saisie des notes, et rien d'autre du module.
void main() {
  const clerk = ['academics.grade.enter', 'classroom.read', 'school.read'];

  test('le rôle dédié voit la saisie, pas les résultats par classe', () {
    expect(isSubMenuOffered(MenuConstants.resultatsSaisieId, clerk), isTrue);
    expect(isSubMenuOffered(MenuConstants.resultatsClasseId, clerk), isFalse);
  });

  test('un enseignant ne voit pas la saisie', () {
    const teacher = [
      'academics.grade.read',
      'academics.grade.write',
      'academics.result.read',
    ];

    expect(isSubMenuOffered(MenuConstants.resultatsSaisieId, teacher), isFalse);
    expect(isSubMenuOffered(MenuConstants.resultatsClasseId, teacher), isTrue);
  });
}
