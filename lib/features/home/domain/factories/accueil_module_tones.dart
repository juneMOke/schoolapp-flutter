import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module_tone.dart';

/// Table de mappage **module → couleur** (spec Accueil-Couleurs §02 et §10).
///
/// La spec impose que ce mappage vive dans une table et non dans le widget :
/// un module garde sa teinte d'un écran à l'autre — pavé d'accueil, médaillon
/// de section, teinte de carte dans son tableau de bord — et c'est cette
/// constance qui le rend mémorisable.
///
/// **Ne pas coder d'alternance « une sur deux »** : la grille est en
/// `auto-fill minmax(272, 1fr)`, donc le nombre de colonnes varie avec la
/// largeur. La couleur appartient au module, pas à sa position.
///
/// ## Deux écarts assumés par rapport à la table de la spec
///
/// 1. **Boutique** ne figure pas au §02 ; la spec y liste `documents`, qui n'a
///    aucune UI dans l'application (module socle). La Boutique étant un guichet
///    d'encaissement, elle rejoint la famille terre cuite, celle que le §01
///    assigne à « ce qui touche à l'argent ». `bleuEncre` reste donc **en
///    réserve** pour Documents le jour où il aura un écran.
/// 2. **Le fond terre cuite est `#6E3215`, pas le `#8F421E` du §02.** Aux
///    voiles du §06, `#8F421E` fait tomber le libellé de la pastille
///    « Tableau de bord » à 4,43:1 au repos et 3,70:1 au survol — sous le seuil
///    de 4,5:1 que la spec pose elle-même au §04 et fait respecter au §09. La
///    contradiction est interne à la spec : le §04 n'a mesuré la pastille que
///    sur `#1B4D6B`, jamais sur terre cuite ni en survol. `#6E3215` la lève
///    sans toucher aux encres. Le voile de survol descend en contrepartie de
///    `.24` à `.20` (cf. `AccueilUiTokens.blocPillHoverVeil`), faute de quoi
///    `#1B4D6B` resterait à 4,26:1 — et l'assombrir, lui, le ferait fusionner
///    avec `#164760`, dont il n'est distant que de 1,10 de ratio croisé.
///
/// `accueil_module_tones_test.dart` remesure la table entière à chaque
/// exécution et échoue sous 4,5:1 : aucune de ces deux valeurs ne peut dériver
/// en silence.
class AccueilModuleTones {
  const AccueilModuleTones._();

  /// Teinte des modules de la famille **bleue** : glyphe de médaillon en or.
  static const AccueilModuleTone _bleuProfond = AccueilModuleTone(
    background: AppColors.accueilBlocBleuProfond,
    accent: AppColors.accueilBlocAccentOr,
    family: AccueilModuleFamily.bleu,
  );

  static const AccueilModuleTone _bleuArdoise = AccueilModuleTone(
    background: AppColors.accueilBlocBleuArdoise,
    accent: AppColors.accueilBlocAccentOr,
    family: AccueilModuleFamily.bleu,
  );

  static const AccueilModuleTone _bleuArdoiseB = AccueilModuleTone(
    background: AppColors.accueilBlocBleuArdoiseB,
    accent: AppColors.accueilBlocAccentOr,
    family: AccueilModuleFamily.bleu,
  );

  /// Teinte des modules de la famille **terre cuite** : glyphe en crème, l'or
  /// ne tenant pas le contraste sur ce fond (§04 — 2,4:1).
  static const AccueilModuleTone _terreFoncee = AccueilModuleTone(
    background: AppColors.accueilBlocTerreFoncee,
    accent: AppColors.accueilBlocAccentCreme,
    family: AccueilModuleFamily.terre,
  );

  /// La table, exposée pour que le test de non-régression puisse la parcourir
  /// entière plutôt que de réénumérer les modules de son côté.
  static const Map<String, AccueilModuleTone> table = {
    MenuConstants.inscriptionsMenuId: _bleuProfond,
    MenuConstants.financesMenuId: _terreFoncee,
    MenuConstants.recouvrementMenuId: _bleuArdoise,
    MenuConstants.boutiqueMenuId: _terreFoncee,
    MenuConstants.expenseMenuId: _terreFoncee,
    MenuConstants.classesMenuId: _terreFoncee,
    MenuConstants.coursesMenuId: _bleuArdoise,
    MenuConstants.resultatsMenuId: _terreFoncee,
    MenuConstants.disciplinesMenuId: _bleuProfond,
    MenuConstants.configurationMenuId: _bleuArdoiseB,
  };

  /// Teinte du module [menuId].
  ///
  /// Un module absent de la table est une erreur de programmation, pas un cas
  /// d'exécution : la palette est fermée (§09 « nouvelle couleur par module »),
  /// donc il n'y a rien à inventer. L'assertion le signale en debug ; en
  /// release le pavé retombe sur le bleu profond, visible et lisible, plutôt
  /// que sur un fond transparent qui laisserait le texte crème sur du papier.
  static AccueilModuleTone of(String menuId) {
    final tone = table[menuId];
    assert(
      tone != null,
      'Aucune teinte déclarée pour le module « $menuId ». La palette est '
      'fermée : ajouter une entrée à AccueilModuleTones.table en réutilisant '
      'l\'une des cinq valeurs, jamais une couleur neuve.',
    );
    return tone ?? _bleuProfond;
  }
}
