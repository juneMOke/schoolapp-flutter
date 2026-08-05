import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Géométrie du bloc de ticket 80 mm, sur rouleau comme sur feuille.
///
/// Séparée du rendu à dessein : **tout** ce qui décide d'une largeur, d'une
/// marge ou d'un corps de texte est ici, et rien n'y peint. C'est ce qui rend
/// l'invariant central d'AM-11 — « le repli sort à l'échelle 1, bloc de 80 mm
/// intact » — vérifiable par le calcul, support par support, sans rendre un
/// seul PDF.
///
/// ⚠️ **Le corps de texte est CALCULÉ, jamais choisi.** Une taille posée à la
/// main faisait déborder chaque ligne pleine largeur : 48 caractères de Courier
/// à 7,6 pt occupent 218,9 pt alors que le rouleau n'en offre que 198,4 utiles.
/// `pw.Text` repliait alors silencieusement la ligne, et le papier remis au
/// parent affichait « Montant reçu … 25 » puis « 000,00 CDF » en dessous. Le
/// gabarit texte, lui, était parfaitement valide — aucun test de mise en page ne
/// pouvait voir le défaut, parce qu'il est **typographique**, pas textuel.
abstract final class TicketBlockGeometry {
  /// Le rouleau thermique 80 mm — la référence dont tout le reste dérive.
  static const PdfPageFormat rollFormat = PdfPageFormat.roll80;

  /// Nombre de colonnes du gabarit.
  static const int columns = TicketTextLayout.defaultColumns;

  /// Largeur **hors tout** du bloc : la laize physique du rouleau. C'est la
  /// grandeur que le repli feuille doit préserver au millimètre.
  static const double blockWidth = 80 * PdfPageFormat.mm;

  /// Marge intérieure du bloc — exactement celle que `roll80` applique. Sans
  /// elle, le bloc posé sur une feuille n'aurait pas la même largeur de texte
  /// que le même bloc sorti du rouleau.
  static const double blockPadding = 5 * PdfPageFormat.mm;

  /// Chasse de Courier, en fraction du corps. Constante de la police (600/1000),
  /// pas un réglage.
  static const double _courierAdvance = 0.6;

  /// Marge de sécurité sur la largeur utile : une imprimante thermique ne pose
  /// jamais le trait exactement au bord, et un arrondi au dernier caractère
  /// suffirait à faire replier la ligne.
  static const double _safety = 0.98;

  /// Retrait de confort appliqué au bloc sur une feuille.
  ///
  /// Le spouleur Android annonce les marges **minimales** de l'imprimante
  /// (`PrintAttributes.getMinMargins`), qui valent souvent zéro — notamment pour
  /// la cible « Enregistrer au format PDF ». Poser le bloc à ras de l'arête
  /// donnerait un ticket collé au bord et un guide de découpe sur le bord.
  static const double _minSheetMargin = 5 * PdfPageFormat.mm;

  /// Sous ce reliquat de papier, la « chute » ne serait qu'un liseré : rien à
  /// découper, donc pas de cadre.
  static const double _cutMargin = 8 * PdfPageFormat.mm;

  // ── Largeurs ───────────────────────────────────────────────────────────────

  /// Largeur imprimable **annoncée** par le média, ses propres marges déduites.
  ///
  /// Chaque marge est bornée à un quart du support : un média déclarant des
  /// marges plus larges que sa feuille donnerait une zone négative, et
  /// `MultiPage` — qui recalcule la sienne depuis le format — lèverait avant
  /// d'avoir posé une ligne.
  static double announcedContentWidthFor(PdfPageFormat format) =>
      format.width -
      _boundedMargin(format.marginLeft, format.width) -
      _boundedMargin(format.marginRight, format.width);

  static double _boundedMargin(double margin, double side) =>
      math.min(margin, side / 4);

  /// Largeur hors tout que le bloc peut occuper sur la **feuille** [format].
  ///
  /// Vaut [blockWidth] dès que la zone imprimable est assez large — le cas de
  /// tous les formats de bureau. Un support plus étroit que 80 mm rétrécit le
  /// bloc plutôt que de le laisser déborder : un ticket réduit reste lisible, un
  /// ticket coupé au bord ne l'est pas.
  static double blockWidthFor(PdfPageFormat format) {
    final announced = announcedContentWidthFor(format);
    return announced < blockWidth ? announced : blockWidth;
  }

  /// Largeur de texte d'un **rouleau** : sa zone de contenu **est** la largeur
  /// de texte, les 5 mm de `roll80` étant déjà la marge intérieure du bloc.
  static double rollTextWidthFor(PdfPageFormat format) =>
      format.width - format.marginLeft - format.marginRight;

  /// Largeur réellement imprimable du rouleau 80 mm — la référence d'échelle.
  static double get usableWidth => rollTextWidthFor(rollFormat);

  /// Corps de texte du rouleau.
  static double get fontSize => fontSizeFor(usableWidth);

  /// Largeur de texte à l'intérieur du bloc posé sur la **feuille** [format].
  ///
  /// Toujours `bloc − 2 × marge intérieure`, jamais autre chose : sur un bloc
  /// entier cela redonne exactement la largeur du rouleau — c'est tout l'objet
  /// d'AM-11 — et sur un bloc rétréci cela reste **monotone**.
  ///
  /// ⚠️ Une version antérieure rendait le bloc entier quand il était rétréci,
  /// « puisque les marges du format tiennent déjà lieu de blanc de bord ».
  /// C'était faux et grave : entre 70 et 80 mm de zone imprimable — un média
  /// ISO_B7 — la largeur de texte DÉPASSAIT celle du rouleau, et le corps dérivé
  /// imprimait le ticket jusqu'à 111 % de l'échelle 1. L'invariant à tenir n'est
  /// pas « ça tient dans la page » mais « jamais plus large que le rouleau ».
  static double sheetTextWidthFor(PdfPageFormat format) {
    final block = blockWidthFor(format);
    // Plancher à la moitié du bloc : sous 20 mm, retirer 2 × 5 mm mangerait
    // l'essentiel du texte. Les deux branches se rejoignent exactement à 20 mm,
    // la fonction reste donc croissante et sans marche.
    return math.max(block - 2 * blockPadding, block / 2);
  }

  /// Largeur de texte réellement offerte par [format], quel que soit le support
  /// — le même aiguillage que le rendu.
  static double textWidthFor(PdfPageFormat format) => format.height.isInfinite
      ? rollTextWidthFor(format)
      : sheetTextWidthFor(format);

  /// Corps garantissant que [columns] caractères tiennent sur UNE ligne de
  /// [textWidth]. Dérivé de la géométrie, donc juste par construction : changer
  /// le format ou le nombre de colonnes ne peut plus créer de repli.
  static double fontSizeFor(double textWidth) =>
      (textWidth * _safety) / (columns * _courierAdvance);

  // ── Placement sur la feuille ───────────────────────────────────────────────

  /// Marges de page retenues pour une feuille.
  ///
  /// La zone de contenu vaut **exactement le bloc** : c'est elle que suivent les
  /// verticales de découpe et la contrainte de `MultiPage`.
  ///
  /// ⚠️ Le retrait de confort ne se prend que sur le papier **en trop**. Un
  /// plancher appliqué inconditionnellement volait 10 mm à un média qui fait
  /// justement 80 mm de laize — une thermique annonçant `getMinMargins() = 0` —
  /// et le ticket en sortait à 86 % de l'échelle 1 sur l'imprimante même pour
  /// laquelle il est dessiné.
  static pw.EdgeInsets sheetMarginsFor(PdfPageFormat format) {
    final block = blockWidthFor(format);
    final left = _boundedMargin(format.marginLeft, format.width);
    final spare = announcedContentWidthFor(format) - block;
    final inset = math.min(math.max(_minSheetMargin - left, 0), spare);

    double vertical(double margin) =>
        math.min(math.max(margin, _minSheetMargin), format.height / 4);

    return pw.EdgeInsets.fromLTRB(
      left + inset,
      vertical(format.marginTop),
      format.width - left - inset - block,
      vertical(format.marginBottom),
    );
  }

  /// Reste-t-il du papier **à retirer** autour du bloc sur [format] ?
  ///
  /// C'est la seule justification du cadre de découpe et de sa consigne. Sur une
  /// feuille de bureau, oui. Sur un rouleau **fini** — le cas d'une thermique
  /// 80 mm sélectionnée dans la boîte de dialogue système, qui passe par le
  /// chemin feuille puisque aucun spouleur n'annonce jamais une hauteur infinie
  /// — non : le ticket occupe déjà toute la laize, et l'encadrer reviendrait à
  /// demander au caissier de découper une bande qui est déjà découpée.
  static bool hasPaperToCut(PdfPageFormat format) =>
      !format.height.isInfinite &&
      announcedContentWidthFor(format) > blockWidthFor(format) + _cutMargin;
}
