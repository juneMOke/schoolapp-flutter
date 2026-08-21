import 'package:flutter/services.dart';

/// Capitalisation automatique de la saisie.
///
/// Deux règles, parce que « majuscule à la première lettre » ne veut pas dire
/// la même chose sur une identité et sur un texte libre :
/// [WordCapitalizationInputFormatter] pour les noms de personnes et de lieux
/// (« Jean-Pierre Mokili »), [SentenceCapitalizationInputFormatter] pour les
/// motifs et commentaires (« Absence non justifiée »).
///
/// Les deux ne posent QUE des majuscules : une capitale déjà saisie n'est
/// jamais rabaissée — « KABONGO » reste « KABONGO ».
///
/// ⚠️ Elles s'appliquent en revanche à **chaque frappe**, y compris quand
/// l'utilisateur rabaisse une lettre à la main : « de Souza » redevient « De
/// Souza » au caractère suivant, et « van der Berg » est inatteignable. C'est
/// le comportement historique du champ nom, conservé tel quel ; un champ qui
/// doit accepter une particule déclare `EteeloTextCapitalization.none`.
abstract class _CapitalizationInputFormatter extends TextInputFormatter {
  const _CapitalizationInputFormatter();

  /// Texte réécrit. Retourner [value] tel quel quand rien ne change évite de
  /// reconstruire une sélection pour rien.
  String transform(String value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final transformed = transform(text);
    if (transformed == text) {
      return newValue;
    }

    // La mise en capitale peut allonger le texte (« ß » → « SS ») : on borne la
    // sélection plutôt que de laisser un curseur hors champ.
    final selection = newValue.selection;
    final baseOffset = selection.baseOffset.clamp(0, transformed.length);
    final extentOffset = selection.extentOffset.clamp(0, transformed.length);

    return newValue.copyWith(
      text: transformed,
      selection: TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
      ),
      composing: TextRange.empty,
    );
  }
}

/// Capitalise la première lettre de **chaque mot** — la règle des identités et
/// des lieux. Le trait d'union et l'apostrophe ouvrent un mot : « Jean-Pierre »,
/// « N'Djamena ».
class WordCapitalizationInputFormatter extends _CapitalizationInputFormatter {
  const WordCapitalizationInputFormatter();

  @override
  String transform(String value) {
    final buffer = StringBuffer();
    var shouldCapitalize = true;

    for (var i = 0; i < value.length; i++) {
      final character = value[i];
      if (shouldCapitalize && _isAlphabetic(character)) {
        buffer.write(character.toUpperCase());
      } else {
        buffer.write(character);
      }
      shouldCapitalize = _isWordDelimiter(character);
    }

    return buffer.toString();
  }

  bool _isWordDelimiter(String character) {
    return character.trim().isEmpty || character == '-' || character == "'";
  }
}

/// Capitalise la **première lettre du champ** seulement — la règle des textes
/// libres, où capitaliser chaque mot produirait « Absence Non Justifiée ».
///
/// C'est bien la première lettre, pas le premier caractère : une saisie qui
/// commence par une espace ou un chiffre n'échappe pas à la règle.
class SentenceCapitalizationInputFormatter
    extends _CapitalizationInputFormatter {
  const SentenceCapitalizationInputFormatter();

  @override
  String transform(String value) {
    for (var i = 0; i < value.length; i++) {
      final character = value[i];
      if (!_isAlphabetic(character)) {
        continue;
      }
      final upper = character.toUpperCase();
      return upper == character ? value : value.replaceRange(i, i + 1, upper);
    }
    return value;
  }
}

/// Vrai pour un caractère qui possède une casse — le seul sur lequel poser une
/// majuscule a un sens (exclut chiffres, espaces et ponctuation).
bool _isAlphabetic(String character) {
  return character.toLowerCase() != character.toUpperCase();
}
