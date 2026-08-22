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

/// Exigences des **actions d'écriture** gardées, nommées une fois et lues par
/// les widgets comme par les tests (ADR-014 §2.11).
///
/// Elles sont ici, et non en littéral dans chaque widget, pour deux raisons.
/// D'abord la conjonction d'inscription était écrite à quatre endroits : quatre
/// occasions de diverger sur un contrôle d'accès. Ensuite, une conjonction que
/// **aucun rôle du template ne détient** bloque un métier au lieu de le
/// protéger — le corollaire appris à l'implémentation serveur — et cela ne se
/// vérifie que si la liste des exigences est énumérable.
///
/// Les deux valeurs viennent du chemin de POUSSÉE, pas du POST en ligne : les
/// points d'entrée `/sync` scellent une pièce numérotée en écrivant, donc
/// exigent `editique.write` en plus. Un 403 y est classé TERMINAL — la saisie
/// serait perdue, pas rejouée.

/// Créer, amorcer ou valider un dossier d'inscription (`POST /sync/enrollments`).
///
/// **Conjonction** : ce point d'entrée scelle une attestation en inscrivant,
/// d'où `editique.write` en plus.
const ModuleAccess kEnrollmentSubmitAccess = ModuleAccess([
  Perm.enrollmentWrite,
  Perm.editiqueWrite,
], requiresAll: true);

/// Instruire un cas disciplinaire : créer, faire avancer, classer sans suite,
/// commenter (`POST /sync/disciplinary-cases`).
///
/// Les quatre gestes partagent un agrégat et un point d'entrée : les séparer
/// laisserait la porte ouverte sur trois d'entre eux, ce qui est précisément ce
/// qui était arrivé.
/// **`discipline.write` seul** : `POST /sync/disciplinary-cases` n'exige rien
/// d'autre. Y ajouter `editique.write` par symétrie avec les deux exigences
/// voisines fermerait le module au surveillant général — ce serait bloquer un
/// métier, pas le protéger.
const ModuleAccess kDisciplineInstructAccess = ModuleAccess([
  Perm.disciplineWrite,
]);

/// Encaisser un paiement (`POST /sync/payments`).
///
/// **Conjonction** : ce point d'entrée scelle le reçu en encaissant.
const ModuleAccess kPaymentCollectAccess = ModuleAccess([
  Perm.financePaymentWrite,
  Perm.editiqueWrite,
], requiresAll: true);

/// Enregistrer un appel — le geste de celui qui constate (`POST /sync/attendance`).
const ModuleAccess kAttendanceRecordAccess = ModuleAccess([
  Perm.attendanceWrite,
]);

/// Corriger un appel **déjà enregistré**, pour un jour **révolu**
/// (`POST /sync/attendance`, même point d'entrée).
///
/// **Conjonction** : c'est la même écriture, plus le droit d'arbitrer. Le motif
/// d'absence porte le verdict justifiée / injustifiée, et « on ne sait pas »
/// vaut « pas justifiée » : rouvrir l'appel d'hier pour y poser « maladie »
/// efface une absence injustifiée d'un registre qui sert à convoquer une
/// famille. Prendre l'appel en retard, ou rectifier celui du jour, reste le
/// geste de celui qui constate et n'exige que [kAttendanceRecordAccess].
///
/// ⚠️ Masquer n'est pas cosmétique ici. Cette écriture part par l'outbox, où un
/// 403 est classé TERMINAL : sans la garde, l'enseignant corrigerait hors ligne,
/// croirait avoir corrigé, et la saisie mourrait plus tard sans rattrapage.
const ModuleAccess kAttendanceAmendAccess = ModuleAccess([
  Perm.attendanceWrite,
  Perm.attendanceAmend,
], requiresAll: true);

/// Toutes les actions d'écriture gardées, avec le libellé qui sert aux
/// messages d'échec. Énumérées pour qu'un test puisse vérifier qu'aucune n'est
/// hors de portée de tous les rôles.
const Map<String, ModuleAccess> kGuardedWriteActions = {
  'valider une inscription': kEnrollmentSubmitAccess,
  'encaisser un paiement': kPaymentCollectAccess,
  'émettre une pièce': ModuleAccess([Perm.editiqueWrite]),
  'enregistrer un appel': kAttendanceRecordAccess,
  'corriger un appel d\'un jour révolu': kAttendanceAmendAccess,
  'instruire un cas disciplinaire': kDisciplineInstructAccess,
  'créer une évaluation / saisir des notes': ModuleAccess([
    Perm.academicsGradeWrite,
  ]),
  'répartir ou affecter des élèves': ModuleAccess([Perm.classroomWrite]),
};

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
    // Le wizard est une CRÉATION : même exigence que l'action qu'il porte.
    MenuConstants.premiereInscriptionId: kEnrollmentSubmitAccess,
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
    // Le contrôle ne lit que des créances et leur solde : `finance.charge.read`
    // suffit, et c'est exactement ce que détient le secrétariat. Qui le détient
    // franchit aussi la disjonction ci-dessus, donc la fiche financière ouverte
    // depuis cet écran reste atteignable.
    MenuConstants.feeControlId: ModuleAccess([Perm.financeChargeRead]),
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
bool canAccessSubMenu(String subMenuId, List<String>? permissions) {
  final access = _accessOf(subMenuId);
  if (access == null) return true;
  if (permissions == null) return false;
  return canAccess(
    requires: access.requires,
    permissions: permissions,
    requiresAll: access.requiresAll,
  );
}

/// Vrai si [menuId] doit apparaître : au moins un de ses sous-modules est
/// accessible. Un menu sans sous-module déclaré (l'accueil) reste visible.
bool canAccessMenu(String menuId, List<String>? permissions) {
  final subMenus = kModuleAccessRegistry[menuId];
  if (subMenus == null) return true;
  return subMenus.keys.any((id) => canAccessSubMenu(id, permissions));
}

/// Routes de premier niveau, **hors coquille** : leur second segment est un mot
/// littéral (`detail`) et non un identifiant de sous-menu, si bien qu'elles
/// échappaient à la garde ci-dessous.
///
/// Le détail/wizard d'inscription est la seule de la production à ce jour.
/// Plancher `enrollment.read` et non l'exigence d'écriture : la même route sert
/// la consultation d'un dossier finalisé, que la comptabilité détient
/// légitimement. L'écriture reste gardée sur ses propres boutons, par
/// [kEnrollmentSubmitAccess].
///
/// **Ne pas déclarer ces segments dans [kModuleAccessRegistry]** : le test
/// d'accord menu↔garde exigerait alors qu'ils soient visibles au menu, où ils
/// n'ont rien à faire.
const Map<String, ModuleAccess> kStandaloneRouteAccess = {
  'enrollments': ModuleAccess([Perm.enrollmentRead]),
};

/// Vrai si [location] est atteignable avec [permissions].
///
/// Les routes de la coquille ont la forme `/{menu}/{sousMenu}[/…]` : le second
/// segment **est** l'identifiant de sous-menu de cette table. La garde de route
/// n'a donc pas sa propre déclaration — elle interroge la même source que la
/// grille d'accueil et la barre latérale, ce qu'exige l'invariant « une seule
/// politique côté client » (ADR-014 §2.9). Les routes de premier niveau, elles,
/// passent par [kStandaloneRouteAccess].
///
/// Les chemins à un seul segment (`/home`, `/login`, `/splash`) et ceux dont le
/// second segment n'est déclaré nulle part (galerie de composants en debug)
/// passent : les tables décrivent ce qui est gardé, pas ce qui existe.
bool canAccessLocation(Uri location, List<String>? permissions) {
  final segments = location.pathSegments;
  if (segments.isEmpty) return true;

  final standalone = kStandaloneRouteAccess[segments.first];
  if (standalone != null) {
    return canAccess(
      requires: standalone.requires,
      permissions: permissions,
      requiresAll: standalone.requiresAll,
    );
  }

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
