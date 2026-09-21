import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// Teintes du tableau de bord des inscriptions (spec Accueil-Couleurs ▸
/// Inscriptions TdB).
///
/// L'accueil colore des **destinations** ; cet écran colore des **lectures**.
/// Une couleur y désigne une nature de chiffre, pas une porte : les filles
/// sont carmin partout, les réinscriptions vertes partout, le secondaire vert
/// partout.
///
/// ## Deux formules, tout l'écran
///
/// Aucune surface colorée n'est écrite en dur. Les pavés sombres sortent de
/// [pave], les surfaces claires de [teinte], les bords de [bordTeinte]. Un
/// widget ne calcule jamais sa couleur : il la reçoit d'une des trois tables.
///
/// ## Écarts assumés à la spec
///
/// La spec a été vérifiée valeur par valeur : ses deux formules et ses neuf
/// couleurs publiées se reproduisent exactement, et treize de ses quinze
/// ratios annoncés sont justes (les deux autres sous-estiment, donc ne
/// trompent pas). Mais elle mesure les **encres** et aucune **barre**. Trois
/// corrections en découlent, toutes encodées ici et vérifiées par
/// `enrollment_dashboard_tones_test.dart` :
///
/// * **A1 — les remplissages de barre sont des aplats pleins.** La spec §05
///   dessine un dégradé d'opacité `.92 → .34` ; à `.34` la barre tombe à
///   1,76:1 contre sa propre carte, très loin des 3:1 d'un objet graphique.
///   Un plancher ne sauve rien : il faudrait `.83` pour la couleur la plus
///   claire, et un dégradé de `.92` à `.83` n'est plus un dégradé. L'aplat
///   plein passe partout (3,90:1 au pire).
/// * **A2 — l'or `#D9A24E` ne colore aucune donnée.** La spec l'interdit sur
///   du texte et le marque « surfaces seules » — mais une barre EST une
///   surface, et l'or y plafonne à 2,01:1. Il disparaît donc de [insCycleColor]
///   et de [insTypeColor].
/// * **A3 — Maternelle et « pré-inscription » prennent l'ocre.** Aucune couleur
///   neuve : [AppColors.insOcre] est déjà le ton de la section « par cycle » et
///   l'accent du pavé « pré-inscriptions ».
///
/// ## Ce qui n'est pas une contrainte, contrairement aux apparences
///
/// Les trois couleurs de cycle ne se distinguent pas entre **elles** (1,47:1
/// entre primaire et secondaire). C'est sans conséquence : les ventilations
/// sont des **lignes étiquetées**, jamais des segments accolés — elles ne se
/// touchent pas. La contrainte ne vaut que pour la barre 100 % (parité, type),
/// et là elle est levée autrement : chaque segment écrit son libellé, ce que
/// `enrollment_split_bar_paints_test.dart` vérifie déjà. **A4** rend cette
/// dépendance explicite : une barre 100 % dont les segments ne seraient pas
/// étiquetés deviendrait illisible, et aucune couleur de cette palette ne
/// pourrait la sauver.
class EnrollmentDashboardTones {
  const EnrollmentDashboardTones._();

  /// Part de l'accent conservée dans un fond de pavé — les 22 % restants sont
  /// du bleu profond.
  static const double paveAccentShare = 0.78;

  /// Fond plein d'un pavé de chiffre clé.
  static Color pave(Color accent) =>
      ColorMix.darken(AppColors.bleuProfond, accent, paveAccentShare);

  /// Fond clair d'une carte de section : [tone] dilué à [percent] % dans le
  /// blanc.
  static Color teinte(Color tone, int percent) =>
      ColorMix.tint(AppColors.surfaceRaised, tone, percent);

  /// Bord d'une carte teintée — toujours ~3× plus saturé que son fond, sans
  /// quoi la carte n'a plus de contour sur le fond de page.
  static Color bordTeinte(Color tone, int strength) =>
      ColorMix.tint(AppColors.border, tone, (strength * 3).clamp(16, 100));

  // Le voile du médaillon d'en-tête et son liseré appartiennent au composant
  // qui les peint — `EteeloStatsCard.tonedMedallion*` — et non à cette table,
  // qui ne décide que des couleurs.

  // Les voiles internes d'un pavé (halo, médaillon, ombre) appartiennent au
  // composant qui les peint — `EteeloKpiCard` — et non à cette table, qui ne
  // décide que des couleurs. Cf. `EteeloKpiCard.filled*`.

  /// Opacité d'un remplissage de barre (**A1**).
  ///
  /// Constante et non paramétrable : c'est une décision, pas un réglage. Toute
  /// valeur inférieure fait passer au moins une couleur de données sous 3:1
  /// contre sa propre carte — le test le vérifie sur chaque couple.
  static const double barFillOpacity = 1.0;

  /// Plage autorisée pour `toneStrength`. Au-delà de 13, la carte cesse d'être
  /// une surface neutre et concurrence les pavés.
  static const int toneStrengthMin = 4;
  static const int toneStrengthMax = 13;

  /// Accent de chaque pavé de chiffre clé — la couleur de ce qu'il **compte**.
  ///
  /// « Inscriptions » et « Premières » partagent le bleu : le second est une
  /// partie du premier, et la paire bleu/vert se relit telle quelle dans la
  /// barre « par type ». Les différencier suggérerait deux totaux indépendants.
  static const Map<String, Color> kpiAccent = {
    'total': AppColors.bleuArdoise,
    'first': AppColors.bleuArdoise,
    're': AppColors.vertSavane,
    'pre': AppColors.insOcre,
  };

  /// Ton et force de chaque section.
  ///
  /// La force n'est pas constante parce qu'à force égale un carmin et un ocre
  /// ne pèsent pas pareil : les tons chauds saturés descendent à 9, les froids
  /// montent à 10, et le bleu profond — le plus dense — tombe à 8. On règle une
  /// densité **perçue**, pas un chiffre.
  static const Map<String, (Color, int)> sectionTone = {
    'rythme': (AppColors.bleuArdoise, 10),
    'sexe': (AppColors.enrollmentStatsFemale, 9),
    'type': (AppColors.terreCuite, 9),
    'niveau': (AppColors.vertSavane, 10),
    'cycle': (AppColors.insOcre, 10),
    'jour': (AppColors.bleuProfond, 8),
  };

  /// Ton et force d'une section, depuis sa clé.
  ///
  /// Passe par une fonction plutôt que par un accès direct à la table : un
  /// widget qui écrirait `sectionTone['rythme']!` déciderait, par ce `!`, de
  /// planter à l'exécution sur une clé fautive. Ici la faute se dit en debug
  /// et se dégrade proprement en release.
  static (Color, int) section(String key) {
    final entry = sectionTone[key];
    assert(entry != null, 'Aucun ton déclaré pour la section « $key ».');
    return entry ?? (AppColors.bleuArdoise, 10);
  }

  /// Teinte d'une section, pour `EteeloStatsCard.tone`.
  static Color sectionTint(String key) => section(key).$1;

  /// Force de la teinte, pour `EteeloStatsCard.toneStrength`.
  static int sectionStrength(String key) => section(key).$2;

  /// Fond plein du pavé de chiffre clé [key] — ce que reçoit
  /// `EteeloKpiCardData.filledBackground`.
  static Color kpiFill(String key) {
    final accent = kpiAccent[key];
    assert(accent != null, 'Aucun accent déclaré pour le pavé « $key ».');
    return pave(accent ?? AppColors.bleuArdoise);
  }

  /// Fond et bord d'une carte de section, depuis sa clé.
  static (Color background, Color border) sectionSurface(String key) {
    final entry = sectionTone[key];
    assert(entry != null, 'Aucun ton déclaré pour la section « $key ».');
    final (tone, strength) = entry ?? (AppColors.bleuArdoise, 10);
    return (teinte(tone, strength), bordTeinte(tone, strength));
  }

  /// Couleur d'un sexe. Portée par la donnée, jamais choisie par un graphique.
  static const Map<String, Color> sexeColor = {
    'F': AppColors.enrollmentStatsFemale,
    'M': AppColors.bleuArdoise,
  };

  /// Couleur d'un type d'inscription.
  ///
  /// `pre` prenait l'or `#D9A24E` dans la spec ; il prend l'ocre (**A2/A3**).
  static const Map<String, Color> typeColor = {
    'first': AppColors.bleuArdoise,
    're': AppColors.vertSavane,
    'pre': AppColors.insOcre,
  };

  /// Couleur d'une famille de cycle.
  ///
  /// Maternelle prenait l'or ; elle prend l'ocre (**A2/A3**). Les trois valeurs
  /// se détachent de leur carte en aplat plein — c'est la seule exigence, les
  /// lignes de ventilation ne se touchant pas.
  static const Map<String, Color> cycleColor = {
    'Maternelle': AppColors.insOcre,
    'Primaire': AppColors.bleuArdoise,
    'Secondaire': AppColors.vertSavane,
  };

  /// Toutes les couleurs susceptibles d'être peintes en barre, pour que le test
  /// de non-régression n'ait pas à les réénumérer de son côté.
  static List<Color> get barColors => {
    ...sexeColor.values,
    ...typeColor.values,
    ...cycleColor.values,
  }.toList(growable: false);
}
