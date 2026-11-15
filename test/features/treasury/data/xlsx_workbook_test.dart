import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_workbook.dart';

import '../xlsx_fixture.dart';

void main() {
  test('deux feuilles, dans l ordre du classeur', () {
    final book = XlsxWorkbook.read(cashReportXlsx());
    expect(book.sheets.map((s) => s.name), ['RJ-20261022', 'Données']);
  });

  test('textes partagés, gras, montants au format de la cellule', () {
    final sheet = XlsxWorkbook.read(cashReportXlsx()).sheets.first;
    // La grille commence à la première ligne non vide (2) et garde les
    // colonnes vides avant le contenu (A).
    expect(sheet.rows, hasLength(3));
    expect(sheet.columnCount, 4);
    expect(sheet.rows[0][1].text, 'Caisse');
    expect(sheet.rows[0][1].bold, isTrue);
    expect(sheet.rows[1][3].text, '3 450 000 FC');
    expect(sheet.rows[1][3].numeric, isTrue);
    expect(sheet.rows[2][1].text, 'Total encaissé');
    expect(sheet.rows[2][3].text, '−5 000 FC');
  });

  test('chaîne en ligne et date au format jour/mois/année', () {
    final sheet = XlsxWorkbook.read(cashReportXlsx()).sheets.last;
    expect(sheet.rows[0][0].text, 'Journée');
    expect(sheet.rows[1][0].text, '22/10/2026');
    expect(sheet.rows[1][0].numeric, isFalse);
  });

  test('un fichier qui n est pas un classeur lève FormatException', () {
    expect(
      () => XlsxWorkbook.read(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
