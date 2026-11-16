import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_styles.dart';
import 'package:xml/xml.dart';

export 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_styles.dart'
    show XlsxAlign;

/// Une cellule lue : son texte prêt à afficher et son allure.
class XlsxCell {
  final String text;
  final bool bold;

  /// Un nombre : à droite, sauf alignement posé par la feuille.
  final bool numeric;

  /// Fond et encre en ARGB, `null` si la feuille n'en pose pas.
  final int? fill;
  final int? ink;
  final XlsxAlign? align;

  /// Colonnes couvertes, elle comprise (cellule fusionnée) ; 0 pour une
  /// cellule recouverte par sa voisine de gauche.
  final int span;

  const XlsxCell(
    this.text, {
    this.bold = false,
    this.numeric = false,
    this.fill,
    this.ink,
    this.align,
    this.span = 1,
  });

  static const empty = XlsxCell('');

  XlsxCell withSpan(int span) => XlsxCell(
    text,
    bold: bold,
    numeric: numeric,
    fill: fill,
    ink: ink,
    align: align,
    span: span,
  );

  bool get isBlank => text.isEmpty && fill == null;
}

class XlsxSheet {
  final String name;

  /// Les lignes, de la première à la dernière non vide ; chaque ligne a
  /// [columnCount] cellules.
  final List<List<XlsxCell>> rows;
  final int columnCount;

  /// La largeur de chaque colonne posée par la feuille, en unités de
  /// caractère d'Excel ; `null` quand elle n'en pose pas.
  final List<double?> widths;

  /// Le numéro Excel de la première ligne de [rows] (1 pour la ligne 1).
  final int firstRow;

  const XlsxSheet({
    required this.name,
    required this.rows,
    required this.columnCount,
    this.widths = const [],
    this.firstRow = 1,
  });
}

/// Un classeur `.xlsx` lu pour l'**aperçu** (Trésorerie A6) : valeurs,
/// montants et heures mis en forme, gras, couleurs, alignement, largeurs de
/// colonnes et cellules fusionnées sur une ligne. Le fichier enregistré reste
/// complet : l'aperçu sert à lire, pas à éditer.
///
/// Un `.xlsx` est un zip de XML : le classeur nomme ses feuilles, les
/// relations disent où elles sont, les chaînes partagées portent les textes,
/// les styles l'allure des cellules.
class XlsxWorkbook {
  final List<XlsxSheet> sheets;

  const XlsxWorkbook(this.sheets);

  /// Lit [bytes]. Lève une [FormatException] sur un fichier illisible.
  static XlsxWorkbook read(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Classeur illisible');
    }
    XmlDocument? doc(String path) {
      final file = archive.findFile(path);
      if (file == null) return null;
      return XmlDocument.parse(utf8.decode(file.content, allowMalformed: true));
    }

    final workbook = doc('xl/workbook.xml');
    if (workbook == null) throw const FormatException('Classeur sans feuille');
    final targets = <String, String>{
      for (final rel
          in doc(
                'xl/_rels/workbook.xml.rels',
              )?.findAllElements('Relationship') ??
              const <XmlElement>[])
        rel.getAttribute('Id') ?? '': rel.getAttribute('Target') ?? '',
    };
    final shared = [
      for (final si
          in doc('xl/sharedStrings.xml')?.findAllElements('si') ??
              const <XmlElement>[])
        si.findAllElements('t').map((t) => t.innerText).join(),
    ];
    final styles = XlsxStyles.of(doc('xl/styles.xml'));
    final sheets = <XlsxSheet>[];
    for (final sheet in workbook.findAllElements('sheet')) {
      final relId = sheet.attributes
          .where((a) => a.name.local == 'id')
          .map((a) => a.value)
          .firstOrNull;
      final target = targets[relId];
      if (target == null) continue;
      final path = target.startsWith('/')
          ? target.substring(1)
          : 'xl/${target.replaceFirst(RegExp(r'^\./'), '')}';
      final xml = doc(path);
      if (xml == null) continue;
      sheets.add(_sheet(sheet.getAttribute('name') ?? '', xml, shared, styles));
    }
    if (sheets.isEmpty) throw const FormatException('Classeur sans feuille');
    return XlsxWorkbook(sheets);
  }

  static XlsxSheet _sheet(
    String name,
    XmlDocument xml,
    List<String> shared,
    XlsxStyles styles,
  ) {
    final cells = <int, Map<int, XlsxCell>>{};
    var maxCol = -1;
    for (final row in xml.findAllElements('row')) {
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r');
        if (ref == null) continue;
        final (rowIndex, colIndex) = _position(ref);
        final style = styles.at(int.tryParse(c.getAttribute('s') ?? '') ?? 0);
        final cell = _cell(c, shared, style);
        if (cell.isBlank) continue;
        (cells[rowIndex] ??= {})[colIndex] = cell;
        if (colIndex > maxCol) maxCol = colIndex;
      }
    }
    if (cells.isEmpty) {
      return XlsxSheet(name: name, rows: const [], columnCount: 0);
    }
    // Fusions sur une ligne : la première cellule s'étend, les autres
    // s'effacent. Une fusion sur plusieurs lignes garde sa première ligne.
    for (final merge in xml.findAllElements('mergeCell')) {
      final range = merge.getAttribute('ref')?.split(':');
      if (range == null || range.length != 2) continue;
      final (r0, c0) = _position(range[0]);
      final (_, c1) = _position(range[1]);
      if (c1 <= c0) continue;
      final row = cells[r0] ??= {};
      row[c0] = (row[c0] ?? XlsxCell.empty).withSpan(c1 - c0 + 1);
      for (var col = c0 + 1; col <= c1; col++) {
        row[col] = const XlsxCell('', span: 0);
      }
      if (c1 > maxCol) maxCol = c1;
    }
    final widths = List<double?>.filled(maxCol + 1, null);
    for (final col in xml.findAllElements('col')) {
      final min = int.tryParse(col.getAttribute('min') ?? '');
      final max = int.tryParse(col.getAttribute('max') ?? '');
      final width = double.tryParse(col.getAttribute('width') ?? '');
      if (min == null || max == null || width == null) continue;
      for (var i = min - 1; i < max && i <= maxCol; i++) {
        if (i >= 0) widths[i] = width;
      }
    }
    final first = cells.keys.reduce((a, b) => a < b ? a : b);
    final last = cells.keys.reduce((a, b) => a > b ? a : b);
    return XlsxSheet(
      name: name,
      columnCount: maxCol + 1,
      widths: widths,
      firstRow: first + 1,
      rows: [
        for (var r = first; r <= last; r++)
          [
            for (var col = 0; col <= maxCol; col++)
              cells[r]?[col] ?? XlsxCell.empty,
          ],
      ],
    );
  }

  static XlsxCell _cell(XmlElement c, List<String> shared, XlsxStyle style) {
    final type = c.getAttribute('t');
    final raw = c.getElement('v')?.innerText;
    XlsxCell text(String value) => XlsxCell(
      value,
      bold: style.bold,
      fill: style.fill,
      ink: style.ink,
      align: style.align,
    );
    switch (type) {
      case 's':
        final index = int.tryParse(raw ?? '');
        return text(
          index != null && index < shared.length ? shared[index] : '',
        );
      case 'inlineStr':
        return text(c.findAllElements('t').map((t) => t.innerText).join());
      case 'str':
      case 'e':
        return text(raw ?? '');
      case 'b':
        return text(raw == '1' ? 'VRAI' : 'FAUX');
      default:
        final value = num.tryParse(raw ?? '');
        if (value == null) return text(raw ?? '');
        return XlsxCell(
          style.format(value),
          bold: style.bold,
          fill: style.fill,
          ink: style.ink,
          align: style.align,
          numeric: !style.isTemporal,
        );
    }
  }

  /// « B12 » → (11, 1), à partir de zéro.
  static (int, int) _position(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref);
    if (match == null) return (0, 0);
    var col = 0;
    for (final unit in match.group(1)!.codeUnits) {
      col = col * 26 + (unit - 64);
    }
    return (int.parse(match.group(2)!) - 1, col - 1);
  }
}
