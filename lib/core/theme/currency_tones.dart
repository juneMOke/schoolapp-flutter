import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// La teinte d'une caisse, une par devise : les dollars en bleu ardoise, les
/// francs en vert savane.
///
/// **Elle repère, elle n'informe pas** : partout où elle apparaît, le symbole
/// de la devise l'accompagne. Une devise inconnue prend le gris du texte plutôt
/// qu'une couleur inventée, qui se lirait comme une troisième catégorie.
///
/// Partagée par la caisse (Finances), la boutique et la trésorerie : une seule
/// table, pour que les dollars aient la même couleur sur tous les écrans.
abstract final class CurrencyTones {
  static Color accent(String currency) =>
      switch (CurrencyCode.normalize(currency)) {
        CurrencyCode.usd => AppColors.bleuArdoise,
        CurrencyCode.cdf => AppColors.vertSavane,
        _ => AppColors.textSecondary,
      };

  /// Fond plein d'une tuile de caisse : `#184662` pour les dollars, `#335D48`
  /// pour les francs.
  static Color pave(String currency) =>
      DashboardTones.pave(DashboardTones.paveAccentSur(accent(currency)));
}
