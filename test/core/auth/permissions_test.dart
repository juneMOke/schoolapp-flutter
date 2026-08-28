import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';

/// Fige la table `(nom, valeur sur le fil)` du catalogue client (ADR-014 §2.7).
///
/// Une valeur sur le fil ne se renomme pas : une fois une école seedée, la
/// chaîne est une donnée en base **et** une constante compilée dans l'APK. Ce
/// test est là pour qu'un glissement — une faute de frappe, un renommage
/// automatique de l'IDE — ne puisse pas passer en silence sur un contrôle
/// d'accès.
void main() {
  // Recopié depuis `PermissionType.Wire` du back-end. Toute divergence est
  // soit un ajout serveur à répercuter, soit une faute à corriger — jamais
  // quelque chose à « faire passer » en ajustant l'attendu sans vérifier.
  const expected = <Perm, String>{
    Perm.enrollmentRead: 'enrollment.read',
    Perm.enrollmentWrite: 'enrollment.write',
    Perm.enrollmentDelete: 'enrollment.delete',
    Perm.enrollmentStatsRead: 'enrollment.stats.read',
    Perm.financeChargeRead: 'finance.charge.read',
    Perm.financeChargeWrite: 'finance.charge.write',
    Perm.financeChargeDelete: 'finance.charge.delete',
    Perm.financePaymentRead: 'finance.payment.read',
    Perm.financePaymentWrite: 'finance.payment.write',
    Perm.financeGridRead: 'finance.grid.read',
    Perm.financeGridWrite: 'finance.grid.write',
    Perm.financeStatsRead: 'finance.stats.read',
    Perm.classroomRead: 'classroom.read',
    Perm.classroomWrite: 'classroom.write',
    Perm.classroomDelete: 'classroom.delete',
    Perm.classroomStatsRead: 'classroom.stats.read',
    Perm.attendanceRead: 'attendance.read',
    Perm.attendanceWrite: 'attendance.write',
    Perm.attendanceDelete: 'attendance.delete',
    Perm.attendanceAmend: 'attendance.amend',
    Perm.attendanceStatsRead: 'attendance.stats.read',
    Perm.disciplineRead: 'discipline.read',
    Perm.disciplineWrite: 'discipline.write',
    Perm.disciplineDelete: 'discipline.delete',
    Perm.academicsCourseRead: 'academics.course.read',
    Perm.academicsCourseWrite: 'academics.course.write',
    Perm.academicsCourseDelete: 'academics.course.delete',
    Perm.academicsGradeRead: 'academics.grade.read',
    Perm.academicsGradeWrite: 'academics.grade.write',
    Perm.academicsGradeSeal: 'academics.grade.seal',
    Perm.academicsResultRead: 'academics.result.read',
    Perm.academicsReferentialRead: 'academics.referential.read',
    Perm.academicsReferentialWrite: 'academics.referential.write',
    Perm.editiqueRead: 'editique.read',
    Perm.editiqueWrite: 'editique.write',
    Perm.editiqueCancel: 'editique.cancel',
    Perm.schoolRead: 'school.read',
    Perm.schoolWrite: 'school.write',
    Perm.schoolProvisioningWrite: 'school.provisioning.write',
    Perm.studentRead: 'student.read',
    Perm.studentWrite: 'student.write',
    Perm.teacherRead: 'teacher.read',
    Perm.teacherWrite: 'teacher.write',
    Perm.scheduleRead: 'schedule.read',
    Perm.scheduleWrite: 'schedule.write',
    Perm.authUserRead: 'auth.user.read',
    Perm.authUserWrite: 'auth.user.write',
    Perm.authPermissionRead: 'auth.permission.read',
    Perm.authPermissionWrite: 'auth.permission.write',
    Perm.platformSchoolProvision: 'platform.school.provision',
  };

  test('le catalogue compte 50 permissions (v1.8 du catalogue serveur)', () {
    // 48 → 49 : `attendance.amend` sépare corriger un appel d'un jour révolu de
    // le prendre. Un ajout, pas un renommage — aucune ligne de
    // `school_role_permission` ne référence la valeur neuve, donc rien à
    // migrer ; mais le serveur doit la connaître avant que cette release ne
    // pose la garde, sinon elle ferme une porte que personne ne peut ouvrir.
    //
    // 49 → 50 : `school.provisioning.write`, semée par la migration serveur V93
    // sur `DIRECTOR` et `SUPER_ADMIN`. Ajout également, et le serveur la connaît
    // déjà — c'est le client qui rattrapait son retard.
    expect(Perm.values, hasLength(50));
  });

  // La confusion coûteuse : deux permissions au nom voisin, dont une seule
  // ouvre quoi que ce soit. Si un jour l'une prenait la valeur de l'autre, la
  // garde du module Configuration se brancherait sur une impasse et le module
  // resterait fermé à tout le monde, sans le dire.
  test('provisionner SON école n\'est pas provisionner UNE école', () {
    expect(
      Perm.schoolProvisioningWrite.wire,
      isNot(Perm.platformSchoolProvision.wire),
    );
    expect(Perm.schoolProvisioningWrite.wire, 'school.provisioning.write');
    expect(Perm.platformSchoolProvision.wire, 'platform.school.provision');
  });

  // Contrepartie du test « périmètre plateforme inatteignable » ci-dessous :
  // celle-ci, elle, DOIT arriver dans un ensemble effectif — c'est tout son
  // objet. Le test tomberait si on la classait par erreur hors du modèle scopé.
  test('provisionner son école est atteignable', () {
    expect(
      canAccess(
        requires: const [Perm.schoolProvisioningWrite],
        permissions: const ['school.provisioning.write'],
      ),
      isTrue,
    );
  });

  // `platform.school.provision` n'appartient à aucune école : jamais semée,
  // refusée à l'édition, ignorée par le résolveur (ADR-014 §2.13). Elle ne peut
  // donc JAMAIS arriver dans un ensemble effectif — la garder déclarée sert le
  // miroir du catalogue, pas l'autorisation.
  test('le périmètre plateforme est déclaré mais inatteignable', () {
    expect(
      canAccess(
        requires: const [Perm.platformSchoolProvision],
        permissions: Perm.values
            .where((p) => p != Perm.platformSchoolProvision)
            .map((p) => p.wire)
            .toList(),
      ),
      isFalse,
    );
  });

  test('chaque permission porte exactement sa valeur sur le fil', () {
    for (final perm in Perm.values) {
      expect(
        perm.wire,
        expected[perm],
        reason:
            'Valeur sur le fil de ${perm.name} — un renommage impose une '
            'migration de données ET une release client.',
      );
    }
  });

  test('aucune permission oubliée dans la table figée', () {
    expect(expected.keys, containsAll(Perm.values));
  });

  test('aucune valeur sur le fil en double', () {
    final wires = Perm.values.map((p) => p.wire).toList();
    expect(wires.toSet(), hasLength(wires.length));
  });

  test('convention de nommage : domaine.action en minuscules pointillées', () {
    for (final perm in Perm.values) {
      expect(
        perm.wire,
        matches(RegExp(r'^[a-z]+(\.[a-z]+)+$')),
        reason: '${perm.name} sort de la convention DOMAINE_ACTION',
      );
    }
  });
}
