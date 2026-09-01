import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_search.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

List<EteeloSelectItem<String>> _items(List<String> labels) => [
  for (final label in labels) EteeloSelectItem(value: label, label: label),
];

void main() {
  group('foldSelectSearchText', () {
    test('replie accents, casse, tirets et apostrophes', () {
      expect(foldSelectSearchText('Ngiri-Ngiri'), 'ngiri ngiri');
      expect(foldSelectSearchText('Côte d’Ivoire'), 'cote d ivoire');
      expect(foldSelectSearchText('ÉLÈVE'), 'eleve');
    });
  });

  group('filterSelectItems', () {
    test('une requete vide rend la liste intacte, dans son ordre', () {
      final items = _items(['Gombe', 'Limete', 'Barumbu']);
      final filtered = filterSelectItems(items, '   ');
      expect(filtered.map((i) => i.label), ['Gombe', 'Limete', 'Barumbu']);
    });

    test('trouve malgre les accents de part et d\'autre', () {
      final items = _items(['Ngiri-Ngiri', 'Gombe']);
      expect(filterSelectItems(items, 'ngíri').single.label, 'Ngiri-Ngiri');
      expect(filterSelectItems(items, 'NGIRI').single.label, 'Ngiri-Ngiri');
    });

    test('exige tous les mots, dans n\'importe quel ordre', () {
      final items = _items(['Kimbanseke Sud', 'Kimbanseke Nord', 'Sud-Kivu']);
      expect(
        filterSelectItems(items, 'sud kimb').single.label,
        'Kimbanseke Sud',
      );
      expect(
        filterSelectItems(items, 'kimb sud').single.label,
        'Kimbanseke Sud',
      );
    });

    test('cherche aussi dans le sous-titre et les termes caches', () {
      final items = [
        const EteeloSelectItem(
          value: 'M1',
          label: 'Maternelle 1',
          subtitle: '24 eleves',
        ),
        const EteeloSelectItem(
          value: 'P1',
          label: 'Primaire 1',
          searchTerms: '1ere annee',
        ),
      ];
      expect(filterSelectItems(items, '24').single.value, 'M1');
      expect(filterSelectItems(items, '1ere').single.value, 'P1');
    });

    test('ne rend rien quand rien ne correspond', () {
      expect(filterSelectItems(_items(['Gombe']), 'zzz'), isEmpty);
    });
  });

  group('dedupeSelectItems', () {
    test('garde la premiere occurrence de chaque valeur', () {
      final items = [
        const EteeloSelectItem(value: 'X', label: 'X'),
        const EteeloSelectItem(value: 'X', label: 'X (doublon)'),
        const EteeloSelectItem(value: 'Y', label: 'Y'),
      ];
      expect(dedupeSelectItems(items).map((i) => i.label), ['X', 'Y']);
    });
  });
}
