import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/level_code_sorter.dart';

void main() {
  group('compareLevelCodes', () {
    test('trie les prefixes numeriques de facon naturelle', () {
      final values = ['10A', '2B', '1C'];
      values.sort(compareLevelCodes);

      expect(values, ['1C', '2B', '10A']);
    });

    test('trie les suffixes numeriques de facon naturelle', () {
      final values = ['A10', 'A2', 'A1'];
      values.sort(compareLevelCodes);

      expect(values, ['A1', 'A2', 'A10']);
    });

    test('place les versions courtes avant les variantes suffixees', () {
      final values = ['1B', '1', '1A'];
      values.sort(compareLevelCodes);

      expect(values, ['1', '1A', '1B']);
    });
  });
}
