import 'package:school_app_flutter/core/auth/permission_policy.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';

/// Exigence d'accès d'un sous-module (ADR-014 §2.5).
class ModuleAccess {
  /// Permissions référencées par le vocabulaire de l'APK.
  final List<Perm> requires;

  /// Conjonction plutôt que disjonction — réservée aux écrans dont l'action
  /// franchit deux frontières d'autorité en un appel.
  final bool requiresAll;

  const ModuleAccess(this.requires, {this.requiresAll = false});
}

/// **Source unique** du mapping sous-module → permissions requises.
///
/// La grille d'accueil et la barre latérale décrivent la même arborescence
/// depuis deux fabriques distinctes. Si chacune déclarait ses exigences, elles
/// divergeraient au premier ajout — et la divergence porterait sur des droits :
/// une tuile offerte à l'accueil, absente du menu, ou l'inverse. Les deux lisent
/// donc cette table, et un test les compare pour le vérifier.
///
/// C'est du **vocabulaire d'UI** : le serveur ne connaît ni les modules ni les
/// icônes, seulement les permissions (§2.5). Changer ce mapping est un
/// redéploiement client assumé ; donner ou retirer un droit reste, lui, une
/// opération 100 % serveur.
const Map<String, Map<String, ModuleAccess>> kModuleAccessRegistry = {
  MenuConstants.inscriptionsMenuId: {
    MenuConstants.inscriptionsDashboardId: ModuleAccess([
      Perm.enrollmentStatsRead,
    ]),
    // Le wizard de première inscription est une CRÉATION, et son écriture part
    // par l'outbox : `POST /sync/enrollments` exige les deux permissions, parce
    // qu'il scelle une attestation en même temps qu'il inscrit. Exiger ici la
    // seule permission d'inscription laisserait produire hors ligne une écriture
    // que le serveur rejettera définitivement au flush — un 403 y est classé
    // TERMINAL, la saisie serait perdue.
    MenuConstants.premiereInscriptionId: ModuleAccess([
      Perm.enrollmentWrite,
      Perm.editiqueWrite,
    ], requiresAll: true),
    MenuConstants.reInscriptionsId: ModuleAccess([Perm.enrollmentRead]),
    MenuConstants.preInscriptionsId: ModuleAccess([Perm.enrollmentRead]),
  },
  MenuConstants.financesMenuId: {
    MenuConstants.financesDashboardId: ModuleAccess([Perm.financeStatsRead]),
    // Disjonction : la fiche montre les créances ET les paiements, mais le
    // secrétariat n'a que les premières. Lui fermer l'écran entier lui retirerait
    // une lecture qu'il détient.
    MenuConstants.facturationsId: ModuleAccess([
      Perm.financeChargeRead,
      Perm.financePaymentRead,
    ]),
  },
  MenuConstants.classesMenuId: {
    MenuConstants.classesDashboardId: ModuleAccess([Perm.classroomStatsRead]),
    MenuConstants.organisationId: ModuleAccess([Perm.classroomRead]),
    MenuConstants.classesListId: ModuleAccess([Perm.classroomRead]),
  },
  MenuConstants.disciplinesMenuId: {
    MenuConstants.disciplinesDashboardId: ModuleAccess([
      Perm.attendanceStatsRead,
    ]),
    MenuConstants.presencesId: ModuleAccess([Perm.attendanceRead]),
    MenuConstants.disciplinesListId: ModuleAccess([Perm.disciplineRead]),
  },
  MenuConstants.coursesMenuId: {
    MenuConstants.myCoursesId: ModuleAccess([Perm.academicsCourseRead]),
    MenuConstants.timetableId: ModuleAccess([Perm.scheduleRead]),
  },
  MenuConstants.resultatsMenuId: {
    MenuConstants.resultatsClasseId: ModuleAccess([Perm.academicsResultRead]),
  },
  MenuConstants.documentsMenuId: {
    MenuConstants.documentsStudentId: ModuleAccess([Perm.editiqueRead]),
  },
};

/// Vrai si [subMenuId] est accessible avec [permissions].
///
/// Un sous-module **non déclaré** est visible : la table décrit ce qui est
/// gardé, et l'accueil (item feuille, sans sous-menu) n'a rien à garder. C'est
/// le seul endroit du dispositif où l'absence ouvre — ailleurs, tout échoue
/// vers le refus. La contrepartie est le test qui vérifie que chaque
/// sous-menu réellement offert par les fabriques figure bien ici.
bool canAccessSubMenu(String subMenuId, List<String> permissions) {
  final access = _accessOf(subMenuId);
  if (access == null) return true;
  return canAccess(
    requires: access.requires,
    permissions: permissions,
    requiresAll: access.requiresAll,
  );
}

/// Vrai si [menuId] doit apparaître : au moins un de ses sous-modules est
/// accessible. Un menu sans sous-module déclaré (l'accueil) reste visible.
bool canAccessMenu(String menuId, List<String> permissions) {
  final subMenus = kModuleAccessRegistry[menuId];
  if (subMenus == null) return true;
  return subMenus.keys.any((id) => canAccessSubMenu(id, permissions));
}

/// Vrai si [location] est atteignable avec [permissions].
///
/// Toutes les routes de la coquille ont la forme `/{menu}/{sousMenu}[/…]` : le
/// second segment **est** l'identifiant de sous-menu de cette table. La garde
/// de route n'a donc pas sa propre déclaration — elle interroge la même source
/// que la grille d'accueil et la barre latérale, ce qu'exige l'invariant
/// « une seule politique côté client » (ADR-014 §2.9).
///
/// Les chemins à un seul segment (`/home`, `/login`, `/splash`) et ceux dont le
/// second segment n'est pas déclaré (galerie de composants en debug) passent :
/// la table décrit ce qui est gardé, pas ce qui existe.
bool canAccessLocation(Uri location, List<String> permissions) {
  final segments = location.pathSegments;
  if (segments.length < 2) return true;
  return canAccessSubMenu(segments[1], permissions);
}

ModuleAccess? _accessOf(String subMenuId) {
  for (final subMenus in kModuleAccessRegistry.values) {
    final access = subMenus[subMenuId];
    if (access != null) return access;
  }
  return null;
}
