import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/geo/geo_label_matcher.dart';

void main() {
  group('nonEmpty', () {
    test('rogne une chaîne et rend null pour le vide ou un non-texte', () {
      expect(GeoLabelMatcher.nonEmpty('  Funa '), 'Funa');
      expect(GeoLabelMatcher.nonEmpty('   '), isNull);
      expect(GeoLabelMatcher.nonEmpty(42), isNull);
      expect(GeoLabelMatcher.nonEmpty(null), isNull);
    });
  });

  group('resolve', () {
    const options = ['Kalamu', 'Ngaliema', 'Kimbanséké'];

    test("préfère l'option identique", () {
      expect(GeoLabelMatcher.resolve(options, 'Kalamu'), 'Kalamu');
    });

    test('retrouve une option malgré la casse, les accents et les espaces', () {
      expect(GeoLabelMatcher.resolve(options, 'NGALIEMA'), 'Ngaliema');
      expect(GeoLabelMatcher.resolve(options, 'kimbanseke'), 'Kimbanséké');
      expect(GeoLabelMatcher.resolve(options, ' Kim-ban seke '), 'Kimbanséké');
    });

    test('rend null pour une valeur absente ou vide', () {
      expect(GeoLabelMatcher.resolve(options, 'Gombe'), isNull);
      expect(GeoLabelMatcher.resolve(options, ''), isNull);
      expect(GeoLabelMatcher.resolve(options, null), isNull);
    });
  });

  group('withOptional', () {
    test('ajoute en tête une valeur que la liste ne connaît pas', () {
      expect(GeoLabelMatcher.withOptional(['A', 'B'], 'Z'), ['Z', 'A', 'B']);
    });

    test('ne duplique pas une valeur déjà présente et ignore le vide', () {
      expect(GeoLabelMatcher.withOptional(['A', 'B'], 'B'), ['A', 'B']);
      expect(GeoLabelMatcher.withOptional(['A'], '  '), ['A']);
      expect(GeoLabelMatcher.withOptional(['A'], null), ['A']);
    });

    test('rend une liste non modifiable', () {
      final result = GeoLabelMatcher.withOptional(['A'], null);
      expect(() => result.add('B'), throwsUnsupportedError);
    });
  });
}
