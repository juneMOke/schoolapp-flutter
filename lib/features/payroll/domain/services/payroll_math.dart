/// L'arithmétique de la paie, en entiers — la même en Dart et en Java.
abstract final class PayrollMath {
  /// `a ÷ b` arrondi au plus proche, demi vers le haut, pour `a ≥ 0` et
  /// `b > 0` : `(2a + b) ÷ 2b` en division entière. La seule fonction
  /// d'arrondi du moteur : tout produit passe par elle.
  static int roundDiv(int a, int b) {
    assert(a >= 0 && b > 0, 'roundDiv($a, $b)');
    if (b <= 0) return 0;
    return (2 * a + b) ~/ (2 * b);
  }

  /// `a ÷ b` tronqué, pour `a ≥ 0` et `b > 0` (échéancier cumulé).
  static int floorDiv(int a, int b) => b <= 0 ? 0 : a ~/ b;
}
