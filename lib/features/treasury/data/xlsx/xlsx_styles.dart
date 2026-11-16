import 'package:xml/xml.dart';

/// L'alignement horizontal d'une cellule, tel que la feuille le demande.
enum XlsxAlign { start, center, end }

/// Le style d'une cellule (`cellXfs`) : graisse, couleurs, alignement et
/// format de nombre.
class XlsxStyle {
  final bool bold;

  /// Couleurs en ARGB (`FF0E2D42`), `null` si la feuille n'en pose pas.
  final int? fill;
  final int? ink;
  final XlsxAlign? align;
  final String? numberFormat;

  const XlsxStyle({
    this.bold = false,
    this.fill,
    this.ink,
    this.align,
    this.numberFormat,
  });

  String get _unquoted =>
      (numberFormat ?? '').replaceAll(RegExp(r'"[^"]*"'), '').toLowerCase();

  /// Une date : un nombre de jours depuis le 30/12/1899.
  bool get isDate {
    final code = _unquoted;
    return code.contains('d') && code.contains('m') || code.contains('yy');
  }

  /// Une heure : la fraction du jour (0,33 = 08:00).
  bool get isTime => _unquoted.contains('h') || _unquoted.contains('ss');

  bool get isTemporal => isDate || isTime;

  String format(num value) {
    String two(int v) => v.toString().padLeft(2, '0');
    if (isTemporal) {
      final instant = DateTime.utc(
        1899,
        12,
        30,
      ).add(Duration(seconds: (value * 86400).round()));
      final date = '${two(instant.day)}/${two(instant.month)}/${instant.year}';
      final time = '${two(instant.hour)}:${two(instant.minute)}';
      if (isDate && isTime) return '$date $time';
      return isDate ? date : time;
    }
    // Le premier segment (valeurs positives) et son suffixe entre guillemets :
    // `#,##0" FC"` → « 3 450 000 FC ».
    final positive = (numberFormat ?? '').split(';').first;
    final suffix = RegExp(r'"([^"]*)"\s*$').firstMatch(positive)?.group(1);
    final decimals =
        RegExp(r'\.(0+)').firstMatch(positive)?.group(1)?.length ??
        (value == value.roundToDouble() ? 0 : 2);
    final parts = value.abs().toStringAsFixed(decimals).split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    final number = parts.length > 1 ? '$grouped,${parts[1]}' : grouped;
    return '${value < 0 ? '−' : ''}$number${suffix ?? ''}';
  }
}

/// Les styles d'un classeur (`xl/styles.xml`).
class XlsxStyles {
  final List<XlsxStyle> xfs;

  const XlsxStyles(this.xfs);

  XlsxStyle at(int index) =>
      index < xfs.length ? xfs[index] : const XlsxStyle();

  static const Map<int, String> _builtIn = {
    1: '0',
    2: '0.00',
    3: '#,##0',
    4: '#,##0.00',
    14: 'dd/mm/yyyy',
    15: 'd-mmm-yy',
    16: 'd-mmm',
    17: 'mmm-yy',
    18: 'h:mm AM/PM',
    20: 'h:mm',
    21: 'h:mm:ss',
    22: 'm/d/yy h:mm',
    45: 'mm:ss',
    46: '[h]:mm:ss',
  };

  static int? _rgb(XmlElement? color) {
    final rgb = color?.getAttribute('rgb');
    if (rgb == null) return null;
    final value = int.tryParse(rgb, radix: 16);
    if (value == null) return null;
    // `RRGGBB` sans alpha : opaque.
    return rgb.length <= 6 ? 0xFF000000 | value : value;
  }

  static XlsxStyles of(XmlDocument? doc) {
    if (doc == null) return const XlsxStyles([]);
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
        (
          bold: font.getElement('b') != null,
          ink: _rgb(font.getElement('color')),
        ),
    ];
    final fills = [
      for (final fill
          in doc.findAllElements('fills').firstOrNull?.findElements('fill') ??
              const <XmlElement>[])
        () {
          final pattern = fill.getElement('patternFill');
          if (pattern?.getAttribute('patternType') != 'solid') return null;
          return _rgb(pattern?.getElement('fgColor'));
        }(),
    ];
    int index(XmlElement xf, String name) =>
        int.tryParse(xf.getAttribute(name) ?? '') ?? 0;
    final cellXfs = doc.findAllElements('cellXfs').firstOrNull;
    return XlsxStyles([
      for (final xf in cellXfs?.findElements('xf') ?? const <XmlElement>[])
        () {
          final font = index(xf, 'fontId') < fonts.length
              ? fonts[index(xf, 'fontId')]
              : null;
          final horizontal = xf
              .getElement('alignment')
              ?.getAttribute('horizontal');
          return XlsxStyle(
            bold: font?.bold ?? false,
            ink: font?.ink,
            fill: index(xf, 'fillId') < fills.length
                ? fills[index(xf, 'fillId')]
                : null,
            align: switch (horizontal) {
              'center' || 'centerContinuous' => XlsxAlign.center,
              'right' => XlsxAlign.end,
              'left' => XlsxAlign.start,
              _ => null,
            },
            numberFormat: formats[index(xf, 'numFmtId')],
          );
        }(),
    ]);
  }
}
