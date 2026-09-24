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

/// Lire la Facturation — la fiche financière d'un élève, ses créances et ses
/// paiements.
///
/// **Disjonction** : la fiche montre les créances ET les paiements, mais le
/// secrétariat n'a que les premières. Lui fermer l'écran entier lui retirerait
/// une lecture qu'il détient.
///
/// Nommée plutôt que recopiée parce qu'elle sort désormais du menu : les états
/// vides de la caisse offrent « Ouvrir la facturation », et cette porte doit se
/// fermer exactement quand celle du menu se ferme. Deux copies de la même
/// exigence divergent au premier ajustement, et la divergence se verrait ici
/// comme un lien qui mène à un refus.
const ModuleAccess kBillingReadAccess = ModuleAccess([
  Perm.financeChargeRead,
  Perm.financePaymentRead,
]);

/// Encaisser un paiement (`POST /sync/payments`).
///
/// **Conjonction** : ce point d'entrée scelle le reçu en encaissant.
const ModuleAccess kPaymentCollectAccess = ModuleAccess([
  Perm.financePaymentWrite,
  Perm.editiqueWrite,
], requiresAll: true);

/// Imposer un taux de change autre que celui de l'école, sur le versement en
/// cours (guichet d'encaissement, bloc « Taux du jour »).
///
/// **Ni conjonction ni repli sur la grille** : corriger un taux ne change qu'un
/// versement, réécrire la grille change ce que toute l'école doit. Les fondre
/// donnerait le second à qui ne doit détenir que le premier.
///
/// ⚠️ **Délibérément ABSENTE de [kGuardedWriteActions] pour l'instant.** Aucun
/// rôle du template serveur ne détient encore `finance.rate.override` ; l'y
/// inscrire ferait rougir — à raison — le test « aucune exigence n'est hors de
/// portée de tous », qui dit qu'une exigence que personne ne détient est une
/// fonction inaccessible plutôt que protégée. **À inscrire le jour où le serveur
/// la sème**, en même temps que la copie du template dans
/// `role_journeys_test.dart` — et pas avant, sous peine d'ajuster un attendu
/// pour faire passer un test.
const ModuleAccess kRateOverrideAccess = ModuleAccess([
  Perm.financeRateOverride,
]);

/// Encaisser une vente boutique (`POST /sync/boutique/sales`), et réclamer son
/// reçu (`POST /boutique/sales/{id}/receipt`).
///
/// **Conjonction**, pour la même raison que l'encaissement de frais : ces deux
/// points d'entrée scellent une pièce numérotée en écrivant, et le serveur les
/// garde littéralement par `@RequiresBothPermissions`. Les deux routes exigent
/// la même paire — c'est pourquoi il n'y en a qu'une ici : réclamer un reçu
/// n'est pas un geste plus léger qu'encaisser, c'est le même scellement.
const ModuleAccess kBoutiqueCollectAccess = ModuleAccess([
  Perm.boutiqueSaleWrite,
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

/// Créer, modifier, dupliquer ou basculer une dépense
/// (`POST /sync/expenses`).
///
/// ⚠️ Masquer n'est pas cosmétique : l'écriture part par l'outbox, où un 403
/// est terminal — offert sans le droit, le geste mourrait plus tard, en
/// silence, sur une saisie que l'économe croit enregistrée.
const ModuleAccess kExpenseWriteAccess = ModuleAccess([Perm.expenseWrite]);

/// Retirer une dépense du registre, ou la restaurer
/// (`POST /sync/expenses/{id}/deletion`). Retirer n'est pas saisir : une école
/// peut confier l'un sans l'autre.
const ModuleAccess kExpenseWithdrawAccess = ModuleAccess([Perm.expenseDelete]);

/// Accorder ou refuser une demande (`POST /sync/expenses/{id}/decision`).
///
/// **Ni conjonction avec [kExpenseWriteAccess], ni repli sur elle** : décider
/// n'est pas saisir. Les fondre rendrait toute demande auto-approuvable par son
/// auteur, et le circuit ne garderait plus rien — c'est exactement ce que le
/// `422 SELF_APPROVAL_FORBIDDEN` du serveur refuse. L'écran masque d'ailleurs
/// Approuver / Refuser sur ses PROPRES demandes (F29), droit ou pas : un geste
/// qu'on sait condamné ne s'offre pas.
const ModuleAccess kExpenseDecideAccess = ModuleAccess([Perm.expenseDecide]);

/// Constater le décaissement d'une demande accordée
/// (`POST /sync/expenses/{id}/payment`).
///
/// Séparée de la décision parce que ce ne sont pas les mêmes mains : la
/// direction accorde, l'économat décaisse. Une école qui confie les deux au
/// même compte le fera en lui donnant les deux droits — c'est son choix, et il
/// reste lisible.
const ModuleAccess kExpensePayAccess = ModuleAccess([Perm.expensePay]);

/// Annuler une décision déjà rendue et ramener la demande en attente
/// (`POST /sync/expenses/{id}/reopen`).
///
/// Le filet de la direction, et le seul geste du circuit qui défait. Le donner
/// à qui dépose reviendrait à lui donner le dernier mot sur son propre refus.
const ModuleAccess kExpenseReopenAccess = ModuleAccess([Perm.expenseReopen]);

/// ⚠️ **Les trois accès du circuit sont délibérément ABSENTS de
/// [kGuardedWriteActions]**, pour la raison exacte de [kRateOverrideAccess] :
/// aucun rôle du template serveur ne détient encore `expense.decide`,
/// `expense.pay` ni `expense.reopen`. Les y inscrire ferait rougir — à raison —
/// le test « aucune exigence n'est hors de portée de tous ». **À inscrire le
/// jour où le back sème ces droits (lots C0→C3)**, en même temps que la copie
/// du template dans `role_journeys_test.dart`, et pas avant.

/// Toutes les actions d'écriture gardées, avec le libellé qui sert aux
/// messages d'échec. Énumérées pour qu'un test puisse vérifier qu'aucune n'est
/// hors de portée de tous les rôles.
const Map<String, ModuleAccess> kGuardedWriteActions = {
  'valider une inscription': kEnrollmentSubmitAccess,
  'encaisser un paiement': kPaymentCollectAccess,
  'encaisser une vente boutique': kBoutiqueCollectAccess,
  'émettre une pièce': ModuleAccess([Perm.editiqueWrite]),
  'enregistrer un appel': kAttendanceRecordAccess,
  'corriger un appel d\'un jour révolu': kAttendanceAmendAccess,
  'instruire un cas disciplinaire': kDisciplineInstructAccess,
  'créer une évaluation / saisir des notes': ModuleAccess([
    Perm.academicsGradeWrite,
  ]),
  'répartir ou affecter des élèves': ModuleAccess([Perm.classroomWrite]),
  'enregistrer une dépense': kExpenseWriteAccess,
  'retirer une dépense': kExpenseWithdrawAccess,
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
    // Même exigence que le lien « Ouvrir la facturation » des états vides de la
    // caisse : une seule définition, pour que les deux portes s'ouvrent et se
    // ferment ensemble.
    MenuConstants.facturationsId: kBillingReadAccess,
  },
  // Le contrôle ne lit que des créances et leur solde : `finance.charge.read`
  // suffit, et c'est exactement ce que détient le secrétariat. Qui le détient
  // franchit aussi la disjonction de la Facturation, donc la fiche financière
  // ouverte depuis cet écran reste atteignable — alors même que le contrôle a
  // quitté le module Finances pour le sien.
  MenuConstants.recouvrementMenuId: {
    // La synthèse ne lit rien de plus que la page nominative — les mêmes
    // créances, comptées au lieu d'être listées. Lui demander un droit de
    // statistiques (`finance.stats.read`) la fermerait au secrétariat, qui est
    // précisément celui qui contrôle.
    MenuConstants.recouvrementDashboardId: ModuleAccess([
      Perm.financeChargeRead,
    ]),
    MenuConstants.recouvrementControlId: ModuleAccess([Perm.financeChargeRead]),
  },
  MenuConstants.boutiqueMenuId: {
    // La caisse s'OUVRE sur la seule lecture des ventes — encaisser est gardé à
    // part, par [kBoutiqueCollectAccess]. Exiger ici la paire d'écriture
    // fermerait l'écran à qui a le droit de consulter la caisse du jour sans
    // tenir le guichet.
    //
    // `boutique.catalog.read` n'y figure PAS, et c'est délibéré : sans elle le
    // serveur caviarde la section `boutiqueArticles` du référentiel à `null`,
    // et l'écran doit dire « catalogue non communiqué » — pas rester
    // inatteignable. Un écran fermé n'apprend rien ; un écran qui nomme le
    // droit manquant, si.
    MenuConstants.boutiqueAchatsId: ModuleAccess([Perm.boutiqueSaleRead]),
    // L'historique lit les MÊMES ventes, en local : même droit. Le distinguer
    // n'inventerait qu'une permission que le serveur ne connaît pas.
    MenuConstants.boutiqueHistoriqueId: ModuleAccess([Perm.boutiqueSaleRead]),
  },
  MenuConstants.expenseMenuId: {
    // Les deux écrans lisent la MÊME liste locale : même droit. Écrire et
    // retirer sont gardés à part, geste par geste ([kExpenseWriteAccess],
    // [kExpenseWithdrawAccess]) — un compte qui consulte doit pouvoir lire le
    // registre sans pouvoir le modifier.
    MenuConstants.expenseDashboardId: ModuleAccess([Perm.expenseRead]),
    MenuConstants.expenseRegisterId: ModuleAccess([Perm.expenseRead]),
    // La file LIT la même liste locale : `expense.read` suffit. Lui demander
    // `expense.decide` la fermerait à celui qui dépose — or il doit y voir sa
    // demande attendre, et pouvoir la relancer ou la retirer.
    MenuConstants.expenseQueueId: ModuleAccess([Perm.expenseRead]),
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
  // Les réglages de l'école, une fois celle-ci en service. Même exigence que
  // l'assistant dont ils rouvrent les écrans : ce sont les mêmes champs, sur la
  // même école — les fermer moins fort ici ouvrirait par la porte de derrière
  // ce que `kStandaloneRouteAccess` garde par la porte d'entrée.
  MenuConstants.configurationMenuId: {
    MenuConstants.configurationSchoolId: ModuleAccess([
      Perm.schoolProvisioningWrite,
    ]),
  },
};

/// Sous-modules **retirés de la navigation par décision produit**, sans rapport
/// avec les droits (2026-09-01 : Réinscription et Pré-inscription, « pour le
/// moment »).
///
/// Volontairement séparé de [kModuleAccessRegistry] : un écran masqué n'est pas
/// un écran interdit. Les mêler dirait à un porteur légitime qu'il n'a pas le
/// droit, là où l'écran est simplement retiré — et le jour où on le rétablit,
/// on ne saurait plus lequel des deux motifs le tenait fermé.
///
/// Conséquences, à connaître avant d'y toucher :
///  - les deux surfaces de navigation (barre latérale et grille d'accueil)
///    lisent cette liste par [isSubMenuOffered], donc ne peuvent pas diverger ;
///  - la **route reste gardée par les seules permissions** : un lien direct
///    vers `/inscriptions/re-inscriptions` ouvre encore l'écran pour qui a
///    `enrollment.read`. C'est délibéré — plus rien n'y mène dans l'UI, et
///    fermer la route ici rendrait un refus de droits mensonger.
///
/// Pour rétablir un écran : retirer son identifiant de cette liste. Rien
/// d'autre n'a été démonté.
const Set<String> kHiddenSubMenus = {
  MenuConstants.reInscriptionsId,
  MenuConstants.preInscriptionsId,
};

/// Vrai si [subMenuId] doit être **offert par la navigation** : ni masqué par
/// décision produit, ni fermé par les droits.
///
/// C'est ce que les deux fabriques appellent — jamais [canAccessSubMenu] en
/// direct, qui ne répond qu'à la question des droits et sert la garde de route.
bool isSubMenuOffered(String subMenuId, List<String>? permissions) =>
    !kHiddenSubMenus.contains(subMenuId) &&
    canAccessSubMenu(subMenuId, permissions);

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
/// **Ne pas déclarer `enrollments` dans [kModuleAccessRegistry]** : le test
/// d'accord menu↔garde exigerait alors qu'il soit visible au menu, où il n'a
/// rien à faire. `configuration`, lui, y figure — et c'est délibéré : ses
/// réglages sont bel et bien offerts au menu (cf. ci-dessus), et les deux
/// déclarations exigent la même permission, si bien que l'accord tient.
const Map<String, ModuleAccess> kStandaloneRouteAccess = {
  'enrollments': ModuleAccess([Perm.enrollmentRead]),
  // L'assistant de mise en service : hors coquille parce qu'il doit être
  // atteignable AVANT que l'école ait une année académique — donc avant que la
  // coquille et son menu aient quoi que ce soit à afficher.
  //
  // Cette entrée garde AUSSI `/configuration/settings`, atteint en lien profond
  // hors coquille : `canAccessLocation` s'arrête au premier segment. Le registre
  // ci-dessus décide, lui, de la visibilité au menu et du rendu en coquille.
  //
  // `school.provisioning.write`, jamais `platform.school.provision` : cf.
  // [Perm.schoolProvisioningWrite].
  'configuration': ModuleAccess([Perm.schoolProvisioningWrite]),
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
