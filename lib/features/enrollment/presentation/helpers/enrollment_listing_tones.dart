import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// Teintes des écrans de liste d'inscription (spec Première inscription).
///
/// ## Deux zones, deux couleurs
///
/// Un écran de liste se lit comme une phrase : « je cherche » → « voici ce que
/// j'ai trouvé » → « voici l'état de chacun » → « voici ce que je peux faire ».
/// Le **bleu** appartient à la saisie — bandeau de recherche, champs, filtres.
/// La **terre cuite** appartient au retour de la machine — barre de résultats,
/// en-tête de tableau, zébrure — et à l'écriture — bouton d'action. L'œil sait
/// donc, sans lire, s'il regarde ce qu'il a demandé ou ce qu'on lui répond.
///
/// Trois terre cuite, trois intensités, et c'est tout : 10 % (barre), 6 %
/// (zébrure), 80 % assombri (en-tête de table), 100 % (bouton). C'est
/// l'échelle d'intensité qui hiérarchise, jamais une teinte de plus.
///
/// ## Ce que ce fichier ne décide pas
///
/// **La couleur des avatars.** La spec §13 propose une palette fermée de six
/// valeurs indexée par `nomComplet.hashCode`. Le produit fait mieux depuis
/// longtemps et le garde : `AvatarPalette.colorFor` hache l'**identifiant** de
/// l'élève en FNV-1a, puis descend la luminosité jusqu'à garantir 4,5:1 contre
/// le blanc cassé *et* la surface alternative. Deux raisons de ne pas régresser :
///
/// * `String.hashCode` n'est stable **ni entre deux exécutions ni entre deux
///   versions du VM** — la spec du tableau de bord l'interdit d'ailleurs
///   explicitement, pour cette raison exacte, dans sa palette de cycles ;
/// * hacher le **nom** fait changer la couleur d'une personne dès qu'on corrige
///   une faute de frappe dans son état civil. L'identifiant, lui, ne bouge pas.
///
/// Le contraste des avatars est donc *calculé*, là où la palette de la spec
/// serait seulement *auditée* — et deux de ses six valeurs sont hors palette
/// ETEELO de son propre aveu (écart E3).
class EnrollmentListingTones {
  const EnrollmentListingTones._();

  // ---- Les deux zones ----

  /// Ce que l'utilisateur demande : bandeau de recherche, champs, filtres.
  static const Color zoneSaisie = AppColors.bleuArdoise;

  /// Ce que la machine répond, et ce qu'on écrit : barre, table, bouton.
  static const Color zoneResultat = AppColors.terreCuite;

  // ---- Les trois formules ----
  //
  // Les mêmes qu'au tableau de bord, à un paramètre près. Elles passent par
  // `ColorMix`, qui arrondit là où `Color.lerp` tronque : sur le seul en-tête
  // de table, la troncature décalerait la valeur publiée d'une unité.

  /// Part du ton conservée dans un bandeau de table — les 20 % restants sont
  /// du bleu profond. Le tableau de bord assombrit ses pavés de 22 % ; une
  /// table est moins haute et supporte un ton plus franc.
  static const double enteteToneShare = 0.80;

  /// Bandeau plein d'en-tête de tableau.
  static Color entete(Color tone) =>
      ColorMix.darken(AppColors.bleuProfond, tone, enteteToneShare);

  /// Surface claire : [tone] dilué à [percent] % dans le blanc.
  static Color teinte(Color tone, int percent) =>
      ColorMix.tint(AppColors.surfaceRaised, tone, percent);

  /// Bord d'une surface teintée — ~2,6× la force du fond.
  static Color bordTeinte(Color tone, int percent) =>
      ColorMix.tint(AppColors.border, tone, percent);

  /// Zébrure d'une ligne paire.
  ///
  /// ⚠️ Part de `--surface` (#FAFAF7) et non du blanc : une zébrure se mesure
  /// contre la ligne impaire, qui est cette surface-là. L'écart est
  /// volontairement infime — 1,07:1 — parce qu'une zébrure **ne porte aucune
  /// information** : elle guide l'œil le long d'une ligne, elle ne dit rien.
  static Color zebrure(Color tone) =>
      ColorMix.mix(AppColors.surface, tone, zebrurePercent / 100);

  static const int zebrurePercent = 6;

  // ---- Surfaces dérivées, par rôle ----

  /// Fond de la barre de résultats — terre cuite à 10 %.
  static Color get barreFond => teinte(zoneResultat, 10);

  /// Bord de la barre de résultats.
  ///
  /// ⚠️ La spec publie `#DFC0AC`, valeur que sa **propre formule** ne produit
  /// pas : `mix(--border, terre-cuite 26 %)` donne `#D8BDA7`, et aucune autre
  /// base plausible — blanc, `--surface-alt` — ne redonne la valeur publiée.
  /// C'est la formule qui fait foi, puisque c'est elle qui se réutilise ; un
  /// bord décoratif n'ayant aucun seuil de contraste, l'écart est sans
  /// conséquence visuelle.
  static Color get barreBord => bordTeinte(zoneResultat, 26);

  /// Fond du corps de formulaire de recherche — bleu à 7 %.
  static Color get formulaireFond => teinte(zoneSaisie, 7);

  /// Bord du corps de formulaire de recherche.
  static Color get formulaireBord => bordTeinte(zoneSaisie, 21);

  /// Bandeau d'en-tête du tableau de résultats.
  static Color get tableEntete => entete(zoneResultat);

  /// Zébrure des lignes paires du tableau de résultats.
  static Color get tableZebrure => zebrure(zoneResultat);

  /// Bord du cadre du tableau — même force que celui de la barre, et c'est
  /// voulu : les deux surfaces encadrent la **même** réponse.
  static Color get tableBord => bordTeinte(zoneResultat, 26);

  /// L'habillage complet du tableau de résultats, prêt à passer au socle.
  ///
  /// Composé ici, et non dans le widget : c'est ce fichier qui connaît les
  /// formules. Le composant de table reçoit des couleurs déjà calculées et
  /// n'a pas à savoir qu'un en-tête s'obtient en assombrissant un ton de 20 %.
  static DataTableTone get table => DataTableTone(
    header: tableEntete,
    headerInk: inkEnteteTable,
    headerInkSorted: inkEnteteTri,
    zebra: tableZebrure,
    border: tableBord,
  );

  // ---- Encres ----
  //
  // Toutes opaques. Le blanc translucide est proscrit sur ces écrans : posé
  // sur un dégradé, son ratio dépend du point où on le mesure, donc il n'est
  // pas vérifiable (§12).

  /// Encre d'en-tête de tableau.
  static const Color inkEnteteTable = AppColors.insInkLabel; // #F8F0E9

  /// Encre de la colonne triée — le tri se lit à la graisse et à cette nuance,
  /// jamais à une couleur d'accent.
  static const Color inkEnteteTri = AppColors.blancCasse; // #FAFAF7

  /// Sous-titre posé sur le dégradé du bandeau de recherche.
  static const Color inkSousTitre = AppColors.listeInkSubtitle;

  /// Sous-texte de tiroir.
  static const Color inkTiroirSub = AppColors.listeInkDrawerSub;

  /// Eyebrow « RÉSULTATS » et pastille « niveau visé » : la terre cuite
  /// **assombrie**, jamais `terreCuite` — qui tombe à 4,04:1 sur son voile
  /// (écart E2 de la spec).
  static const Color inkTerreCuite = AppColors.terreCuiteInk;

  // ---- Statut d'un dossier ----

  /// Couleur pleine et voile de chaque statut de dossier.
  ///
  /// Le statut se porte par un **filet** ou une **pastille**, jamais par le
  /// fond de la ligne : une liste bicolore n'a plus de zébrure lisible, et le
  /// statut disparaît à l'impression (§12).
  static const Map<String, ({Color color, Color soft})> statut = {
    'done': (
      color: AppColors.vertSavane,
      soft: AppColors.enrollmentStatsReSoft,
    ),
    'progress': (
      color: AppColors.bleuArdoise,
      soft: AppColors.enrollmentStatsAccentSoft,
    ),
  };

  /// Teinte d'un statut, depuis sa clé.
  static ({Color color, Color soft}) statutOf(String key) {
    final entry = statut[key];
    assert(entry != null, 'Aucun ton déclaré pour le statut « $key ».');
    return entry ??
        (
          color: AppColors.bleuArdoise,
          soft: AppColors.enrollmentStatsAccentSoft,
        );
  }
}
