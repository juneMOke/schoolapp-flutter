import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

/// Table de dépliage des diacritiques.
///
/// Le catalogue des nationalités est saisi sans accents (« Algerienne »), les
/// noms de communes et de quartiers en portent (« Ngiri-Ngiri », « Kimbanseke
/// Sud », « Bandalungwa »). Sans normalisation, taper « alge » trouve, taper
/// « ngíri » ne trouve plus, et le guichet conclut que la recherche est
/// cassée. On replie les deux côtés — la requête ET l'option — sur la même
/// base ASCII.
const Map<String, String> _foldings = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
  // Le tiret et l'apostrophe séparent des mots, ils ne les composent pas :
  // « Ngiri-Ngiri » doit sortir sur « ngiri ngiri » comme sur « ngirin ».
  '-': ' ', "'": ' ', '’': ' ',
};

/// Replie une chaîne sur sa forme comparable : minuscules, sans accents.
String foldSelectSearchText(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_foldings[char] ?? char);
  }
  return buffer.toString();
}

/// Filtre une liste d'options sur une requête libre.
///
/// Les mots de la requête sont exigés **tous**, dans n'importe quel ordre :
/// « sud kimb » trouve « Kimbanseke Sud ». Une requête vide rend la liste
/// intacte — on ne réordonne jamais les options, leur ordre est celui que
/// l'appelant a choisi (référentiel, ordre pédagogique, ordre du guichet).
List<EteeloSelectItem<T>> filterSelectItems<T>(
  List<EteeloSelectItem<T>> items,
  String query,
) {
  final tokens = foldSelectSearchText(
    query.trim(),
  ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
  if (tokens.isEmpty) return items;

  return items
      .where((item) {
        final haystack = foldSelectSearchText(
          [item.label, item.subtitle ?? '', item.searchTerms ?? ''].join(' '),
        );
        return tokens.every(haystack.contains);
      })
      .toList(growable: false);
}

/// Dédoublonne par valeur en gardant la première occurrence.
///
/// Les cascades géographiques peuvent produire deux fois la même valeur le
/// temps d'un rechargement ; une liste qui affiche deux lignes identiques fait
/// douter de ce qui a été enregistré.
List<EteeloSelectItem<T>> dedupeSelectItems<T>(
  List<EteeloSelectItem<T>> items,
) {
  final seen = <T>{};
  return [
    for (final item in items)
      if (seen.add(item.value)) item,
  ];
}
