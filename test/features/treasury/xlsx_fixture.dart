import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Un petit classeur `.xlsx` construit à la main : deux feuilles (« RJ-20261022 »
/// et « Données »), des textes partagés, une ligne en gras, des montants au
/// format `#,##0" FC"` et une date.
Uint8List cashReportXlsx() {
  final files = <String, String>{
    'xl/workbook.xml':
        '<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
        '<sheet name="RJ-20261022" sheetId="1" r:id="rId1"/>'
        '<sheet name="Données" sheetId="2" r:id="rId2"/>'
        '</sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships>'
        '<Relationship Id="rId1" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Target="worksheets/sheet2.xml"/>'
        '</Relationships>',
    'xl/sharedStrings.xml':
        '<sst><si><t>Caisse</t></si><si><t>Caisse CDF</t></si>'
        '<si><r><t>Total </t></r><r><t>encaissé</t></r></si></sst>',
    'xl/styles.xml':
        '<styleSheet><numFmts><numFmt numFmtId="164" formatCode="#,##0&quot; FC&quot;"/></numFmts>'
        '<fonts><font/><font><b/></font></fonts>'
        '<fills><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FF0E2D42"/></patternFill></fill></fills>'
        '<cellXfs><xf fontId="0" numFmtId="0"/><xf fontId="1" numFmtId="0"/>'
        '<xf fontId="0" numFmtId="164"/><xf fontId="0" numFmtId="14"/>'
        '<xf fontId="0" numFmtId="20"/><xf fontId="1" fillId="2" numFmtId="0"/></cellXfs>'
        '</styleSheet>',
    'xl/worksheets/sheet1.xml':
        '<worksheet><sheetData>'
        '<cols><col min="1" max="1" width="2"/><col min="2" max="2" width="20"/></cols>'
        '<row r="2"><c r="B2" t="s" s="5"><v>0</v></c></row>'
        '<row r="3"><c r="B3" t="s"><v>1</v></c><c r="D3" s="2"><v>3450000</v></c></row>'
        '<row r="4"><c r="B4" t="s" s="1"><v>2</v></c><c r="D4" s="2"><v>-5000</v></c></row>'
        '<row r="5"><c r="C5" s="4"><v>0.34375</v></c></row>'
        '</sheetData><mergeCells><mergeCell ref="B2:D2"/></mergeCells></worksheet>',
    'xl/worksheets/sheet2.xml':
        '<worksheet><sheetData>'
        '<row r="1"><c r="A1" t="inlineStr"><is><t>Journée</t></is></c></row>'
        '<row r="2"><c r="A2" s="3"><v>46317</v></c></row>'
        '</sheetData></worksheet>',
  };
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
