import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

void main() {
  group('SearchNormalizationHelper.normalize', () {
    test('met en minuscules', () {
      expect(SearchNormalizationHelper.normalize('AWA'), 'awa');
    });

    test('retire les accents courants', () {
      expect(SearchNormalizationHelper.normalize('José'), 'jose');
      expect(SearchNormalizationHelper.normalize('Émile'), 'emile');
      expect(SearchNormalizationHelper.normalize('Noël'), 'noel');
      expect(SearchNormalizationHelper.normalize('François'), 'francois');
    });

    test('combine casse et accents', () {
      expect(SearchNormalizationHelper.normalize('ÉCOLE'), 'ecole');
    });

    test('laisse les caractères non accentués intacts', () {
      expect(SearchNormalizationHelper.normalize("N'Sumbu"), "n'sumbu");
    });
  });

  group('SearchNormalizationHelper.contains', () {
    test('terme vide ou null matche toujours', () {
      expect(SearchNormalizationHelper.contains('José', ''), isTrue);
      expect(SearchNormalizationHelper.contains('José', null), isTrue);
      expect(SearchNormalizationHelper.contains(null, null), isTrue);
    });

    test('champ null ne matche jamais un terme non vide', () {
      expect(SearchNormalizationHelper.contains(null, 'jose'), isFalse);
    });

    test('terme sans accent matche un champ accentué', () {
      expect(SearchNormalizationHelper.contains('José', 'jose'), isTrue);
    });

    test('terme accentué matche un champ sans accent', () {
      expect(SearchNormalizationHelper.contains('Ecole', 'écolé'), isTrue);
    });

    test('insensible à la casse', () {
      expect(SearchNormalizationHelper.contains('José', 'JOSE'), isTrue);
    });

    test('substring simple toujours supportée', () {
      expect(SearchNormalizationHelper.contains('Ndiaye', 'dia'), isTrue);
      expect(SearchNormalizationHelper.contains('Ndiaye', 'zzz'), isFalse);
    });
  });
}
