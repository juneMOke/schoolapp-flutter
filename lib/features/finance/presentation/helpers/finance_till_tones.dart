import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';

/// Les teintes du tableau de bord de la caisse — spec Tableaux de bord §&nbsp;03,
/// moitié « Encaissements ».
///
/// Elles **dérivent** de la grammaire partagée plutôt que de la redéclarer :
/// avant ce fichier, l'écran posait ses couleurs en dur et la coïncidence avec
/// `DashboardSense` n'était qu'une coïncidence de palette. Un pavé de caisse
/// s'obtient désormais par la même formule que ceux des trois autres tableaux
/// de bord, et il suivra leurs évolutions sans qu'on y pense.
///
/// La doctrine propre à cet écran est conservée : **la teinte repère, elle
/// n'informe pas.** Partout où une couleur de devise apparaît, le symbole de la
/// devise l'accompagne — la couleur ne porte jamais seule cette information.
class FinanceTillTones {
  const FinanceTillTones._();

  /// Fond plein d'une tuile de caisse : `#184662` pour les dollars, `#335D48`
  /// pour les francs.
  ///
  /// Le garde-fou passe en premier par principe. Aucune des deux devises n'est
  /// substituée aujourd'hui — toutes deux sont des sens sombres — mais une
  /// troisième devise prend le gris du texte, qui lui **serait** substitué.
  static Color paveDeCaisse(String currency) => DashboardTones.pave(
    DashboardTones.paveAccentSur(tillCurrencyAccent(currency)),
  );

  /// Fond plein de la tuile « Reçus émis » : `#855D0F`.
  ///
  /// L'ocre, et non une teinte de devise. Le code gardait cette tuile
  /// **neutre** pour dire « ce n'est pas un montant » ; la spec le dit par une
  /// couleur qui n'est ni celle des dollars ni celle des francs. L'intention
  /// est la même, le moyen change — et la grammaire partagée range déjà les
  /// reçus émis sous [DashboardSense.attente].
  static Color get paveDesRecus => DashboardTones.pave(DashboardSense.attente);

  /// Voile du médaillon sur un pavé.
  ///
  /// Emprunté à la carte KPI du socle plutôt que recopié : deux valeurs qui
  /// divergeraient feraient deux bandes de pavés d'aspect différent sur le
  /// même produit.
  static const double voileMedaillon = EteeloKpiCard.filledMedallionVeil;

  /// Encres de la ligne de tendance, **sur un pavé de caisse**.
  ///
  /// ⚠️ `vertSavane` et `error` — les couleurs de la tuile blanche — tombent à
  /// **1,63** et **1,85** sur le pavé dollars, **1,21** et **1,38** sur le pavé
  /// francs. Ce ne sont pas des valeurs limites : la ligne devient invisible.
  /// Les deux nuances claires ci-dessous tiennent (7,95 / 5,94 en hausse,
  /// 7,27 / 5,43 en baisse).
  ///
  /// Elles ne valent que pour les **deux pavés de caisse** : sur le pavé ocre
  /// des reçus, [AppColors.paveInkReste] retomberait à 4,26. La tuile des reçus
  /// ne porte pas de tendance, et ce n'est pas un hasard — un compteur d'objets
  /// n'a pas de variation à comparer.
  static const Color inkTendanceHausse = AppColors.paveInkPercu;
  static const Color inkTendanceBaisse = AppColors.paveInkReste;

  /// L'encre de la pastille « boutique ».
  ///
  /// ⚠️ La terre cuite pleine ne se lit pas sur son propre voile : **3,90:1**,
  /// et **4,01** sur le fond que la spec prescrit — sous le seuil dans les deux
  /// cas, pour un texte. C'est l'écart E2, et sa réponse existait déjà sans
  /// être employée ici.
  static const Color inkBoutique = AppColors.terreCuiteInk;

  // ---- Cartes de section (spec §03 · forces normalisées par le §02) ----
  //
  // Les cinq tons vivent **ici et pas dans les widgets** : éparpillés, cinq
  // sections voisines dériveraient l'une après l'autre au premier ajustement.
  //
  // ⚠️ La force vient de [DashboardTones.forceDe], pas du chiffre écrit dans
  // la spec section par section. Les deux ne divergent que sur les reçus — la
  // spec écrit 9, la grammaire rend 10 — soit `#F7F2E8` contre `#F6F0E6`, un
  // écart invisible. Normaliser ces forces **entre écrans** est précisément la
  // raison d'être du § 02 ; suivre le chiffre local le contredirait.

  /// « Jour par jour » — le seul ton piloté par la donnée : il suit la caisse
  /// affichée, comme les barres qu'il encadre.
  static (Color fond, Color bord) sectionJourParJour(String currency) =>
      DashboardTones.section(tillCurrencyAccent(currency));

  /// « Par source » — la marque, parce qu'on y parle de la boutique.
  static (Color fond, Color bord) get sectionParSource =>
      DashboardTones.section(AppColors.terreCuite);

  /// « Poste imputé » — le neutre structurel.
  static (Color fond, Color bord) get sectionPosteImpute =>
      DashboardTones.section(AppColors.bleuArdoise);

  /// « Par classe » — l'encaissé.
  static (Color fond, Color bord) get sectionParClasse =>
      DashboardTones.section(AppColors.vertSavane);

  /// « Reçus de la caisse » — l'ocre, le même que le bandeau de sa table.
  static (Color fond, Color bord) get sectionDesRecus =>
      DashboardTones.section(DashboardSense.attente);

  /// L'habillage du tableau des reçus — ton ocre `#A66A00`.
  ///
  /// Les couleurs arrivent calculées : le composant de table ne sait pas qu'un
  /// bandeau s'obtient en assombrissant un ton de 20 % vers le bleu profond.
  /// Les deux encres d'en-tête sont celles du module Inscriptions, vérifiées
  /// sur **ce** bandeau-ci (5,10 et 5,50) et non reprises de confiance.
  static DataTableTone get tableDesRecus => DataTableTone(
    header: DashboardTones.entete(DashboardSense.attente),
    headerInk: AppColors.insInkLabel,
    headerInkSorted: AppColors.blancCasse,
    zebra: DashboardTones.zebrure(DashboardSense.attente),
    border: ColorMix.tint(AppColors.border, DashboardSense.attente, 26),
  );
}
