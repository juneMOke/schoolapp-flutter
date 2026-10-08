import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/selection_sets.dart';

void main() {
  test('toggled ajoute puis retire', () {
    final once = SelectionSets.toggled(const {}, 'a');
    expect(once, {'a'});
    expect(SelectionSets.toggled(once, 'a'), isEmpty);
  });

  test('pageToggled coche la page, puis la décoche si elle l\'était', () {
    final page = ['a', 'b'];
    final all = SelectionSets.pageToggled({'z'}, page);
    expect(all, {'z', 'a', 'b'});
    expect(SelectionSets.pageToggled(all, page), {'z'});
    expect(SelectionSets.pageToggled({'a'}, page), {'a', 'b'});
    expect(SelectionSets.pageToggled({'z'}, const []), {'z'});
  });
}
