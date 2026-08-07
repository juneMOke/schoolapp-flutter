import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/documents/data/ticket/ticket_block_geometry.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Rend le reçu provisoire en PDF **80 mm** — sortie de repli de RG-012-10,
/// quand aucune imprimante thermique n'est appairée.
///
/// Trois contraintes du paquet `pdf` dictent la forme :
///
/// 1. **`pw.Page`, jamais `pw.MultiPage`, sur un rouleau.** Ce dernier asserte
///    contre une hauteur infinie, que `PdfPageFormat.roll80` porte par
///    définition. Le corollaire est assumé : aucune pagination — une répartition
///    très longue produit une page unique très haute, ce qui est le comportement
///    naturel d'un rouleau. Sur une **feuille**, la hauteur est finie : la
///    contrainte tombe et `pw.MultiPage` redevient le bon outil.
/// 2. **Police intégrée `courier`.** Le gabarit raisonne en colonnes de
///    caractères : seule une chasse fixe garantit l'alignement. `courier` est
///    embarquée dans le format PDF (encodage WinAnsi, accents français couverts)
///    — aucun asset à déclarer, aucun chargement à faire.
/// 3. Le contenu vient **entièrement** de [TicketTextLayout]. Ce renderer ne
///    décide d'aucune mise en page : c'est ce qui rend le critère d'acceptation
///    de l'ADR — même contenu textuel entre les deux sorties — vérifiable par
///    une simple comparaison de chaînes.
///
/// ## Deux supports, un seul bloc (AM-11)
///
/// `Printing.layoutPdf` remet le document au **spouleur du système**, qui
/// applique le format papier choisi par l'utilisateur : une page `roll80`
/// remise à une imprimante de bureau ressort **étirée sur A4**. Un filet qui
/// sort étiré n'est pas un filet.
///
/// D'où deux chemins, un seul gabarit :
///
/// * **rouleau** (hauteur infinie) → une page unique de 80 mm de large ;
/// * **feuille** (hauteur finie) → le **même bloc de 80 mm** posé en haut à
///   gauche de la zone imprimable, le reste de la feuille laissé vide. S'il
///   reste du papier autour du bloc (cf. `hasPaperToCut`), un cadre de découpe
///   l'entoure : verticales pleines, horizontales pointillées.
///
/// La largeur du bloc et le corps de texte étant identiques dans les deux cas,
/// la sortie feuille est le ticket **à l'échelle 1** — et la propriété centrale
/// de D-4 (un ticket de 8 cm ne peut pas se confondre avec un reçu A4 scellé)
/// reste entière : seule la **feuille** change.
///
/// ⚠️ **Le corps de texte est CALCULÉ, jamais choisi.** Une taille posée à la
/// main faisait déborder chaque ligne pleine largeur : 48 caractères de Courier
/// à 7,6 pt occupent 218,9 pt alors que le rouleau n'en offre que 198,4 utiles.
/// `pw.Text` repliait alors silencieusement la ligne, et le papier remis au
/// parent affichait « Montant reçu … 25 » puis « 000,00 CDF » en dessous. Le
/// gabarit texte, lui, était parfaitement valide — aucun test de mise en page ne
/// pouvait voir le défaut, parce qu'il est **typographique**, pas textuel.
abstract final class PdfTicketRenderer {
  /// Le rouleau thermique 80 mm, format par défaut du rendu.
  static const PdfPageFormat pageFormat = TicketBlockGeometry.rollFormat;

  /// Nombre de colonnes du gabarit.
  static const int columns = TicketBlockGeometry.columns;

  /// Plafond de pagination de `MultiPage`.
  ///
  /// À ne pas surestimer : le compteur du paquet mesure les pages
  /// **consécutives produites par un même enfant**, pas le total. Le ticket
  /// posant un enfant par ligne, il ne se déclenchera jamais ici — le nombre de
  /// feuilles est borné par la longueur du ticket, rien d'autre. La valeur n'est
  /// relevée que pour ne pas hériter d'un plafond de 20 qui, lui, pourrait
  /// mordre en débogage.
  static const int _maxSheetPages = 40;

  /// Trait de découpe : gris et fin, pour qu'il guide les ciseaux sans jamais
  /// se lire comme une partie du ticket.
  static const double _cutLineWidth = 0.4;
  static const List<num> _cutPattern = <num>[3, 3];
  static const PdfColor _cutColor = PdfColors.grey500;

  /// Blanc de respiration entre le trait de découpe et la première ligne.
  static const double _cutGap = 3;

  /// [format] décide du support : hauteur infinie → rouleau, hauteur finie →
  /// feuille. [cutNotice] n'apparaît que sur une feuille, sous le trait de
  /// découpe : il appartient au **support**, jamais au ticket — l'ajouter au
  /// gabarit casserait le critère « même contenu textuel entre les deux
  /// sorties ».
  static Future<Uint8List> render(
    TicketReceiptModel model, {
    PdfPageFormat format = pageFormat,
    String? cutNotice,
  }) async {
    final lines = TicketTextLayout.render(model, columns: columns);
    final document = pw.Document();

    if (format.height.isInfinite) {
      _addRollPage(document, lines, format);
    } else {
      _addSheetPages(document, lines, format, cutNotice);
    }

    return document.save();
  }

  // ── Rouleau ────────────────────────────────────────────────────────────────

  static void _addRollPage(
    pw.Document document,
    List<String> lines,
    PdfPageFormat format,
  ) {
    final style = _textStyle(
      TicketBlockGeometry.fontSizeFor(TicketBlockGeometry.textWidthFor(format)),
    );

    document.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [for (final line in lines) _line(line, style)],
        ),
      ),
    );
  }

  // ── Feuille ────────────────────────────────────────────────────────────────

  static void _addSheetPages(
    pw.Document document,
    List<String> lines,
    PdfPageFormat format,
    String? cutNotice,
  ) {
    final block = TicketBlockGeometry.blockWidthFor(format);
    final textWidth = TicketBlockGeometry.textWidthFor(format);
    final style = _textStyle(TicketBlockGeometry.fontSizeFor(textWidth));
    final padding = (block - textWidth) / 2;
    final framed = TicketBlockGeometry.hasPaperToCut(format);
    final notice = framed ? cutNotice?.trim() : null;

    pw.Widget guided(pw.Widget child) => framed ? _sideCutGuides(child) : child;

    document.addPage(
      pw.MultiPage(
        maxPages: _maxSheetPages,
        pageFormat: format,
        margin: TicketBlockGeometry.sheetMarginsFor(format),
        build: (context) => [
          if (framed) _horizontalCutGuide(block),
          if (framed) guided(pw.SizedBox(width: block, height: _cutGap)),
          for (final line in lines)
            guided(
              // La marge intérieure est posée des DEUX côtés : la boîte du
              // `Padding` mesure alors exactement `block`, sans dépendre du fait
              // qu'il s'étire ou non jusqu'à sa contrainte — c'est cette boîte
              // que les verticales suivent.
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: padding),
                child: pw.SizedBox(width: textWidth, child: _line(line, style)),
              ),
            ),
          // Fermeture du cadre en UN seul enfant : trois enfants indépendants
          // se faisaient repousser séparément, et une feuille entière pouvait
          // ne porter que la consigne de découpe — un ordre de découper un
          // cadre absent. Groupés, ils basculent ensemble ou pas du tout.
          if (framed) _sheetFooter(block, padding, style, notice),
        ],
      ),
    );
  }

  /// Le bas du cadre : blanc, trait de découpe, puis la consigne.
  static pw.Widget _sheetFooter(
    double block,
    double padding,
    pw.TextStyle style,
    String? notice,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      _sideCutGuides(pw.SizedBox(width: block, height: _cutGap)),
      _horizontalCutGuide(block),
      // Sous le trait bas : la consigne part avec la chute, jamais avec le
      // ticket remis au parent.
      if (notice != null && notice.isNotEmpty)
        pw.Padding(
          padding: pw.EdgeInsets.only(top: _cutGap, left: padding),
          child: pw.Text(
            notice,
            style: style.copyWith(
              fontSize: style.fontSize! * 0.9,
              color: _cutColor,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
    ],
  );

  /// Greffe les deux verticales de découpe sur les bords de [child].
  ///
  /// Elles sont peintes **ligne à ligne** plutôt qu'en fond de page : un fond ne
  /// connaît pas la hauteur du ticket et courrait jusqu'au bas de la feuille,
  /// suggérant de découper 26 cm de papier pour un ticket de 9 cm. Ici le cadre
  /// s'arrête exactement où le ticket s'arrête, sur chaque page.
  ///
  /// Le trait est **plein** et non pointillé : redémarré à chaque ligne, un
  /// pointillé remettrait sa phase à zéro toutes les 8 pt et donnerait un bord
  /// haché. Les horizontales, elles, sont tracées d'un seul trait — elles
  /// peuvent rester pointillées.
  static pw.Widget _sideCutGuides(pw.Widget child) => pw.CustomPaint(
    painter: (canvas, size) {
      _stroke(canvas, 0, 0, 0, size.y);
      _stroke(canvas, size.x, 0, size.x, size.y);
    },
    child: child,
  );

  /// Une horizontale pointillée large de tout le bloc.
  static pw.Widget _horizontalCutGuide(double block) => pw.CustomPaint(
    size: PdfPoint(block, _cutLineWidth),
    painter: (canvas, size) => _strokeDashed(canvas, 0, 0, size.x, 0),
  );

  static void _strokeDashed(
    PdfGraphics canvas,
    double fromX,
    double fromY,
    double toX,
    double toY,
  ) => _stroke(canvas, fromX, fromY, toX, toY, dashed: true);

  /// `saveContext`/`restoreContext` encadrent systématiquement le tracé : sans
  /// eux, la largeur de trait, la couleur et surtout le motif de pointillés
  /// fuiraient sur tout ce qui est peint ensuite.
  static void _stroke(
    PdfGraphics canvas,
    double fromX,
    double fromY,
    double toX,
    double toY, {
    bool dashed = false,
  }) {
    canvas
      ..saveContext()
      ..setLineWidth(_cutLineWidth)
      ..setStrokeColor(_cutColor);
    if (dashed) canvas.setLineDashPattern(_cutPattern);
    canvas
      ..moveTo(fromX, fromY)
      ..lineTo(toX, toY)
      ..strokePath()
      ..restoreContext();
  }

  // ── Communs ────────────────────────────────────────────────────────────────

  static pw.TextStyle _textStyle(double size) =>
      pw.TextStyle(font: pw.Font.courier(), fontSize: size);

  static pw.Widget _line(String line, pw.TextStyle style) {
    // Une ligne vide doit être un blanc de hauteur NON NULLE. La matérialiser
    // par une espace ne suffisait pas : le moteur de texte découpe sur les
    // espaces, ne trouve aucun mot, n'ajoute aucune ligne et rend une boîte de
    // hauteur zéro. Le blanc de respiration du gabarit — celui qui sépare le
    // montant reçu de la répartition — n'existait donc pas sur le papier.
    if (line.isEmpty) return pw.SizedBox(height: style.fontSize);
    return _text(line, style);
  }

  static pw.Widget _text(String line, pw.TextStyle style) => pw.Text(
    line,
    style: style,
    // Filet de sécurité : si une ligne dépassait malgré le calcul, mieux vaut
    // la tronquer visiblement que la replier en silence — un repli déplace un
    // montant sur la ligne suivante sans que rien ne le signale.
    maxLines: 1,
    overflow: pw.TextOverflow.clip,
  );
}
