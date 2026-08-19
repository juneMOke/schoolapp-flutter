import 'package:school_app_flutter/core/helpers/phone_number_format.dart';

/// Rapprochement de deux numéros de téléphone en SQL, insensible au format
/// d'écriture.
///
/// Depuis le passage de la saisie en E.164, un même tuteur peut exister sous
/// deux écritures : la fiche héritée (`0816939060`, `+243 81 693 90 60`) et
/// la saisie du jour (`+243816939060`). Une comparaison par égalité stricte
/// les prendrait pour deux personnes et créerait un doublon de tuteur —
/// invisible à la saisie, mais qui éclate ensuite la fratrie et la
/// facturation.
///
/// La comparaison porte donc sur les derniers chiffres significatifs, ce qui
/// absorbe indicatif, `0` du plan national et séparateurs sans avoir à
/// réécrire les lignes en base.
///
/// ⚠️ C'est un PRÉ-FILTRE, pas un verdict : deux abonnés de pays voisins
/// peuvent partager leurs derniers chiffres (`+242…` / `+243…`, de part et
/// d'autre du fleuve). Les candidats remontés doivent être confirmés en Dart
/// par [PhoneNumberFormat.sameNumber], qui lui garde l'indicatif — sans quoi
/// un élève finirait rattaché au parent d'un autre.
abstract final class PhoneNumberSql {
  /// Nombre de chiffres comparés : la partie nationale complète du pays de
  /// saisie (v1 mono-pays).
  static final int _significantDigits = PhoneCountry.congoDrc.nationalLength;

  /// Séparateurs retirés avant comparaison. SQLite n'offrant pas de « tout
  /// sauf un chiffre », la liste est explicite : elle couvre ce qu'une
  /// saisie ou un pull peut déposer dans la colonne (l'espace insécable
  /// arrive des copier-coller). Un séparateur exotique ne fausse pas le
  /// résultat, il fait seulement manquer le rapprochement — l'égalité
  /// stricte d'avant les manquait tous.
  static const List<String> _separators = [
    ' ',
    '-',
    '(',
    ')',
    '+',
    '.',
    '/',
    '\u00A0',
    '\u202F',
  ];

  /// Chiffres seuls d'une expression SQL (séparateurs et `+` retirés).
  static String digitsOnly(String expr) {
    var sql = expr;
    for (final separator in _separators) {
      sql = "REPLACE($sql, '$separator', '')";
    }
    return sql;
  }

  /// Expression SQL réduisant [expr] à sa clé de rapprochement. Un numéro
  /// plus court que [_significantDigits] est comparé en entier.
  static String matchKey(String expr) =>
      'SUBSTR(${digitsOnly(expr)}, -$_significantDigits)';

  /// Clé de rapprochement calculée côté Dart, à passer en argument face à un
  /// [matchKey] appliqué à une colonne. Même rôle de pré-filtre : la
  /// décision revient à [PhoneNumberFormat.sameNumber].
  static String matchKeyOf(String rawPhone) {
    final digits = PhoneNumberFormat.digitsOnly(rawPhone);
    if (digits.length <= _significantDigits) return digits;
    return digits.substring(digits.length - _significantDigits);
  }
}
