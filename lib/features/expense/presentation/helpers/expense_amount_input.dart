/// Lecture du montant saisi (spec §7) — saisie libre, espaces et séparateurs
/// de milliers tolérés.
///
/// Règles, dans l'ordre :
///
/// 1. espaces (ordinaire, insécable, fine insécable) ignorés ;
/// 2. seuls chiffres, virgule et point sont admis ;
/// 3. la **dernière** marque suivie d'un ou deux chiffres est la marque
///    décimale (« 120,50 », « 120.5 », « 1.200,50 ») ;
/// 4. suivie de trois chiffres, c'est un groupement (« 385.000 », « 1,200 ») :
///    un centime n'a jamais trois chiffres ;
/// 5. plus de trois chiffres après la dernière marque : illisible.
abstract final class ExpenseAmountInput {
  /// Centimes lus, ou `null` si rien de lisible ou si le montant n'est pas
  /// strictement positif (« Indiquez le montant réellement décaissé. »).
  static int? toCents(String raw) {
    final cleaned = raw.replaceAll(RegExp('[\\s  ]'), '');
    if (cleaned.isEmpty || RegExp(r'[^0-9.,]').hasMatch(cleaned)) return null;

    var units = cleaned;
    var fraction = '';
    final lastMark = cleaned.lastIndexOf(RegExp(r'[.,]'));
    if (lastMark >= 0) {
      final tail = cleaned.substring(lastMark + 1);
      if (tail.length > 3) return null;
      if (tail.length <= 2) {
        units = cleaned.substring(0, lastMark);
        fraction = tail;
      }
    }

    final digits = units.replaceAll(RegExp(r'[.,]'), '');
    if (digits.isEmpty && fraction.isEmpty) return null;
    final whole = int.tryParse(digits.isEmpty ? '0' : digits);
    if (whole == null) return null;
    final cents = whole * 100 + int.parse(fraction.padRight(2, '0'));
    return cents > 0 ? cents : null;
  }

  /// Le montant rangé, réécrit pour le champ d'une modification : « 385000 »,
  /// « 120,50 » — sans groupement, pour qu'une retouche ne bute sur rien.
  static String fromCents(int cents) {
    final whole = cents ~/ 100;
    final fraction = cents % 100;
    return fraction == 0
        ? '$whole'
        : '$whole,${fraction.toString().padLeft(2, '0')}';
  }
}
