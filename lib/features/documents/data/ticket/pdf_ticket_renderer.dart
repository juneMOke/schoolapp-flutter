import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Rend le reçu provisoire en PDF **80 mm** — sortie de repli de RG-012-10,
/// quand aucune imprimante thermique n'est appairée.
///
/// Trois contraintes du paquet `pdf` dictent la forme :
///
/// 1. **`pw.Page`, jamais `pw.MultiPage`.** Ce dernier asserte contre une
///    hauteur infinie, que `PdfPageFormat.roll80` porte par définition. Le
///    corollaire est assumé : aucune pagination — une répartition très longue
///    produit une page unique très haute, ce qui est le comportement naturel
///    d'un rouleau.
/// 2. **Police intégrée `courier`.** Le gabarit raisonne en colonnes de
///    caractères : seule une chasse fixe garantit l'alignement. `courier` est
///    embarquée dans le format PDF (encodage WinAnsi, accents français couverts)
///    — aucun asset à déclarer, aucun chargement à faire.
/// 3. Le contenu vient **entièrement** de [TicketTextLayout]. Ce renderer ne
///    décide d'aucune mise en page : c'est ce qui rend le critère d'acceptation
///    de l'ADR — même contenu textuel entre les deux sorties — vérifiable par
///    une simple comparaison de chaînes.
///
/// ⚠️ **Le corps de texte est CALCULÉ, jamais choisi.** Une taille posée à la
/// main faisait déborder chaque ligne pleine largeur : 48 caractères de Courier
/// à 7,6 pt occupent 218,9 pt alors que le rouleau n'en offre que 198,4 utiles.
/// `pw.Text` repliait alors silencieusement la ligne, et le papier remis au
/// parent affichait « Montant reçu … 25 » puis « 000,00 CDF » en dessous. Le
/// gabarit texte, lui, était parfaitement valide — aucun test de mise en page ne
/// pouvait voir le défaut, parce qu'il est **typographique**, pas textuel.
abstract final class PdfTicketRenderer {
  /// Largeur d'un rouleau thermique 80 mm.
  static const PdfPageFormat pageFormat = PdfPageFormat.roll80;

  /// Nombre de colonnes du gabarit pour ce format.
  static const int columns = TicketTextLayout.defaultColumns;

  /// Chasse de Courier, en fraction du corps. Constante de la police (600/1000),
  /// pas un réglage.
  static const double _courierAdvance = 0.6;

  /// Marge de sécurité sur la largeur utile : une imprimante thermique ne pose
  /// jamais le trait exactement au bord, et un arrondi au dernier caractère
  /// suffirait à faire replier la ligne.
  static const double _safety = 0.98;

  /// Largeur réellement imprimable, marges de la page déduites.
  static double get usableWidth =>
      pageFormat.width - pageFormat.marginLeft - pageFormat.marginRight;

  /// Corps de texte garantissant que [columns] caractères tiennent sur UNE
  /// ligne. Dérivé de la géométrie du format, donc juste par construction :
  /// changer le format ou le nombre de colonnes ne peut plus créer de repli.
  static double get fontSize =>
      (usableWidth * _safety) / (columns * _courierAdvance);

  static Future<Uint8List> render(TicketReceiptModel model) async {
    final lines = TicketTextLayout.render(model, columns: columns);
    final document = pw.Document();
    final style = pw.TextStyle(font: pw.Font.courier(), fontSize: fontSize);

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            for (final line in lines)
              pw.Text(
                // Une ligne vide serait de hauteur nulle : on la matérialise
                // par une espace pour conserver la respiration du gabarit.
                line.isEmpty ? ' ' : line,
                style: style,
                // Filet de sécurité : si une ligne dépassait malgré le calcul,
                // mieux vaut la tronquer visiblement que la replier en silence —
                // un repli déplace un montant sur la ligne suivante sans que
                // rien ne le signale.
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
          ],
        ),
      ),
    );

    return document.save();
  }
}
