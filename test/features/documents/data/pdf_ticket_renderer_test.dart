import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/ticket_block_geometry.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalBanner: 'Provisoire',
  referenceLabel: 'Réf.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice: 'Conservez ce ticket.',
);

TicketReceiptModel _model({int allocationCount = 2}) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  schoolMunicipality: 'Ngaliema',
  studentFullName: 'Mbala Kasa Amina',
  matriculationNumber: 'MAT-0042',
  classroomName: '5e primaire A',
  provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
  paidAt: DateTime(2026, 8, 4, 14, 7),
  cashierFullName: 'Jean Kabeya',
  amountReceived: MoneyBag.of(const [Money(150000, 'CDF')]),
  allocations: [
    for (var i = 0; i < allocationCount; i++)
      TicketAllocationLine(
        label: 'Poste $i',
        amountInCents: 1000 * (i + 1),
        currency: 'CDF',
      ),
  ],
  remainingBalance: MoneyBag.of(const [Money(250000, 'CDF')]),
  labels: _labels,
);

void main() {
  test('produit un PDF valide', () async {
    final bytes = await PdfTicketRenderer.render(_model());

    expect(bytes, isNotEmpty);
    // Signature %PDF — même garde que le mapper d'éditique côté serveur.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  // `pw.MultiPage` asserte contre une hauteur infinie, que `roll80` porte par
  // définition : ce test échouerait immédiatement si quelqu'un l'y substituait.
  test('rend un rouleau 80 mm de hauteur libre', () async {
    expect(PdfTicketRenderer.pageFormat.width, PdfPageFormat.roll80.width);
    expect(PdfTicketRenderer.pageFormat.height, double.infinity);

    await expectLater(PdfTicketRenderer.render(_model()), completes);
  });

  // Aucune pagination sur un rouleau : une répartition longue produit une page
  // unique très haute — comportement voulu, pas un débordement.
  test('encaisse une répartition très longue sans lever', () async {
    final bytes = await PdfTicketRenderer.render(_model(allocationCount: 120));

    expect(bytes, isNotEmpty);
  });

  test('deux rendus du même modèle produisent la même taille', () async {
    final model = _model();

    final first = await PdfTicketRenderer.render(model);
    final second = await PdfTicketRenderer.render(model);

    expect(first.length, second.length);
  });

  // LE défaut que les tests de gabarit ne pouvaient pas voir : il est
  // typographique, pas textuel. 48 caractères de Courier à une taille posée à
  // la main débordaient la largeur utile du rouleau, et `pw.Text` repliait la
  // ligne en silence — « Montant reçu … 25 » puis « 000 FC » en dessous, sur
  // le papier remis au parent.
  test('une ligne pleine largeur tient sur UNE ligne imprimée', () {
    const courierAdvance = 0.6;
    final lineWidth =
        TicketBlockGeometry.columns *
        courierAdvance *
        TicketBlockGeometry.fontSize;

    expect(
      lineWidth,
      lessThanOrEqualTo(TicketBlockGeometry.usableWidth),
      reason:
          'ligne de ${TicketBlockGeometry.columns} caractères = '
          '${lineWidth.toStringAsFixed(2)} pt pour '
          '${TicketBlockGeometry.usableWidth.toStringAsFixed(2)} pt utiles',
    );
  });

  // Le corps est DÉRIVÉ de la géométrie : changer le format ou le nombre de
  // colonnes ne doit pas pouvoir recréer le repli.
  test('le corps de texte reste lisible sur papier thermique', () {
    expect(TicketBlockGeometry.fontSize, greaterThan(6.0));
    expect(TicketBlockGeometry.fontSize, lessThan(9.0));
  });

  // Une ligne de 48 caractères produit une page d'UNE hauteur de ligne : deux
  // signeraient un repli.
  test('une ligne pleine largeur ne double pas la hauteur de page', () async {
    final short = await PdfTicketRenderer.render(_modelWithSingleLine('court'));
    final full = await PdfTicketRenderer.render(_modelWithSingleLine('X' * 40));

    // Tolérance large : on veut détecter un DOUBLEMENT, pas un octet près.
    expect(full.length, lessThan(short.length * 2));
  });

  // ── Repli imprimable sur feuille (AM-11) ───────────────────────────────────
  //
  // `Printing.layoutPdf` remet le document au spouleur, qui applique le papier
  // de l'utilisateur : une page `roll80` en ressortait ÉTIRÉE sur A4. Pire, sa
  // hauteur infinie n'atteint même pas le framework Android (aucun `MediaSize`
  // ne correspond → média par défaut). Le repli compose donc le même bloc de
  // 80 mm sur la feuille réellement annoncée.
  group('repli sur feuille', () {
    test('une feuille A4 produit une vraie page A4, pas un rouleau', () async {
      final bytes = await PdfTicketRenderer.render(
        _model(),
        format: PdfPageFormat.a4,
      );

      // La MediaBox est écrite en clair dans le dictionnaire de page : c'est la
      // preuve directe que le spouleur reçoit un A4 et n'a rien à mettre à
      // l'échelle.
      expect(_latin1(bytes), contains('MediaBox[0 0 595.27559 841.88976]'));
    });

    // LE critère d'acceptation d'AM-11 : « le repli sort à l'échelle 1, bloc de
    // 80 mm intact ». On l'éprouve sur le CORPS RÉELLEMENT ÉMIS dans le flux de
    // contenu, pas sur la formule de production rejouée — une assertion qui
    // recalcule ce qu'elle teste ne prouve rien.
    for (final media in _mediaAtScaleOne) {
      test('${media.nom} : bloc de 80 mm rendu à l\'échelle 1', () async {
        final bytes = await PdfTicketRenderer.render(
          _model(),
          format: media.format,
        );

        expect(
          TicketBlockGeometry.blockWidthFor(media.format),
          closeTo(80 * PdfPageFormat.mm, 0.001),
          reason: 'le bloc doit rester à la laize du rouleau',
        );
        expect(
          _emittedFontSizes(bytes),
          contains(closeTo(_rollFontSize, 0.0005)),
          reason: 'le corps émis doit être celui du rouleau',
        );
      });
    }

    // La correction qui a coûté le plus cher à trouver : une thermique 80 mm
    // annonce `getMinMargins() = 0`, donc 80 mm imprimables. Un plancher de
    // retrait appliqué inconditionnellement lui volait 10 mm — le ticket sortait
    // à 86 % de l'échelle sur l'imprimante même pour laquelle il est dessiné.
    test('une thermique 80 mm sans marge garde l\'échelle 1', () async {
      final bytes = await PdfTicketRenderer.render(_model(), format: _thermal);

      expect(
        _emittedFontSizes(bytes),
        contains(closeTo(_rollFontSize, 0.0005)),
      );
    });

    // Le corps émis ne doit JAMAIS dépasser celui du rouleau : un ticket
    // agrandi n'est plus un ticket de 80 mm. Une version antérieure imprimait
    // à 111 % sur un média de 88 mm.
    for (final media in _allMedia) {
      test('${media.nom} : le corps ne dépasse jamais celui du rouleau', () {
        expect(
          TicketBlockGeometry.fontSizeFor(
            TicketBlockGeometry.textWidthFor(media.format),
          ),
          lessThanOrEqualTo(_rollFontSize + 0.0005),
        );
      });
    }

    // Sur Android, les marges reçues dans `onLayout` sont les marges MINIMALES
    // de l'imprimante (`getMinMargins`), souvent nulles — notamment pour
    // « Enregistrer au format PDF ». Sans retrait, le ticket serait collé à
    // l'arête et le guide de découpe tracé sur le bord.
    test(
      'une feuille annoncée sans marge reçoit un retrait sur les 4 côtés',
      () {
        const flat = PdfPageFormat(595.27559, 841.88976);
        final margins = TicketBlockGeometry.sheetMarginsFor(flat);
        const floor = 5 * PdfPageFormat.mm;

        expect(margins.left, closeTo(floor, 0.001));
        expect(margins.top, closeTo(floor, 0.001));
        expect(margins.bottom, closeTo(floor, 0.001));
        // À droite, tout le papier en trop : la zone de contenu vaut le bloc.
        expect(
          flat.width - margins.left - margins.right,
          closeTo(TicketBlockGeometry.blockWidthFor(flat), 0.001),
        );
      },
    );

    // On ne fait qu'AUGMENTER la marge annoncée : jamais poser d'encre dans une
    // zone que l'imprimante déclare non imprimable.
    test('une marge annoncée plus large que le retrait est respectée', () {
      final margins = TicketBlockGeometry.sheetMarginsFor(PdfPageFormat.a4);

      expect(margins.left, closeTo(20 * PdfPageFormat.mm, 0.001));
      expect(margins.top, closeTo(20 * PdfPageFormat.mm, 0.001));
      expect(margins.bottom, closeTo(20 * PdfPageFormat.mm, 0.001));
    });

    // Support plus étroit que 80 mm : le bloc rétrécit plutôt que de déborder,
    // et le corps suit — un ticket réduit reste lisible, un ticket coupé au
    // bord ne l'est pas.
    test('un support étroit rétrécit le bloc sans faire déborder', () async {
      const narrow = PdfPageFormat(
        60 * PdfPageFormat.mm,
        100 * PdfPageFormat.mm,
        marginAll: 5 * PdfPageFormat.mm,
      );

      final block = TicketBlockGeometry.blockWidthFor(narrow);
      final textWidth = TicketBlockGeometry.textWidthFor(narrow);
      final lineWidth =
          TicketBlockGeometry.columns *
          0.6 *
          TicketBlockGeometry.fontSizeFor(textWidth);

      expect(block, lessThan(80 * PdfPageFormat.mm));
      expect(lineWidth, lessThanOrEqualTo(textWidth));
      await expectLater(
        PdfTicketRenderer.render(_model(), format: narrow),
        completes,
      );
    });

    // Sur une feuille la hauteur est finie : la contrainte qui interdit
    // `MultiPage` sur un rouleau tombe, et une répartition longue doit
    // PAGINER — jamais déborder en silence hors de la feuille.
    test('une répartition longue pagine sans rien perdre', () async {
      final bytes = await PdfTicketRenderer.render(
        _model(allocationCount: 120),
        format: PdfPageFormat.a4,
      );

      expect(
        'MediaBox'.allMatches(_latin1(bytes)).length,
        greaterThan(1),
        reason: 'une seule page signerait un débordement hors feuille',
      );
      // La preuve qui compte sur une pièce d'argent : les 120 postes sont
      // TOUS peints, pages confondues. Une pagination qui tronque produirait un
      // PDF valide, paginé, et amputé — indétectable autrement.
      expect('Poste'.allMatches(_visibleText(bytes)).length, 120);
    });

    // La consigne appartient au SUPPORT. On la fournit aux DEUX rendus : le
    // rouleau doit l'ignorer. Ne la passer qu'à la feuille prouverait seulement
    // qu'un texte non fourni n'apparaît pas.
    test('la consigne de découpe n\'entre jamais dans le ticket', () async {
      const notice = 'Decoupez le long du cadre.';
      final sheet = await PdfTicketRenderer.render(
        _model(),
        format: PdfPageFormat.a4,
        cutNotice: notice,
      );
      final roll = await PdfTicketRenderer.render(_model(), cutNotice: notice);

      expect(_visibleText(sheet), contains('Decoupez'));
      expect(_visibleText(roll), isNot(contains('Decoupez')));
    });

    // Le critère d'acceptation « même contenu textuel entre les deux sorties »
    // (AM-2), éprouvé sur les mots RÉELLEMENT peints — pas sur le fait que les
    // deux chemins appellent la même fonction.
    test('feuille et rouleau peignent exactement les mêmes mots', () async {
      final sheet = await PdfTicketRenderer.render(
        _model(),
        format: PdfPageFormat.a4,
        cutNotice: 'Decoupez le long du cadre.',
      );
      final roll = await PdfTicketRenderer.render(_model());

      final mots = _paintedWords(roll);
      expect(
        mots,
        isNotEmpty,
        reason: 'extraction du flux de contenu en échec',
      );
      // Le ticket entier, montants compris. Le franc s'imprime « FC » depuis
      // que la règle d'écriture se décide sur la devise ; c'est cette
      // abréviation-là qu'on cherche sur le papier.
      expect(mots, contains('FC'));
      expect(_paintedWords(sheet), containsAll(mots));
    });

    // Le cadre n'a de sens que s'il reste du papier à retirer. Sur un média qui
    // fait déjà la laize du ticket — une thermique — l'encadrer reviendrait à
    // demander de découper une bande déjà découpée.
    test(
      'le cadre de découpe n\'apparaît que s\'il y a du papier autour',
      () async {
        final sheet = await PdfTicketRenderer.render(
          _model(),
          format: PdfPageFormat.a4,
          cutNotice: 'Decoupez le long du cadre.',
        );
        final thermal = await PdfTicketRenderer.render(
          _model(),
          format: _thermal,
          cutNotice: 'Decoupez le long du cadre.',
        );

        expect(TicketBlockGeometry.hasPaperToCut(PdfPageFormat.a4), isTrue);
        expect(TicketBlockGeometry.hasPaperToCut(_thermal), isFalse);
        // `[3 3] 0 d` est le motif de pointillés des deux horizontales, `S` le
        // tracé des verticales : ni l'un ni l'autre ne doit sortir sur la laize.
        expect('[3 3] 0 d'.allMatches(_visibleText(sheet)).length, 2);
        expect(_visibleText(thermal), isNot(contains('[3 3] 0 d')));
        expect(_visibleText(thermal), isNot(contains('Decoupez')));
      },
    );

    // Bouclage de bout en bout du jeu de caractères : la police du ticket est
    // une base-14 Latin-1 qui SUPPRIME sans erreur ce qu'elle ne couvre pas.
    // « Institut Sacré-Cœur » — un nom d'établissement banal en RDC —
    // s'imprimait « Sacré-Cur ».
    test('la ligature arrive jusque dans le PDF, translittérée', () async {
      final bytes = await PdfTicketRenderer.render(
        _modelWithSingleLine('Sacré-Cœur'),
        format: PdfPageFormat.a4,
      );

      final peint = _visibleText(bytes);
      expect(peint, contains('SACR'));
      expect(peint, contains('COEUR'));
    });

    test('le rouleau reste rendu sans pagination', () async {
      final bytes = await PdfTicketRenderer.render(
        _model(allocationCount: 120),
      );

      expect('MediaBox'.allMatches(_latin1(bytes)).length, 1);
    });
  });
}

/// Un média 80 mm tel qu'un service d'impression thermique l'annonce : laize
/// pleine, marges minimales nulles, hauteur finie (aucun spouleur n'annonce
/// jamais une hauteur infinie).
const _thermal = PdfPageFormat(80 * PdfPageFormat.mm, 3276 * PdfPageFormat.mm);

typedef _Media = ({String nom, PdfPageFormat format});

/// Supports assez larges pour porter le bloc entier — l'échelle doit y valoir 1.
const List<_Media> _mediaAtScaleOne = [
  (nom: 'A4', format: PdfPageFormat.a4),
  (nom: 'A5', format: PdfPageFormat.a5),
  (nom: 'Letter', format: PdfPageFormat.letter),
  (nom: 'A4 sans marge', format: PdfPageFormat(595.27559, 841.88976)),
  // 88 × 125 mm : une `MediaSize` standard d'Android, juste plus large que le
  // bloc — c'est là qu'une version antérieure imprimait à 111 %.
  (
    nom: 'ISO_B7',
    format: PdfPageFormat(88 * PdfPageFormat.mm, 125 * PdfPageFormat.mm),
  ),
];

const List<_Media> _allMedia = [
  ..._mediaAtScaleOne,
  (nom: 'thermique 80 mm', format: _thermal),
  (
    nom: 'support de 60 mm',
    format: PdfPageFormat(
      60 * PdfPageFormat.mm,
      100 * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    ),
  ),
];

double get _rollFontSize => TicketBlockGeometry.fontSize;

/// Corps de police posés dans le flux de contenu (`/F1 6.75197 Tf`).
///
/// C'est la seule mesure qui échappe à la tautologie : elle lit ce que le PDF
/// porte, là où réassembler la formule de production ne testerait que soi-même.
List<double> _emittedFontSizes(Uint8List bytes) => RegExp(r'/F\d+ ([0-9.]+) Tf')
    .allMatches(_visibleText(bytes))
    .map((m) => double.parse(m.group(1)!))
    .toList();

/// Mots réellement peints, dans l'ordre — le moteur émet `[(mot)]TJ` par mot.
List<String> _paintedWords(Uint8List bytes) => RegExp(r'\[\((.*?)\)\]TJ')
    .allMatches(_visibleText(bytes))
    .map((m) => m.group(1)!)
    .where((word) => word.isNotEmpty)
    .toList();

String _latin1(Uint8List bytes) => String.fromCharCodes(bytes);

/// Texte réellement peint dans le document, flux de contenu décompressés.
///
/// `pw.Document` déflate ses flux : sans cette étape, chercher une chaîne dans
/// les octets bruts ne prouverait rien — ni sa présence, ni son absence.
///
/// ⚠️ Le moteur de texte du paquet dessine **un mot par opérateur** (`[(mot)]TJ`
/// précédé de son propre `Td`) : une ligne entière n'existe nulle part d'un
/// seul tenant. On cherche donc des mots, jamais des phrases.
String _visibleText(Uint8List bytes) {
  final raw = _latin1(bytes);
  final buffer = StringBuffer();

  var index = raw.indexOf('stream');
  while (index >= 0) {
    final end = raw.indexOf('endstream', index);
    if (end < 0) break;
    // Le mot-clé `stream` est suivi d'un saut de ligne, et `endstream` précédé
    // d'un autre : ni l'un ni l'autre n'appartient aux données déflatées, et
    // les laisser suffit à faire échouer l'inflation.
    var start = index + 'stream'.length;
    while (start < end && _isEol(raw.codeUnitAt(start))) {
      start++;
    }
    var stop = end;
    while (stop > start && _isEol(raw.codeUnitAt(stop - 1))) {
      stop--;
    }
    try {
      buffer.write(
        String.fromCharCodes(zlib.decode(bytes.sublist(start, stop).toList())),
      );
    } catch (_) {
      // Flux non déflaté (police, image) : sans intérêt ici.
    }
    index = raw.indexOf('stream', end + 'endstream'.length);
  }

  return buffer.toString();
}

bool _isEol(int code) => code == 13 || code == 10;

/// Modèle réduit à l'essentiel, pour isoler l'effet d'une seule ligne longue.
TicketReceiptModel _modelWithSingleLine(String studentName) =>
    TicketReceiptModel(
      schoolName: 'E',
      studentFullName: studentName,
      provisionalReference: 'PROV-1',
      paidAt: DateTime(2026, 8, 4, 14, 7),
      amountReceived: MoneyBag.of(const [Money(2500000000, 'CDF')]),
      labels: _labels,
    );
