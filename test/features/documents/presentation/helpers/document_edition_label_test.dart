import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/presentation/helpers/document_edition_label.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une pièce réémise garde son numéro (back v0.17.0) : l'édition s'ajoute au
/// libellé qui la désigne dès la deuxième, et seulement alors.
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  const label = 'Pièce n° ETL-AI-2526-000087';

  test('une première édition ne s annonce pas', () {
    expect(withDocumentEdition(fr, label, 1), label);
  });

  test('une édition inconnue non plus : celle d une pièce plus ancienne', () {
    expect(withDocumentEdition(fr, label, null), label);
  });

  test('une valeur aberrante ne s affiche pas', () {
    expect(withDocumentEdition(fr, label, 0), label);
  });

  test('dès la deuxième, l édition suit le libellé', () {
    expect(
      withDocumentEdition(fr, label, 2),
      'Pièce n° ETL-AI-2526-000087 · édition 2',
    );
    expect(withDocumentEdition(en, 'No. X', 3), 'No. X · edition 3');
  });
}
