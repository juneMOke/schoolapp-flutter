import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// En français, ICU range 0 dans la catégorie `one` : `one{1 article}` écrit
/// « 1 article » pour un panier vide. La branche `one` doit donc écrire le
/// compteur — ou bien un cas `=0` doit la précéder.
void main() {
  test('aucune branche « one » française ne fige le chiffre 1', () {
    final arb =
        jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync())
            as Map<String, dynamic>;
    final offenders = <String>[
      for (final entry in arb.entries)
        if (!entry.key.startsWith('@') &&
            entry.value is String &&
            _freezesOne(entry.value as String))
          entry.key,
    ];
    expect(offenders, isEmpty);
  });

  test('zéro se lit zéro', () {
    final l10n = AppLocalizationsFr();
    expect(l10n.boutiqueArticleCount(0), '0 article');
    expect(l10n.boutiqueOpenCartWithCount(0), 'Voir le panier, 0 article');
    expect(l10n.financeTillReportBusy(0), contains('dans 0 seconde.'));
    expect(l10n.boutiqueArticleCount(1), '1 article');
    expect(l10n.boutiqueArticleCount(2), '2 articles');
  });
}

/// Vrai si un `{n, plural, …}` du message a une branche `one` qui écrit le
/// chiffre 1 en dur, sans cas `=0` pour lui épargner zéro.
bool _freezesOne(String message) {
  for (final plural in RegExp(r'\{(\w+), plural,').allMatches(message)) {
    final body = _balanced(message, plural.end);
    final one = _caseOf(body, 'one');
    if (one == null || _caseOf(body, '=0') != null) continue;
    if (RegExp(r'(^|\D)1(\D|$)').hasMatch(one)) return true;
  }
  return false;
}

String? _caseOf(String body, String selector) {
  final start = body.indexOf('$selector{');
  if (start < 0) return null;
  return _balanced(body, start + selector.length + 1);
}

/// Le texte jusqu'à l'accolade qui ferme celle ouverte juste avant [from].
String _balanced(String text, int from) {
  var depth = 1;
  var i = from;
  while (i < text.length && depth > 0) {
    if (text[i] == '{') depth++;
    if (text[i] == '}') depth--;
    i++;
  }
  return text.substring(from, i - 1);
}
