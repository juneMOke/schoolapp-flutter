import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Parcours par rôle — le seul filet contre une dérive entre l'APK et le
/// serveur (ADR-014).
///
/// Le mapping module → permission vit dans l'APK (`kModuleAccessRegistry`) ;
/// les gardes `@RequiresPermission` vivent dans le back. Rien ne relie
/// mécaniquement les deux. Ce fichier tend le fil : il recopie le **template de
/// rôles serveur** et vérifie que chaque profil garde accès à son métier.
///
/// **Discipline de mise à jour** : toute divergence constatée ici est soit un
/// changement serveur à répercuter, soit une faute de l'APK. Jamais quelque
/// chose à « faire passer » en ajustant l'attendu sans avoir tranché lequel des
/// deux a raison. La copie ci-dessous est une duplication assumée — elle est
/// visible et relisible, là où l'absence de test ne l'était pas.
///
/// Source : `RolePermissionTemplate.DEFAULT_DEFINITIONS` (back-end).
const _secretariat = <String>[
  'enrollment.read',
  'enrollment.write',
  'enrollment.delete',
  'enrollment.stats.read',
  'finance.charge.read',
  'finance.grid.read',
  'classroom.read',
  'student.read',
  'student.write',
  'school.read',
  'schedule.read',
  'academics.result.read',
  'editique.read',
  'editique.write',
  'editique.cancel',
];

const _comptabilite = <String>[
  'enrollment.read',
  'finance.charge.read',
  'finance.charge.write',
  'finance.payment.read',
  'finance.payment.write',
  'finance.grid.read',
  'finance.stats.read',
  'classroom.read',
  'student.read',
  'school.read',
  'editique.read',
  'editique.write',
  'editique.cancel',
];

/// ⚠️ `ACADEMIC_ADMIN` a perdu **tout `/schedule/*` et tout
/// `/academics/cours/*`** — 12 routes fermées côté serveur, qui répondent 403
/// dès la migration passée. Les permissions correspondantes ont été retirées du
/// template en même temps, donc l'APK ferme les sous-modules de lui-même :
/// c'est ce que cette liste doit refléter, et l'absence de `schedule.read` ici
/// est ce qui l'atteste.
const _directionEtudes = <String>[
  'enrollment.read',
  'finance.charge.read',
  'classroom.read',
  'classroom.write',
  'classroom.stats.read',
  'student.read',
  'teacher.read',
  'school.read',
  'academics.grade.read',
  'academics.result.read',
  'academics.referential.read',
  'academics.referential.write',
  'academics.grade.seal',
  'editique.read',
  'editique.write',
];

/// ⚠️ `DISCIPLINE_SUPERVISOR` a perdu les **quatre routes `/schedule/*` en
/// lecture** : plus d'emploi du temps pour la surveillance générale.
const _discipline = <String>[
  'enrollment.read',
  'finance.charge.read',
  'classroom.read',
  'student.read',
  'school.read',
  'attendance.read',
  'attendance.write',
  'attendance.delete',
  'attendance.amend',
  'attendance.stats.read',
  'discipline.read',
  'discipline.write',
  'discipline.delete',
  'editique.read',
];

const _enseignant = <String>[
  'classroom.read',
  'student.read',
  'school.read',
  'schedule.read',
  'attendance.read',
  'attendance.write',
  'discipline.read',
  'academics.course.read',
  'academics.course.write',
  'academics.course.delete',
  'academics.grade.read',
  'academics.grade.write',
  'academics.result.read',
  'academics.referential.read',
];

/// `DIRECTOR` et `SUPER_ADMIN` partagent `FULL_SCHOOL_ACCESS` : tout le
/// catalogue **sauf le périmètre plateforme**, qui n'appartient à aucune école
/// et n'est jamais semé (ADR-014 §2.13). Écrire « toutes les valeurs » ferait
/// dire au test que la direction détient un droit qu'aucun résolveur ne lui
/// donnera jamais.
final _direction = Perm.values
    .where((p) => p != Perm.platformSchoolProvision)
    .map((p) => p.wire)
    .toList(growable: false);

/// Rôles servis par une application aujourd'hui. `PARENT` et `STUDENT` sont
/// volontairement sans droits côté serveur, et n'ont pas d'application — leur
/// cas est traité à part, plus bas.
const _rolesActifs = <String, List<String>>{
  'secrétariat': _secretariat,
  'comptabilité': _comptabilite,
  'direction des études': _directionEtudes,
  'discipline': _discipline,
  'enseignant': _enseignant,
};

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  Set<String> visibleSubMenus(List<String> permissions) => {
    for (final menu in MenuFactory.createMenuItems(
      l10n,
      permissions: permissions,
    ))
      for (final sub in menu.subMenus) sub.id,
  };

  bool can(ModuleAccess access, List<String> permissions) => canAccess(
    requires: access.requires,
    permissions: permissions,
    requiresAll: access.requiresAll,
  );

  // Une valeur inconnue de `Perm` dans un template signifie que le serveur a
  // renommé ou ajouté une permission sans que l'APK suive. Comme le client
  // ignore en silence ce qu'il ne connaît pas, la divergence serait autrement
  // invisible : le module disparaîtrait sans que rien ne le signale.
  group('le catalogue de l\'APK couvre les templates serveur', () {
    final connues = Perm.values.map((p) => p.wire).toSet();

    for (final role in {..._rolesActifs, 'direction': _direction}.entries) {
      test('${role.key} : aucune permission inconnue du client', () {
        expect(
          role.value.where((wire) => !connues.contains(wire)),
          isEmpty,
          reason:
              'Permission absente de `Perm` — soit le serveur a bougé et il '
              'faut suivre, soit la copie du template est fautive.',
        );
      });
    }
  });

  // L'invariant fondateur, vu du client : chaque profil doit pouvoir faire son
  // métier. Un fail-closed trop zélé se voit ici — et pas en production, où il
  // se traduirait par un agent qui ne peut plus travailler.
  group('chaque rôle garde son métier', () {
    test('secrétariat : instruit les dossiers et délivre les pièces', () {
      final ids = visibleSubMenus(_secretariat);
      expect(ids, contains(MenuConstants.premiereInscriptionId));
      expect(ids, contains(MenuConstants.reInscriptionsId));
      expect(ids, contains(MenuConstants.preInscriptionsId));
      expect(ids, contains(MenuConstants.inscriptionsDashboardId));
      expect(ids, contains(MenuConstants.documentsStudentId));

      expect(can(kEnrollmentSubmitAccess, _secretariat), isTrue);
      // Il lit la situation financière sans tenir la caisse (§ template).
      expect(ids, contains(MenuConstants.facturationsId));
      expect(can(kPaymentCollectAccess, _secretariat), isFalse);
    });

    test('comptabilité : encaisse et édite, sans toucher au pédagogique', () {
      final ids = visibleSubMenus(_comptabilite);
      expect(ids, contains(MenuConstants.facturationsId));
      expect(ids, contains(MenuConstants.financesDashboardId));
      expect(ids, contains(MenuConstants.documentsStudentId));
      expect(can(kPaymentCollectAccess, _comptabilite), isTrue);

      expect(ids, isNot(contains(MenuConstants.myCoursesId)));
      expect(ids, isNot(contains(MenuConstants.presencesId)));
      // Elle lit la grille tarifaire mais ne la réécrit pas : source unique de
      // vérité monétaire de l'école.
      expect(_comptabilite, isNot(contains(Perm.financeGridWrite.wire)));
    });

    test('direction des études : compose les classes, sans l\'emploi du temps '
        'ni les cours', () {
      final ids = visibleSubMenus(_directionEtudes);
      expect(ids, contains(MenuConstants.organisationId));
      expect(ids, contains(MenuConstants.classesListId));
      expect(ids, contains(MenuConstants.classesDashboardId));
      expect(ids, contains(MenuConstants.resultatsClasseId));

      // Les 12 routes fermées côté serveur : l'APK ne doit pas offrir une
      // porte qui répondrait 403. Il ne le fait pas de lui-même — c'est le
      // retrait des permissions du template qui ferme, et c'est cela que ces
      // deux lignes surveillent.
      expect(ids, isNot(contains(MenuConstants.timetableId)));
      expect(ids, isNot(contains(MenuConstants.myCoursesId)));

      expect(
        can(const ModuleAccess([Perm.classroomWrite]), _directionEtudes),
        isTrue,
      );
      // Elle scelle les bulletins mais ne saisit pas les notes (§2.7).
      expect(_directionEtudes, contains(Perm.academicsGradeSeal.wire));
      expect(
        can(const ModuleAccess([Perm.academicsGradeWrite]), _directionEtudes),
        isFalse,
      );
    });

    test('discipline : instruit présences et cas, lit le reste', () {
      final ids = visibleSubMenus(_discipline);
      expect(ids, contains(MenuConstants.presencesId));
      expect(ids, contains(MenuConstants.disciplinesListId));
      expect(ids, contains(MenuConstants.disciplinesDashboardId));

      expect(
        can(const ModuleAccess([Perm.attendanceWrite]), _discipline),
        isTrue,
      );
      expect(
        can(const ModuleAccess([Perm.disciplineWrite]), _discipline),
        isTrue,
      );
      // Elle lit les pièces mais n'en émet plus depuis la suppression de
      // `@EditiqueStaffOnly` (effet de bord assumé, ADR §11).
      expect(
        can(const ModuleAccess([Perm.editiqueWrite]), _discipline),
        isFalse,
      );
      expect(ids, contains(MenuConstants.documentsStudentId));
      // Les quatre routes schedule lui sont fermées : le sous-module suit.
      expect(ids, isNot(contains(MenuConstants.timetableId)));
    });

    test('enseignant : fait cours, appelle et note', () {
      final ids = visibleSubMenus(_enseignant);
      expect(ids, contains(MenuConstants.myCoursesId));
      expect(ids, contains(MenuConstants.timetableId));
      expect(ids, contains(MenuConstants.presencesId));
      expect(ids, contains(MenuConstants.resultatsClasseId));

      expect(
        can(const ModuleAccess([Perm.academicsGradeWrite]), _enseignant),
        isTrue,
      );
      expect(
        can(const ModuleAccess([Perm.attendanceWrite]), _enseignant),
        isTrue,
      );
      // Il ne scelle pas : sceller n'est pas saisir (§2.7).
      expect(_enseignant, isNot(contains(Perm.academicsGradeSeal.wire)));
      // Ni finances, ni inscriptions, ni éditique.
      expect(ids, isNot(contains(MenuConstants.facturationsId)));
      expect(ids, isNot(contains(MenuConstants.reInscriptionsId)));
      expect(ids, isNot(contains(MenuConstants.documentsStudentId)));
    });

    // Le module Configuration n'a pas de rôle opérationnel : c'est un geste de
    // direction. Ce test dit les deux moitiés — elle l'a, personne d'autre ne
    // l'a — parce que la première seule laisserait passer un élargissement
    // silencieux du template.
    test('configuration : la direction seule règle l\'école', () {
      expect(
        visibleSubMenus(_direction),
        contains(MenuConstants.configurationSchoolId),
      );
      for (final role in _rolesActifs.entries) {
        expect(
          visibleSubMenus(role.value),
          isNot(contains(MenuConstants.configurationSchoolId)),
          reason: '${role.key} ne provisionne pas l\'école',
        );
      }
    });

    test('direction : rien ne lui est masqué', () {
      final ids = visibleSubMenus(_direction);
      final tous = {
        for (final subMenus in kModuleAccessRegistry.values) ...subMenus.keys,
      };
      expect(ids, equals(tous));
      for (final action in kGuardedWriteActions.entries) {
        expect(can(action.value, _direction), isTrue, reason: action.key);
      }
    });
  });

  // Corollaire appris à l'implémentation serveur (§2.11) : une conjonction peut
  // laisser un rôle à mi-chemin, et le symptôme est un métier bloqué plutôt
  // qu'une faille. Une exigence que PERSONNE ne détient est une fonction que
  // l'école ne peut plus rendre.
  group('aucune exigence n\'est hors de portée de tous', () {
    for (final action in kGuardedWriteActions.entries) {
      test('« ${action.key} » est exécutable par au moins un rôle', () {
        final porteurs = _rolesActifs.entries
            .where((role) => can(action.value, role.value))
            .map((role) => role.key);

        expect(
          porteurs,
          isNotEmpty,
          reason:
              'Aucun rôle du template ne détient cette exigence : la fonction '
              'est inaccessible à toute l\'école, pas protégée.',
        );
      });
    }

    // La direction compte ici, et pas dans le groupe des actions d'écriture
    // ci-dessus. Un module peut être légitimement réservé à elle seule — la
    // mise en service de l'école l'est — sans qu'aucun rôle opérationnel n'y
    // touche jamais. L'exclure des porteurs ferait rougir ce test sur un module
    // correctement réservé, et la seule façon de le rendre vert serait
    // d'affaiblir la garde. Ce qu'il continue d'attraper : un module déclaré
    // sur `platform.school.provision`, la permission plateforme qu'aucune école
    // ne reçoit (§2.13) — le piège exact que la mise en service a frôlé.
    final porteursDeModule = {..._rolesActifs, 'direction': _direction};

    test('chaque sous-module est atteignable par au moins un rôle', () {
      for (final menu in kModuleAccessRegistry.entries) {
        for (final sub in menu.value.entries) {
          expect(
            porteursDeModule.values.any((perms) => can(sub.value, perms)),
            isTrue,
            reason: '${sub.key} n\'est ouvert à aucun rôle',
          );
        }
      }
    });
  });

  // Décision explicite du template, pas un oubli : aucune application ne
  // s'adresse encore aux familles ni aux élèves, donc le fail-closed leur
  // présente une application entièrement masquée — le comportement voulu.
  test('parent / élève : application entièrement masquée', () {
    const aucunDroit = <String>[];

    expect(visibleSubMenus(aucunDroit), isEmpty);
    for (final action in kGuardedWriteActions.values) {
      expect(can(action, aucunDroit), isFalse);
    }
    expect(
      canAccessLocation(Uri.parse('/finances/facturations'), aucunDroit),
      isFalse,
    );
  });
}
