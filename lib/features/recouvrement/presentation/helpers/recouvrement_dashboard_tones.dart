import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Les teintes des cartes de section du tableau de bord Recouvrement.
///
/// Le § 02 de la spec range ce module en « sections sans tone → 9–10 » : ses
/// quatre cartes étaient blanches quand celles d'Inscriptions et de Finances
/// ne le sont plus.
///
/// ⚠️ **La spec ne dit pas quel ton va à quelle section.** Le § 04 décrit les
/// états de dette, le § 02 ne donne qu'une force. Le choix ci-dessous est donc
/// un arbitrage, fait selon les sens du § 07 et non selon une prescription :
///
/// * **Périmètre** — un sélecteur de frais : structurel, donc le bleu ardoise ;
/// * **Taux de recouvrement** — ce qui est rentré, donc le vert savane ;
/// * **Où en est chaque niveau** — un état par niveau, neutre, bleu ardoise ;
/// * **Simulation** — un réglage, donc la marque. Le § 04 pose déjà la règle
///   pour le curseur de cette même carte : « la terre cuite pour un réglage,
///   jamais pour un état ».
///
/// ⚠️ La teinte ne se voit que dans le **corps** de la carte :
/// [BiToneSectionCard] coiffe celle-ci d'un en-tête au dégradé opaque qui lui
/// est propre. C'est voulu — cet en-tête est l'identité partagée des sections
/// de tout le produit — mais une carte teintée n'est donc pas teintée de haut
/// en bas.
class RecouvrementDashboardTones {
  const RecouvrementDashboardTones._();

  // Des getters nommés par paire plutôt qu'un record : `section.$1` dans un
  // arbre de widgets n'apprend rien à qui le lit, et les étiquettes d'un
  // record positionnel — `(Color fond, Color bord)` — ne créent aucun
  // accesseur, ce qui ne se voit qu'à la compilation.

  /// Périmètre — le sélecteur de frais et de cycle.
  static Color get fondPerimetre => _section(AppColors.bleuArdoise).$1;
  static Color get bordPerimetre => _section(AppColors.bleuArdoise).$2;

  /// Taux de recouvrement par frais et par devise.
  static Color get fondTaux => _section(AppColors.vertSavane).$1;
  static Color get bordTaux => _section(AppColors.vertSavane).$2;

  /// « Où en est chaque niveau » — le classement par cycle.
  static Color get fondCycles => _section(AppColors.bleuArdoise).$1;
  static Color get bordCycles => _section(AppColors.bleuArdoise).$2;

  /// « Et si on renvoyait les impayés ? » — la simulation.
  static Color get fondSimulation => _section(AppColors.terreCuite).$1;
  static Color get bordSimulation => _section(AppColors.terreCuite).$2;

  /// La force vient de [DashboardTones.forceDe] : 10 pour les tons froids,
  /// 9 pour les chauds saturés. On règle une densité perçue, pas un chiffre.
  static (Color, Color) _section(Color tone) => DashboardTones.section(tone);
}
