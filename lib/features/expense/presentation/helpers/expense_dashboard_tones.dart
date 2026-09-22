import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Les teintes de la bande de chiffres clés des Dépenses — spec Tableaux de
/// bord §&nbsp;05.
///
/// Trois pavés fixes et **un quatrième dont la couleur vient du serveur** :
/// le « poste principal » prend la teinte du poste dominant, lue dans
/// `ref_expense_types.color`. C'est ce quatrième qui fait l'écart E1 de la
/// spec, et c'est pour lui que le garde-fou de [DashboardTones] existe.
class ExpenseDashboardTones {
  const ExpenseDashboardTones._();

  /// Total dépensé — la marque : l'argent qui sort.
  static Color get paveTotal => _pave(AppColors.terreCuite);

  /// Restant à payer — l'ocre, et non le rouge : un fournisseur non réglé
  /// n'est pas un incident.
  static Color get paveRestant => _pave(AppColors.feeStatusPartial);

  /// Dépenses enregistrées — un compteur neutre.
  static Color get paveEnregistrees => _pave(AppColors.bleuArdoise);

  /// Poste principal — **la seule teinte du produit qui vienne du serveur**.
  ///
  /// Passer par [DashboardTones.paveAccentSur] n'est pas ici une précaution de
  /// principe mais le cœur du sujet : quand le poste dominant est « Électricité »
  /// (or `#D9A24E`), le pavé brut rend l'encre crème illisible ; quand c'est une
  /// teinte claire qu'une école a configurée elle-même — et rien ne l'en
  /// empêche — aucune table ne peut l'avoir prévue. Le repli de luminance
  /// assombrit alors jusqu'au seuil.
  ///
  /// Le défaut ne se déclenche que chez les écoles dont la dépense dominante
  /// est celle-là : **aucune relecture ne l'aurait vu.**
  static Color pavePostePrincipal(Color accentServeur) => _pave(accentServeur);

  /// Le garde-fou, puis la formule. Jamais l'inverse.
  static Color _pave(Color accent) =>
      DashboardTones.pave(DashboardTones.paveAccentSur(accent));
}
