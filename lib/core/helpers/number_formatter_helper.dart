/// Helper pour formater les grands nombres en K (milliers) et M (millions)
///
/// Exemples:
/// - 500 → "500"
/// - 1500 → "1.5K"
/// - 10000 → "10K"
/// - 1500000 → "1.5M"
/// - 10000000 → "10M"
class NumberFormatterHelper {
  /// Formate un nombre pour l'affichage en axe Y
  /// avec K pour les milliers et M pour les millions
  static String formatYAxisLabel(double value) {
    final absValue = value.abs();

    // Pour les millions
    if (absValue >= 1000000) {
      final millions = value / 1000000;
      // Affiche 1 décimale si < 10M, pas de décimale sinon
      if (millions.abs() < 10) {
        return '${millions.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}M';
      }
      return '${millions.toStringAsFixed(0)}M';
    }

    // Pour les milliers
    if (absValue >= 1000) {
      final thousands = value / 1000;
      // Affiche 1 décimale si < 10K, pas de décimale sinon
      if (thousands.abs() < 10) {
        return '${thousands.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}K';
      }
      return '${thousands.toStringAsFixed(0)}K';
    }

    // Pour les valeurs < 1000
    return value.toInt().toString();
  }
}
