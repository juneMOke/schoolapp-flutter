import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Une cellule lue : son texte prêt à afficher, et sa graisse.
class XlsxCell {
  final String text;
  final bool bold;

  /// Un nombre : on l'aligne à droite.
  final bool numeric;

  const XlsxCell(this.text, {this.bold = false, this.numeric = false});

  static const empty = XlsxCell('');
}

class XlsxSheet {
  final String name;

  /// Les lignes, de la première à la dernière non vide ; chaque ligne a
  /// [columnCount] cellules.
  final List<List<XlsxCell>> rows;
  final int columnCount;

  const XlsxSheet({
    required this.name,
    required this.rows,
    required this.columnCount,
  });
}

/// Un classeur `.xlsx` lu pour l'**aperçu** (Trésorerie A6) : les valeurs, les
/// montants mis en forme, la graisse. Ni couleurs ni cellules fusionnées : le
/// fichier enregistré reste complet, l'aperçu sert à vérifier les chiffres.
///
/// Un `.xlsx` est un zip de XML : le classeur nomme ses feuilles, les
/// relations disent où elles sont, les chaînes partagées portent les textes,
/// les styles disent ce qui est en gras et comment un nombre s'écrit.
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
    final shared = _sharedStrings(doc('xl/sharedStrings.xml'));
    final styles = _Styles.of(doc('xl/styles.xml'));
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

  static List<String> _sharedStrings(XmlDocument? doc) => [
    for (final si in doc?.findAllElements('si') ?? const <XmlElement>[])
      si.findAllElements('t').map((t) => t.innerText).join(),
  ];

  static XlsxSheet _sheet(
    String name,
    XmlDocument xml,
    List<String> shared,
    _Styles styles,
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
        if (cell.text.isEmpty) continue;
        (cells[rowIndex] ??= {})[colIndex] = cell;
        if (colIndex > maxCol) maxCol = colIndex;
      }
    }
    if (cells.isEmpty) {
      return XlsxSheet(name: name, rows: const [], columnCount: 0);
    }
    final first = cells.keys.reduce((a, b) => a < b ? a : b);
    final last = cells.keys.reduce((a, b) => a > b ? a : b);
    return XlsxSheet(
      name: name,
      columnCount: maxCol + 1,
      rows: [
        for (var r = first; r <= last; r++)
          [
            for (var col = 0; col <= maxCol; col++)
              cells[r]?[col] ?? XlsxCell.empty,
          ],
      ],
    );
  }

  static XlsxCell _cell(XmlElement c, List<String> shared, _Style style) {
    final type = c.getAttribute('t');
    final raw = c.getElement('v')?.innerText;
    switch (type) {
      case 's':
        final index = int.tryParse(raw ?? '');
        final text = index != null && index < shared.length
            ? shared[index]
            : '';
        return XlsxCell(text, bold: style.bold);
      case 'inlineStr':
        final text = c.findAllElements('t').map((t) => t.innerText).join();
        return XlsxCell(text, bold: style.bold);
      case 'str':
      case 'e':
        return XlsxCell(raw ?? '', bold: style.bold);
      case 'b':
        return XlsxCell(raw == '1' ? 'VRAI' : 'FAUX', bold: style.bold);
      default:
        final value = num.tryParse(raw ?? '');
        if (value == null) return XlsxCell(raw ?? '', bold: style.bold);
        return XlsxCell(
          style.format(value),
          bold: style.bold,
          numeric: !style.isDate,
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

class _Style {
  final bool bold;
  final String? numberFormat;

  const _Style({this.bold = false, this.numberFormat});

  /// Une date Excel : un nombre de jours depuis le 30/12/1899.
  bool get isDate {
    final code = numberFormat;
    if (code == null) return false;
    final unquoted = code.replaceAll(RegExp(r'"[^"]*"'), '').toLowerCase();
    return unquoted.contains('d') && unquoted.contains('m') ||
        unquoted.contains('yy');
  }

  String format(num value) {
    if (isDate) {
      final date = DateTime.utc(
        1899,
        12,
        30,
      ).add(Duration(days: value.floor()));
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(date.day)}/${two(date.month)}/${date.year}';
    }
    final code = numberFormat ?? '';
    // Le premier segment (valeurs positives) et son suffixe entre guillemets :
    // `#,##0" FC"` → « 3 450 000 FC ».
    final positive = code.split(';').first;
    final suffix = RegExp(r'"([^"]*)"\s*$').firstMatch(positive)?.group(1);
    final decimals =
        RegExp(r'\.(0+)').firstMatch(positive)?.group(1)?.length ??
        (value == value.roundToDouble() ? 0 : 2);
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    final number = parts.length > 1 ? '$grouped,${parts[1]}' : grouped;
    return '${value < 0 ? '−' : ''}$number${suffix ?? ''}';
  }
}

class _Styles {
  final List<_Style> xfs;

  const _Styles(this.xfs);

  _Style at(int index) => index < xfs.length ? xfs[index] : const _Style();

  static const Map<int, String> _builtIn = {
    1: '0',
    2: '0.00',
    3: '#,##0',
    4: '#,##0.00',
    14: 'dd/mm/yyyy',
    15: 'd-mmm-yy',
    16: 'd-mmm',
    17: 'mmm-yy',
    22: 'm/d/yy h:mm',
  };

  static _Styles of(XmlDocument? doc) {
    if (doc == null) return const _Styles([]);
    final formats = <int, String>{
      ..._builtIn,
      for (final f in doc.findAllElements('numFmt'))
        int.tryParse(f.getAttribute('numFmtId') ?? '') ?? -1:
            f.getAttribute('formatCode') ?? '',
    };
    final fonts = [
      for (final font
          in doc.findAllElements('fonts').firstOrNull?.findElements('font') ??
              const <XmlElement>[])
        font.getElement('b') != null,
    ];
    final cellXfs = doc.findAllElements('cellXfs').firstOrNull;
    return _Styles([
      for (final xf in cellXfs?.findElements('xf') ?? const <XmlElement>[])
        _Style(
          bold: () {
            final id = int.tryParse(xf.getAttribute('fontId') ?? '') ?? 0;
            return id < fonts.length && fonts[id];
          }(),
          numberFormat:
              formats[int.tryParse(xf.getAttribute('numFmtId') ?? '') ?? 0],
        ),
    ]);
  }
}
