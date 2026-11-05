import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';

import 'cote_grid_hint_band_harness.dart';

const _courses = 12;

/// Trois cases par cours : P1, P2, examen.
const _firstRow = 0;
const _lastRow = (_courses - 1) * 3;

void main() {
  const formats = {'téléphone': Size(360, 740), '7″ portrait': Size(600, 960)};
  for (final MapEntry(key: name, value: size) in formats.entries) {
    for (final keyboard in [0.0, 300.0]) {
      for (final (label, index) in [
        ('1re ligne', _firstRow),
        ('dernière ligne', _lastRow),
      ]) {
        final clavier = keyboard > 0 ? 'clavier ouvert' : 'sans clavier';
        testWidgets('$name, $clavier, $label : la bande est à l\'écran, '
            'la case au-dessus d\'elle', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          addTearDown(tester.view.reset);
          await pumpHintBulletin(
            tester,
            classe: longHintClasse(_courses),
            cells: [
              CoteCell(
                key: CoteCellKey(
                  studentId: 'e1',
                  coursId: 'c${index ~/ 3}',
                  colonneId: 'P1',
                  examen: false,
                ),
                calculee: 12.5,
              ),
            ],
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));

          tester.widget<TextField>(gridField(index)).focusNode!.requestFocus();
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }

          expect(bandText(tester), contains('Moyenne des évaluations'));
          final visibleBottom = size.height - keyboard;
          final page = tester.getRect(find.byType(SingleChildScrollView).first);
          final band = tester.getRect(hintPanel);
          final cell = tester.getRect(gridField(index));
          expect(band.top, greaterThanOrEqualTo(page.top));
          expect(band.bottom, lessThanOrEqualTo(visibleBottom));
          expect(band.bottom, lessThanOrEqualTo(page.bottom));
          expect(band.left, greaterThanOrEqualTo(0));
          expect(band.right, lessThanOrEqualTo(size.width));
          expect(cell.top, greaterThanOrEqualTo(page.top));
          expect(cell.bottom, lessThanOrEqualTo(band.top));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
