import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Les teintes des tableaux du tableau de bord Boutique — **la recette du
/// tableau des reçus de la caisse Finances** (`FinanceTillTones.tableDesRecus`)
/// : bandeau d'en-tête assombri vers le bleu profond, zébrure, cadre teinté, et
/// la carte de section du même ton.
///
/// Les tons suivent le sens partagé des tableaux de bord : des **reçus**
/// s'écrivent en ocre partout — « Dernières ventes » porte donc celui des reçus
/// de la caisse —, des **effectifs** en bleu ardoise.
abstract final class BoutiqueDashboardTones {
  /// « Dernières ventes » : des reçus.
  static const Color ventes = DashboardSense.attente;

  /// « Élèves concernés » : un effectif.
  static const Color eleves = DashboardSense.attendu;

  /// Le bandeau, la zébrure et le cadre d'un tableau de ton [tone]. Les encres
  /// d'en-tête sont celles de la caisse, vérifiées sur ces deux bandeaux par
  /// `boutique_dashboard_tones_test.dart`.
  static DataTableTone tableOf(Color tone) => DataTableTone(
    header: DashboardTones.entete(tone),
    headerInk: AppColors.insInkLabel,
    headerInkSorted: AppColors.blancCasse,
    zebra: DashboardTones.zebrure(tone),
    border: ColorMix.tint(AppColors.border, tone, 26),
  );

  /// La force de la carte de section qui porte le tableau.
  static int sectionStrength(Color tone) => DashboardTones.forceDe(tone);
}
