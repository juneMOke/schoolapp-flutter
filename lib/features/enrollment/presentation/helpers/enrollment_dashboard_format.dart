/// Le formatage des nombres du tableau de bord.
///
/// Rassemblé ici pour que les milliers s'écrivent partout de la même façon —
/// et parce que les composants de socle, eux, ne formatent rien : ils
/// reçoivent des chaînes déjà accordées, ce qui les laisse servir aussi bien
/// « 14 élèves » que « 2 805 000 FC ».
abstract final class EnrollmentDashboardFormat {
  /// Espace **insécable fine** entre les groupes de milliers, comme le veut la
  /// typographie française. Un espace ordinaire laisserait « 1 » seul en fin
  /// de ligne et « 250 » à la ligne suivante.
  static const String _thousandsSeparator = ' ';

  /// `1250` → `1 250`.
  ///
  /// Écrit à la main plutôt qu'avec `intl` : le paquet n'est pas une
  /// dépendance directe du projet, et le seul besoin est le groupement par
  /// trois. Les nombres de cet écran sont des effectifs — jamais de décimales,
  /// jamais de devise.
  static String count(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(_thousandsSeparator);
      }
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

  /// Part de [value] dans [total], arrondie. `0` quand le total est nul —
  /// jamais une division par zéro, jamais un `NaN` à l'écran.
  static int share(int value, int total) =>
      total <= 0 ? 0 : ((value * 100) / total).round();
}
