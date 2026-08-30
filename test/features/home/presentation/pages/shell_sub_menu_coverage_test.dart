import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/home/domain/factories/menu_factory.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// La coquille rend son contenu par un `switch` sur `selectedSubMenuId`. Un
/// sous-menu offert par la barre latérale mais absent de ce `switch` tombe dans
/// le `default` : l'écran affiche « cette page est en cours de développement »,
/// **sans la moindre erreur**, alors que la route et le module existent.
///
/// C'est exactement ce qui est arrivé à la caisse boutique : route déclarée,
/// entrée de menu déclarée, garde d'accès déclarée, module entier et testé — et
/// un guichet qui tombait sur un chantier. Aucun test ne pouvait le voir : ils
/// montaient tous la page directement, jamais par la coquille.
///
/// ## Pourquoi lire le fichier source
///
/// Le `switch` est privé, et le recopier dans une liste ici ne prouverait rien —
/// c'est précisément la divergence entre deux listes tenues en parallèle qu'on
/// cherche à interdire. On lit donc la SEULE source qui existe.
void main() {
  test('chaque sous-menu offert par la barre a son écran dans la coquille', () {
    final source = File(
      'lib/features/home/presentation/pages/home_page.dart',
    ).readAsStringSync();

    final rendered = RegExp(
      r'case MenuConstants\.(\w+):',
    ).allMatches(source).map((match) => match.group(1)!).toSet();

    // Les identifiants tels que la barre les offre réellement — jamais une
    // liste recopiée, qui dériverait avec le code au lieu de le contredire.
    //
    // ⚠️ TOUS les droits, et non `null` : l'ensemble inconnu ferme chaque
    // sous-menu (fail-closed), l'arborescence se réduit à l'Accueil, et le test
    // passerait sur une liste vide — vert sans rien vérifier. C'est ce qu'il a
    // fait à la première écriture, jusqu'à ce que la mutation le dise.
    final offered = <String>{
      for (final menu in MenuFactory.createMenuItems(
        AppLocalizationsFr(),
        permissions: Perm.values.map((p) => p.wire).toList(),
      ))
        for (final sub in menu.subMenus) sub.id,
    };
    expect(
      offered,
      isNotEmpty,
      reason: 'sans arborescence, la comparaison ci-dessous ne vérifie rien',
    );

    // La comparaison porte sur les VALEURS, pas sur les noms de constantes :
    // le `switch` cite `MenuConstants.boutiqueAchatsId`, la barre offre
    // `'boutique-achats'`.
    final renderedValues = {
      for (final name in rendered) _valueOfConstant(source: name),
    };

    final missing = offered.difference(renderedValues);
    expect(
      missing,
      isEmpty,
      reason:
          'Ces sous-menus sont offerts au menu mais ne sont rendus par aucun '
          'cas de la coquille : ils afficheront « page en cours de '
          'développement ». → $missing',
    );
  });
}

/// Résout la valeur d'une constante de `MenuConstants` par son nom.
///
/// Table explicite plutôt que réflexion : `dart:mirrors` n'existe pas sous
/// Flutter, et une constante ajoutée sans être ajoutée ici fait rougir le test
/// — ce qui est le bon sens de panne, puisqu'un sous-menu neuf doit être
/// examiné.
String _valueOfConstant({required String source}) =>
    _constants[source] ?? source;

const Map<String, String> _constants = {
  'accueilId': 'accueil',
  'inscriptionsDashboardId': 'inscriptions-dashboard',
  'preInscriptionsId': 'pre-inscriptions',
  'reInscriptionsId': 're-inscriptions',
  'premiereInscriptionId': 'premiere-inscription',
  'financesDashboardId': 'finances-dashboard',
  'facturationsId': 'facturations',
  'feeControlId': 'controle-frais',
  'boutiqueAchatsId': 'boutique-achats',
  'boutiqueHistoriqueId': 'boutique-historique',
  'classesDashboardId': 'classes-dashboard',
  'organisationId': 'organisation',
  'classesListId': 'classes-list',
  'disciplinesDashboardId': 'disciplines-dashboard',
  'presencesId': 'presences',
  'disciplinesListId': 'disciplines-list',
  'myCoursesId': 'my-courses',
  'timetableId': 'timetable',
  'resultatsClasseId': 'resultats-classe',
  'documentsStudentId': 'documents-eleve',
  'configurationSchoolId': 'settings',
};
