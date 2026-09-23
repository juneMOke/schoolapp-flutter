import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Grammaire chromatique des écrans de **liste** — recherche puis résultats.
///
/// ## Deux zones, deux couleurs
///
/// Un écran de liste se lit comme une phrase : « je cherche » → « voici ce que
/// j'ai trouvé ». Le **bleu** appartient à la saisie — bandeau de recherche,
/// champs, filtres. La **terre cuite** appartient au retour de la machine —
/// barre de résultats, en-tête de tableau, zébrure. L'œil sait donc, sans
/// lire, s'il regarde ce qu'il a demandé ou ce qu'on lui répond.
///
/// Trois terre cuite, trois intensités, et c'est tout : 10 % (barre), 6 %
/// (zébrure), 80 % assombri (en-tête de table). C'est l'échelle d'intensité
/// qui hiérarchise, jamais une teinte de plus.
///
/// ## Pourquoi ce fichier vit dans `core`
///
/// Les mêmes cinq surfaces se composaient déjà **deux fois**, à l'identique au
/// ton près : dans `EnrollmentListingTones` et dans `FinanceTillTones`. Un
/// composant partagé — `BiModeSearchForm`, qui coiffe quatre écrans — ne peut
/// en outre importer aucune des deux, puisqu'un fichier de `core` ne descend
/// jamais dans `features`. Les écrire une fois ici est ce qui empêche qu'un
/// module dérive le jour où le mélange évolue, exactement comme
/// [DashboardTones] le fait pour les tableaux de bord.
///
/// Les formules ne sont d'ailleurs pas réécrites : elles sont **empruntées** à
/// [DashboardTones]. Un en-tête de liste et un en-tête de tableau de bord sont
/// le même objet, et rien ne justifierait qu'ils divergent.
///
/// ## Ce que ce fichier ne décide pas
///
/// **La couleur d'un statut, et celle d'un avatar.** Elles appartiennent au
/// module qui connaît ses statuts et sa clé d'identité stable.
class ListingTones {
  const ListingTones._();

  // ---- Les deux zones ----

  /// Ce que l'utilisateur demande : bandeau de recherche, champs, filtres.
  static const Color zoneSaisie = AppColors.bleuArdoise;

  /// Ce que la machine répond : barre de résultats, table, zébrure.
  static const Color zoneResultat = AppColors.terreCuite;

  // ---- Les intensités, nommées une fois ----

  /// Corps d'un formulaire de recherche — assez pour appartenir à son en-tête,
  /// pas assez pour teinter les champs, qui restent d'un blanc franc.
  static const int formulairePercent = 7;
  static const int formulaireBordPercent = 21;

  /// Barre de résultats.
  static const int barrePercent = 10;

  /// Bord d'une surface de résultat — barre et cadre de table le partagent, et
  /// c'est voulu : les deux encadrent la **même** réponse.
  static const int bordPercent = 26;

  // ---- Les formules, empruntées à la grammaire des tableaux de bord ----

  /// Surface claire : [tone] dilué à [percent] % dans le blanc.
  static Color teinte(Color tone, int percent) =>
      DashboardTones.teinte(tone, percent);

  /// Bord d'une surface teintée — ~2,6× la force du fond.
  static Color bordTeinte(Color tone, int percent) =>
      ColorMix.tint(AppColors.border, tone, percent);

  // ---- Surfaces dérivées, par rôle ----

  /// Fond du corps d'un formulaire de recherche.
  static Color get formulaireFond => teinte(zoneSaisie, formulairePercent);

  /// Bord du corps d'un formulaire de recherche.
  static Color get formulaireBord =>
      bordTeinte(zoneSaisie, formulaireBordPercent);

  /// Fond de la barre de résultats — la surface qui **nomme l'état** de la
  /// recherche, et la seule teintée en permanence quel que soit cet état.
  static Color get barreFond => teinte(zoneResultat, barrePercent);

  /// Bord de la barre de résultats.
  ///
  /// ⚠️ La spec Première inscription publie `#DFC0AC`, valeur que sa **propre
  /// formule** ne produit pas : `mix(--border, terre-cuite 26 %)` donne
  /// `#D8BDA7`, et aucune autre base plausible — blanc, `--surface-alt` — ne
  /// redonne la valeur publiée. C'est la formule qui fait foi, puisque c'est
  /// elle qui se réutilise ; un bord décoratif n'ayant aucun seuil de
  /// contraste, l'écart est sans conséquence visuelle.
  static Color get barreBord => bordTeinte(zoneResultat, bordPercent);

  // ---- Encres ----
  //
  // Toutes opaques. Le blanc translucide est proscrit sur ces écrans : posé
  // sur un dégradé, son ratio dépend du point où on le mesure, donc il n'est
  // pas vérifiable.

  /// Encre des libellés de colonne d'un en-tête de table.
  static const Color inkEnteteTable = AppColors.insInkLabel; // #F8F0E9

  /// Encre de la colonne triée — le tri se lit à la graisse et à cette nuance,
  /// jamais à une couleur d'accent qui entrerait en concurrence avec les
  /// couleurs de donnée des cellules.
  static const Color inkEnteteTri = AppColors.blancCasse; // #FAFAF7

  /// Eyebrow « RÉSULTATS » et pastilles posées sur le voile de la barre : la
  /// terre cuite **assombrie**, jamais [AppColors.terreCuite] — qui tombe à
  /// 4,04:1 sur ce voile-là.
  static const Color inkResultat = AppColors.terreCuiteInk;

  /// Sous-titre posé sur le dégradé de marque d'un bandeau de recherche.
  static const Color inkSousTitre = AppColors.listeInkSubtitle;

  /// Sous-texte de tiroir.
  static const Color inkTiroirSub = AppColors.listeInkDrawerSub;

  // ---- L'habillage d'une table ----

  /// L'habillage complet d'une table de résultats, prêt à passer au socle.
  ///
  /// Composé ici, et non dans le widget : c'est ce fichier qui connaît les
  /// formules. Le composant de table reçoit des couleurs déjà calculées et n'a
  /// pas à savoir qu'un en-tête s'obtient en assombrissant un ton de 20 %.
  ///
  /// Paramétré par le ton plutôt que figé sur [zoneResultat], parce que la
  /// caisse teinte déjà son tableau des reçus en ocre : la fabrique doit
  /// pouvoir porter les deux sans se dédoubler.
  static DataTableTone tableTone(Color tone) => DataTableTone(
    header: DashboardTones.entete(tone),
    headerInk: inkEnteteTable,
    headerInkSorted: inkEnteteTri,
    zebra: DashboardTones.zebrure(tone),
    border: bordTeinte(tone, bordPercent),
  );

  /// L'habillage d'une table de résultats de liste — la terre cuite.
  static DataTableTone get table => tableTone(zoneResultat);
}
