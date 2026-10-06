import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_fonts.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/copie_options.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_duree.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la copie imprime d'une évaluation.
class SujetCopieContent {
  final String brancheNom;
  final String classroomName;
  final String titre;

  /// Date déjà mise en forme dans la langue de l'écran.
  final String dateLabel;
  final double maxPoints;
  final EvaluationSujet sujet;

  const SujetCopieContent({
    required this.brancheNom,
    required this.classroomName,
    required this.titre,
    required this.dateLabel,
    required this.maxPoints,
    required this.sujet,
  });
}

/// **La feuille de copie** (spec S8), rendue sur la tablette : branche —
/// classe, titre, date · durée · « Noté sur », lignes nom / note, « Au
/// programme », consignes, puis les questions avec trois lignes de réponse —
/// ou l'encadré du corrigé quand l'option « Réponses » est cochée.
///
/// Construite en `pw.Document`, jamais capturée de l'écran : le texte reste
/// sélectionnable et imprimable sans réseau. Le serveur rend sa propre version
/// pour les parents ; les deux partent de la même feuille.
abstract final class SujetCopiePdf {
  static const PdfColor _ink = PdfColor.fromInt(0xFF2C2A26);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5C5852);
  static const PdfColor _accent = PdfColor.fromInt(0xFFB85C2C);
  static const PdfColor _rule = PdfColor.fromInt(0xFFC9C3B0);
  static const PdfColor _answerSoft = PdfColor.fromInt(0xFFF3F8F4);
  static const PdfColor _answerBorder = PdfColor.fromInt(0xFFCFE0D4);
  static const PdfColor _answerInk = PdfColor.fromInt(0xFF3D6B4A);

  static const double _titleSize = 26;
  static const double _bodySize = 11;
  static const double _smallSize = 9;
  static const int _answerLines = 3;
  static const double _answerLineGap = 22;

  static Future<Uint8List> build({
    required SujetCopieContent content,
    required CopieOptions options,
    required AppLocalizations l10n,
    required SujetCopieFonts fonts,
  }) async {
    final document = pw.Document(title: content.titre);
    final theme = pw.ThemeData.withFont(
      base: fonts.body,
      bold: fonts.bodyBold,
      italic: fonts.italic,
    );
    document.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 18 * PdfPageFormat.mm,
          marginBottom: 18 * PdfPageFormat.mm,
          marginLeft: 16 * PdfPageFormat.mm,
          marginRight: 16 * PdfPageFormat.mm,
        ),
        build: (_) => [
          ..._header(content, options, l10n, fonts),
          if (options.programme && content.sujet.cadre.programme.isNotEmpty)
            ..._programme(content.sujet.cadre.programme, l10n, fonts),
          if (options.consignes && content.sujet.cadre.consignes != null)
            _consignes(content.sujet.cadre.consignes!, fonts),
          pw.SizedBox(height: 12),
          for (final (i, q) in content.sujet.questions.indexed)
            _question(i + 1, q, options, l10n),
        ],
      ),
    );
    return document.save();
  }

  static List<pw.Widget> _header(
    SujetCopieContent content,
    CopieOptions options,
    AppLocalizations l10n,
    SujetCopieFonts fonts,
  ) {
    final duree = content.sujet.cadre.dureeMinutes;
    final meta = [
      content.dateLabel,
      if (options.duree && duree != null)
        l10n.copieSheetDuree(formatDuree(l10n, duree)),
      if (options.points)
        l10n.copieSheetNotedOn(formatPoints(content.maxPoints)),
    ].join(' · ');
    return [
      pw.Text(
        '${content.brancheNom} — ${content.classroomName}'.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: _smallSize,
          letterSpacing: 1,
          color: _muted,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        content.titre,
        style: pw.TextStyle(
          font: fonts.title,
          fontSize: _titleSize,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        meta,
        style: const pw.TextStyle(fontSize: _bodySize, color: _muted),
      ),
      pw.SizedBox(height: 14),
      pw.Row(
        children: [
          pw.Expanded(flex: 3, child: _fillLine(l10n.copieSheetName)),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _fillLine(
              l10n.copieSheetGrade(formatPoints(content.maxPoints)),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 14),
    ];
  }

  static pw.Widget _fillLine(String label) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _rule)),
    ),
    child: pw.Text(label, style: const pw.TextStyle(fontSize: _bodySize)),
  );

  static List<pw.Widget> _programme(
    List<String> lines,
    AppLocalizations l10n,
    SujetCopieFonts fonts,
  ) => [
    pw.Text(
      l10n.sujetProgrammeLabel,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: _bodySize),
    ),
    pw.SizedBox(height: 4),
    for (final (i, line) in lines.indexed)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 18,
              child: pw.Text(
                '${i + 1}',
                style: pw.TextStyle(font: fonts.title, color: _accent),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: _bodySize),
              ),
            ),
          ],
        ),
      ),
    pw.SizedBox(height: 8),
  ];

  static pw.Widget _consignes(String text, SujetCopieFonts fonts) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: fonts.italic,
        fontSize: _bodySize,
        color: _muted,
      ),
    ),
  );

  static pw.Widget _question(
    int number,
    SujetQuestion question,
    CopieOptions options,
    AppLocalizations l10n,
  ) {
    final points = question.points;
    final answer = question.reponseAttendue;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$number. ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: question.enonce),
                if (options.points && points != null)
                  pw.TextSpan(
                    text:
                        '  ${l10n.copieSheetQuestionPoints(formatPoints(points))}',
                    style: const pw.TextStyle(color: _muted),
                  ),
              ],
              style: const pw.TextStyle(fontSize: _bodySize, color: _ink),
            ),
          ),
          pw.SizedBox(height: 6),
          if (options.reponses && answer != null)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _answerSoft,
                border: pw.Border.all(color: _answerBorder),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                l10n.copieSheetCorrige(answer),
                style: const pw.TextStyle(
                  fontSize: _bodySize,
                  color: _answerInk,
                ),
              ),
            )
          else
            for (var line = 0; line < _answerLines; line++)
              pw.Container(
                height: _answerLineGap,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _rule)),
                ),
              ),
        ],
      ),
    );
  }
}
