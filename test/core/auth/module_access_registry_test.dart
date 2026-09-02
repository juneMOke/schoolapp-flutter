import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/domain/factories/accueil_modules_factory.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Jeux de droits repris du template de rôles serveur — ce sont les périmètres
/// réels que la flotte verra.
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
  'academics.grade.read',
  'academics.grade.write',
  'academics.result.read',
  'academics.referential.read',
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

/// La direction : tout, sauf la permission plateforme qu'aucune école ne reçoit
/// (§2.13). Elle est indispensable au sens POSITIF de l'accord menu ↔ garde :
/// sans porteur des droits, un module réservé à la direction ne serait vérifié
/// que par sa moitié « fermé à tous les autres », et une garde de route
/// exigeant une permission différente de celle du menu passerait inaperçue.
final _direction = Perm.values
    .where((p) => p != Perm.platformSchoolProvision)
    .map((p) => p.wire)
    .toList(growable: false);

void main() {
  final AppLocalizations l10n = AppLocalizationsFr();

  Set<String> menuSubMenuIds(List<String>? permissions) => {
    for (final menu in MenuFactory.createMenuItems(
      l10n,
      permissions: permissions,
    ))
      for (final sub in menu.subMenus) sub.id,
  };

  Set<String> accueilSubMenuIds(List<String>? permissions) => {
    for (final module in AccueilModulesFactory.create(
      l10n,
      permissions: permissions,
    ))
      for (final sub in module.subModules) sub.target.subMenuId,
  };

  /// Ce que les DROITS accordent, indépendamment du masquage produit
  /// (`kHiddenSubMenus`). Les assertions de politique passent par ici : un
  /// écran retiré de la navigation n'a rien perdu de ses exigences.
  Set<String> grantedSubMenuIds(List<String>? permissions) => {
    for (final subMenus in kModuleAccessRegistry.values)
      for (final id in subMenus.keys)
        if (canAccessSubMenu(id, permissions)) id,
  };

  group('cohérence du registre', () {
    // Le registre est la source unique : tout sous-menu réellement offert doit
    // y figurer, sinon il échappe au filtrage sans que rien ne le signale — la
    // seule règle du dispositif où l'absence ouvre au lieu de fermer.
    test('chaque sous-menu offert est déclaré dans le registre', () {
      final declared = {
        for (final subMenus in kModuleAccessRegistry.values) ...subMenus.keys,
      };
      // Tous les droits déclarés → les fabriques rendent leur arborescence
      // complète. Un sous-menu qui n'apparaîtrait pas dans `declared` serait
      // passé au travers du filtre en silence.
      final tousDroits = [
        for (final subMenus in kModuleAccessRegistry.values)
          for (final access in subMenus.values)
            for (final perm in access.requires) perm.wire,
      ];

      expect(menuSubMenuIds(tousDroits).difference(declared), isEmpty);
      expect(accueilSubMenuIds(tousDroits).difference(declared), isEmpty);
      // …et rien n'est déclaré pour un écran qui n'existe plus. Les écrans
      // masqués par décision produit sont exemptés : ils existent toujours,
      // gardent leurs exigences, et leur route reste gardée par elles — c'est
      // seulement la navigation qui ne les propose plus.
      expect(
        declared
            .difference(menuSubMenuIds(tousDroits))
            .difference(kHiddenSubMenus),
        isEmpty,
        reason: 'entrée orpheline dans kModuleAccessRegistry',
      );
    });

    test('chaque menu déclaré existe dans le registre par son id', () {
      expect(
        kModuleAccessRegistry.keys,
        contains(MenuConstants.financesMenuId),
      );
      expect(
        kModuleAccessRegistry[MenuConstants.financesMenuId]!.keys,
        contains(MenuConstants.facturationsId),
      );
    });
  });

  // La garantie que tout le lot existe pour porter : la grille d'accueil et la
  // barre latérale décrivent la même arborescence depuis deux fabriques. Si
  // elles filtraient chacune avec leur propre déclaration, elles divergeraient
  // au premier ajout — et la divergence porterait sur des droits.
  group('accueil et barre latérale montrent le même périmètre', () {
    for (final cas in <String, List<String>>{
      'enseignant': _enseignant,
      'comptabilité': _comptabilite,
      'aucun droit': <String>[],
      'permission inconnue seule': <String>['module.futur.read'],
    }.entries) {
      test(cas.key, () {
        // L'accueil ne porte pas le module Documents (menu propre, hors des six
        // cartes) : on compare sur l'intersection des sous-menus qu'il décrit.
        final accueil = accueilSubMenuIds(cas.value);
        final menu = menuSubMenuIds(cas.value);
        expect(accueil.difference(menu), isEmpty);
        expect(
          menu.difference(accueil),
          everyElement(equals(MenuConstants.documentsStudentId)),
        );
      });
    }
  });

  group('filtrage par rôle', () {
    test('enseignant : ni finances, ni inscriptions, ni éditique', () {
      final ids = menuSubMenuIds(_enseignant);

      expect(ids, contains(MenuConstants.presencesId));
      expect(ids, contains(MenuConstants.myCoursesId));
      expect(ids, contains(MenuConstants.timetableId));
      expect(ids, contains(MenuConstants.resultatsClasseId));
      expect(ids, contains(MenuConstants.disciplinesListId));

      expect(ids, isNot(contains(MenuConstants.facturationsId)));
      expect(ids, isNot(contains(MenuConstants.reInscriptionsId)));
      expect(ids, isNot(contains(MenuConstants.documentsStudentId)));
      // Pas de `attendance.stats.read` dans son template : le tableau de bord
      // présence disparaît, mais la feuille d'appel reste.
      expect(ids, isNot(contains(MenuConstants.disciplinesDashboardId)));
    });

    test('comptabilité : facturation et documents, pas les cours', () {
      final ids = menuSubMenuIds(_comptabilite);

      expect(ids, contains(MenuConstants.facturationsId));
      expect(ids, contains(MenuConstants.financesDashboardId));
      expect(ids, contains(MenuConstants.documentsStudentId));

      expect(ids, isNot(contains(MenuConstants.myCoursesId)));
      expect(ids, isNot(contains(MenuConstants.presencesId)));
      // `enrollment.read` sans `enrollment.write` : les listes, pas le wizard.
      // L'assertion porte sur le DROIT, pas sur le menu : les deux listes
      // d'inscription sont masquées par décision produit (`kHiddenSubMenus`),
      // ce qui ne retire rien à ce que la comptabilité a le droit de lire.
      expect(
        grantedSubMenuIds(_comptabilite),
        contains(MenuConstants.reInscriptionsId),
      );
      expect(ids, isNot(contains(MenuConstants.premiereInscriptionId)));
    });

    // Conjonction : créer une inscription scelle une attestation. Sans
    // `editique.write`, l'écriture partirait à l'outbox pour y être rejetée
    // définitivement — mieux vaut ne pas ouvrir la porte.
    test('inscription sans editique.write : le wizard reste fermé', () {
      const sansEditique = ['enrollment.read', 'enrollment.write'];
      final ids = menuSubMenuIds(sansEditique);
      // Le droit de lire les listes est bien là (elles sont masquées ailleurs,
      // cf. `kHiddenSubMenus`) ; c'est le wizard, et lui seul, qui reste fermé.
      expect(
        grantedSubMenuIds(sansEditique),
        contains(MenuConstants.reInscriptionsId),
      );
      expect(ids, isNot(contains(MenuConstants.premiereInscriptionId)));

      final avecEditique = menuSubMenuIds(const [
        'enrollment.read',
        'enrollment.write',
        'editique.write',
      ]);
      expect(avecEditique, contains(MenuConstants.premiereInscriptionId));
    });

    // Disjonction : la fiche de facturation montre créances ET paiements, mais
    // le secrétariat n'a que les premières — lui fermer l'écran entier lui
    // retirerait une lecture qu'il détient.
    test('facturation : une seule des deux lectures suffit', () {
      expect(
        menuSubMenuIds(const ['finance.charge.read']),
        contains(MenuConstants.facturationsId),
      );
      expect(
        menuSubMenuIds(const ['finance.payment.read']),
        contains(MenuConstants.facturationsId),
      );
    });
  });

  group('modules vides', () {
    test('un menu sans aucun sous-menu accessible disparaît', () {
      final menus = MenuFactory.createMenuItems(
        l10n,
        permissions: const ['classroom.read'],
      );
      final ids = menus.map((m) => m.id).toSet();

      expect(ids, contains(MenuConstants.classesMenuId));
      expect(ids, isNot(contains(MenuConstants.financesMenuId)));
      expect(ids, isNot(contains(MenuConstants.coursesMenuId)));
    });

    test('droits inconnus : la grille est vide, l\'accueil demeure', () {
      final menus = MenuFactory.createMenuItems(l10n, permissions: null);

      expect(menus.map((m) => m.id), [MenuConstants.accueilId]);
      expect(AccueilModulesFactory.create(l10n, permissions: null), isEmpty);
    });

    test('l\'accueil reste, même sans aucun droit', () {
      final menus = MenuFactory.createMenuItems(l10n, permissions: const []);

      // Item feuille : la seule porte qui reste quand tout est masqué. Sans
      // elle, l'utilisateur n'aurait plus rien à quoi se raccrocher.
      expect(menus.map((m) => m.id), [MenuConstants.accueilId]);
      expect(
        AccueilModulesFactory.create(l10n, permissions: const []),
        isEmpty,
      );
    });

    test('une carte filtrée annonce le bon nombre de pages', () {
      final modules = AccueilModulesFactory.create(
        l10n,
        permissions: const ['classroom.read'],
      );

      final classes = modules.single;
      // Organisation + Liste, sans le tableau de bord (classroom.stats.read).
      expect(classes.pageCount, 2);
      expect(classes.subModules.any((s) => s.isDashboard), isFalse);
      // L'entrée retombe sur la première page réellement atteignable.
      expect(classes.entry.target.subMenuId, MenuConstants.organisationId);
    });
  });

  // Écrans retirés de la navigation par décision produit (2026-09-01), sans
  // rapport avec les droits. Ce qui suit fixe la frontière entre les deux
  // motifs de fermeture : sans ces tests, rétablir un écran se ferait à
  // l'aveugle, et « masqué » finirait par se confondre avec « interdit ».
  group('écrans masqués par décision produit', () {
    // Tous les droits déclarés : si un masqué apparaît malgré ça, c'est bien le
    // masquage qui a lâché, pas une permission qui manque.
    final tousDroits = [
      for (final subMenus in kModuleAccessRegistry.values)
        for (final access in subMenus.values)
          for (final perm in access.requires) perm.wire,
    ];

    test('ni la barre latérale ni l\'accueil ne les proposent', () {
      for (final id in kHiddenSubMenus) {
        expect(
          menuSubMenuIds(tousDroits),
          isNot(contains(id)),
          reason: '$id ne doit plus figurer dans la barre latérale',
        );
        expect(
          accueilSubMenuIds(tousDroits),
          isNot(contains(id)),
          reason: '$id ne doit plus figurer dans la grille d\'accueil',
        );
      }
    });

    test('les deux surfaces masquent EXACTEMENT les mêmes', () {
      // Elles lisent `isSubMenuOffered`, donc la même liste. Le vérifier tient
      // l'invariant du fichier : une tuile offerte d'un côté et absente de
      // l'autre serait pire que les deux absences.
      final declared = {
        for (final subMenus in kModuleAccessRegistry.values) ...subMenus.keys,
      };
      final manquantsMenu = declared.difference(menuSubMenuIds(tousDroits));
      final manquantsAccueil = declared.difference(
        accueilSubMenuIds(tousDroits),
      );
      expect(manquantsMenu, equals(kHiddenSubMenus));
      // L'accueil ne porte pas Documents (menu propre) : on l'écarte de la
      // comparaison, il n'a jamais été de son périmètre.
      expect(
        manquantsAccueil.difference({MenuConstants.documentsStudentId}),
        equals(kHiddenSubMenus),
      );
    });

    test('leurs DROITS sont intacts — masqué n\'est pas interdit', () {
      for (final id in kHiddenSubMenus) {
        expect(
          canAccessSubMenu(id, tousDroits),
          isTrue,
          reason: '$id est retiré de la navigation, pas de la politique',
        );
        expect(
          canAccessSubMenu(id, const []),
          isFalse,
          reason: '$id garde ses exigences face à un porteur sans droit',
        );
      }
    });

    test('leur route reste gardée par les seules permissions', () {
      // Décision assumée : plus rien n'y mène dans l'UI, mais un lien direct
      // ouvre encore l'écran pour qui en a le droit. Fermer la route ici
      // rendrait le refus mensonger — il parlerait de droits absents là où
      // l'écran est simplement retiré.
      expect(
        canAccessLocation(
          Uri.parse('/inscriptions/${MenuConstants.reInscriptionsId}'),
          tousDroits,
        ),
        isTrue,
      );
      expect(
        canAccessLocation(
          Uri.parse('/inscriptions/${MenuConstants.preInscriptionsId}'),
          const [],
        ),
        isFalse,
      );
    });
  });

  // ADR-014 §2.9 — masquer une tuile ne suffit pas : un lien profond, un retour
  // arrière ou une restauration d'état atteignent la route sans passer par le
  // menu. La garde interroge la MÊME table, sans déclaration parallèle.
  group('garde de route', () {
    bool allows(String location, List<String>? permissions) =>
        canAccessLocation(Uri.parse(location), permissions);

    test('route de module interdite → refusée', () {
      expect(allows('/finances/facturations', _enseignant), isFalse);
      expect(allows('/finances/facturations', _comptabilite), isTrue);
    });

    // C'est le cas que le filtrage du registre ne couvrait pas : la route porte
    // des paramètres, donc elle ne figure dans aucun menu.
    test('route à paramètres : le second segment décide', () {
      const detail = '/finances/facturations/detail/stu-1/ay-1';
      expect(allows(detail, _enseignant), isFalse);
      expect(allows(detail, _comptabilite), isTrue);

      const catalogue = '/documents/documents-eleve/catalogue/stu-1/ay-1';
      expect(allows(catalogue, _enseignant), isFalse);
      expect(allows(catalogue, _comptabilite), isTrue);

      const discipline = '/disciplines/presences/student/stu-1/ay-1';
      expect(allows(discipline, _enseignant), isTrue);
      expect(allows(discipline, _comptabilite), isFalse);
    });

    test('les routes hors coquille passent (auth, splash, accueil)', () {
      for (final location in const ['/home', '/login', '/splash', '/']) {
        expect(allows(location, const []), isTrue, reason: location);
      }
    });

    test('une route non déclarée passe (galerie de composants en debug)', () {
      expect(allows('/dev/components', const []), isTrue);
    });

    // Route de PREMIER niveau : son second segment est le mot `detail`, pas un
    // identifiant de sous-menu. Elle échappait donc entièrement à la garde, et
    // deux routes sœurs se contredisaient — un refresh qui retire
    // `enrollment.read` éjectait de la liste mais laissait sur le dossier.
    test('le détail d\'inscription est gardé par kStandaloneRouteAccess', () {
      const detail = '/enrollments/detail/e-1';
      expect(allows(detail, const []), isFalse);
      expect(allows(detail, _enseignant), isFalse);
      expect(allows(detail, _comptabilite), isTrue);
      // Le wizard de création emprunte la même route.
      expect(allows('/enrollments/detail/new', _enseignant), isFalse);
    });

    // Ancrage anti-dérive : la clé littérale de la table doit rester celle de
    // la route réelle, qui vit dans une constante d'un autre fichier.
    test('la clé déclarée correspond à la route de production', () {
      expect(
        Uri.parse(EnrollmentConstants.enrollmentDetailRoute).pathSegments.first,
        isIn(kStandaloneRouteAccess.keys),
      );
    });

    // L'état de tout le parc au premier démarrage après la montée v24.
    test('droits INCONNUS : les routes ferment comme sans droits', () {
      expect(allows('/finances/facturations', null), isFalse);
      expect(allows('/enrollments/detail/e-1', null), isFalse);
      // Les chemins hors coquille restent atteignables : sans eux,
      // l'utilisateur n'aurait plus d'écran du tout pour se reconnecter.
      expect(allows('/home', null), isTrue);
      expect(allows('/login', null), isTrue);
    });

    test('aucun droit : toute route de module est refusée', () {
      expect(allows('/classes/organisation', const []), isFalse);
      expect(allows('/cours/my-courses', const []), isFalse);
      expect(allows('/resultats/resultats-classe', const []), isFalse);
    });

    // Cohérence avec les deux autres surfaces : ce qui est masqué au menu doit
    // être refusé à la route, et l'inverse.
    test('la garde et le menu s\'accordent, sous-menu par sous-menu', () {
      for (final permissions in <List<String>>[
        _enseignant,
        _comptabilite,
        _direction,
        const <String>[],
      ]) {
        final visibles = menuSubMenuIds(permissions);
        for (final entry in kModuleAccessRegistry.entries) {
          for (final subMenuId in entry.value.keys) {
            // Un écran masqué par décision produit quitte le menu sans que ses
            // droits bougent : la garde continue de l'autoriser. C'est la SEULE
            // divergence tolérée, et seulement dans ce sens-là — la surface
            // n'offre jamais ce que la garde refuse, qui est le sens dangereux.
            if (kHiddenSubMenus.contains(subMenuId)) {
              expect(
                visibles,
                isNot(contains(subMenuId)),
                reason:
                    '$subMenuId est masqué : il ne doit pas revenir au menu',
              );
              continue;
            }
            expect(
              allows('/${entry.key}/$subMenuId', permissions),
              visibles.contains(subMenuId),
              reason: '$subMenuId diverge entre menu et garde de route',
            );
          }
        }
      }
    });
  });
}
