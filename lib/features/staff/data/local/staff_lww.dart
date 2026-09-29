/// L'arbitrage « dernier écrit gagne » du module RH, partagé par la fiche et
/// le pointage.
abstract final class StaffLww {
  /// Deux écritures d'un même instant : comparées en instants, jamais en
  /// chaînes — le serveur tronque à la microseconde et peut réécrire la forme.
  static bool sameInstant(String? a, String? b) {
    if (a == null || b == null) return a == b;
    final left = DateTime.tryParse(a);
    final right = DateTime.tryParse(b);
    if (left == null || right == null) return a == b;
    return left.isAtSameMomentAs(right);
  }
}
