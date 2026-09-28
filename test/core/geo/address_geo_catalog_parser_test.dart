import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog_parser.dart';

void main() {
  group('format structuré', () {
    final parsed = AddressGeoCatalogParser.parse({
      'ville': 'Kinshasa',
      'districts': [
        {
          'nom': 'Funa',
          'communes': [
            {
              'nom': 'Kalamu',
              'quartiers': [
                {'nom': 'Matonge', 'code_postal': '1234'},
                'Yolo',
                'Yolo',
                {'nom': '  '},
              ],
            },
            {'nom': 'Vide', 'quartiers': <Object>[]},
          ],
        },
        {'nom': 'Sans communes'},
      ],
    }, defaultCity: 'Défaut');

    test('garde la cascade et écarte les branches vides', () {
      expect(parsed.data.keys, ['Kinshasa']);
      expect(parsed.data['Kinshasa']!.keys, ['Funa']);
      expect(parsed.data['Kinshasa']!['Funa']!.keys, ['Kalamu']);
    });

    test('dédoublonne les quartiers et affiche le code postal', () {
      expect(parsed.data['Kinshasa']!['Funa']!['Kalamu'], ['Matonge', 'Yolo']);
      expect(parsed.neighborhoodDisplayMaps['Kinshasa']!['Funa']!['Kalamu'], {
        'Matonge (1234)': 'Matonge',
        'Yolo': 'Yolo',
      });
    });

    test("prend la ville par défaut quand le fichier n'en donne pas", () {
      final withoutCity = AddressGeoCatalogParser.parse({
        'districts': [
          {
            'nom': 'Lukunga',
            'communes': [
              {
                'nom': 'Gombe',
                'quartiers': ['Golf'],
              },
            ],
          },
        ],
      }, defaultCity: 'Kinshasa');

      expect(withoutCity.data.keys, ['Kinshasa']);
    });
  });

  test('format historique : ville → district → commune → quartiers', () {
    final parsed = AddressGeoCatalogParser.parse({
      'Kinshasa': {
        'Funa': {
          'Kalamu': [' Matonge ', '', 'Yolo'],
        },
      },
    }, defaultCity: 'Kinshasa');

    expect(parsed.data['Kinshasa']!['Funa']!['Kalamu'], ['Matonge', 'Yolo']);
    expect(parsed.neighborhoodDisplayMaps['Kinshasa']!['Funa']!['Kalamu'], {
      'Matonge': 'Matonge',
      'Yolo': 'Yolo',
    });
  });
}
