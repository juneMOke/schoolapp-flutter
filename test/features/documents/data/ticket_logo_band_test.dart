import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// La bande de logo, hors du pivot texte, et son inversion de polarité.
///
/// ## Ce que ces tests assertent, et à quelle précision
///
/// La règle est celle que le chantier s'est donnée : **asserter au pixel ce qui
/// est CALCULÉ, large ce qui est MESURÉ.**
///
/// * La **géométrie** est calculée — 576 points font 72 octets, la hauteur est
///   celle de la bande — donc elle s'asserte exactement. Elle ne dépend d'aucun
///   rééchantillonneur.
/// * Le **taux d'encre** est mesuré, et il varie d'un dérivateur à l'autre : la
///   dérivation Python d'essai donne ~92,3 % de blanc là où celle du serveur en
///   donne ~91,6 %, pour la même figure. Une borne serrée autour d'une de ces
///   valeurs serait verte aujourd'hui et rouge au premier tirage réel, **pour
///   une raison qui n'est pas un défaut**. La fourchette est donc large : elle
///   dit « ça ressemble à un logo » et rien de plus.
///
/// Ce que la fourchette doit discriminer, c'est un **basculement** : une bande
/// versée sans inversion imprimerait ~92 % de sa surface au lieu de ~8 %. Un
/// seuil au milieu sépare parfaitement les deux et ne casse jamais.
const _escA0 = <int>[0x1B, 0x61, 0x00];
const _gsV0 = <int>[0x1D, 0x76, 0x30, 0x00];

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalMention: 'provisoire',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  derivedAmountPrefix: 'soit',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve',
  keepTicketNotice: 'Conservez ce ticket.',
);

final _model = TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  studentFullName: 'Mbala Kasa Amina',
  reference: 'PROV-A1B2C3',
  isProvisional: true,
  paidAt: DateTime(2026, 9, 8, 1, 35),
  tenders: TicketTenderLine.identityFrom(
    MoneyBag.of(const [Money(150000, 'CDF')]),
  ),
  labels: _labels,
);

/// Une bande 576×128 dont [inkRows] lignes du milieu sont entièrement encrées.
///
/// Convention PNG : les bits à **1 sont BLANCS**, l'encre est à 0. Avec 10
/// lignes sur 128, l'encre couvre ~7,8 % — l'ordre de grandeur d'un sceau.
TicketLogoBand _band({int width = 576, int height = 128, int inkRows = 10}) {
  final bytesPerRow = width ~/ 8;
  final bits = Uint8List(bytesPerRow * height)..fillRange(0, -1 + 1, 0);
  for (var i = 0; i < bits.length; i++) {
    bits[i] = 0xFF; // tout blanc
  }
  final start = (height - inkRows) ~/ 2;
  for (var y = start; y < start + inkRows; y++) {
    for (var b = 0; b < bytesPerRow; b++) {
      bits[y * bytesPerRow + b] = 0x00; // encre
    }
  }
  return TicketLogoBand(widthDots: width, heightDots: height, bits: bits);
}

/// Proportion de bits à 1 dans [bytes], en pourcentage.
double _onesPercent(List<int> bytes) {
  var ones = 0;
  for (final b in bytes) {
    ones += b.toRadixString(2).split('').where((c) => c == '1').length;
  }
  return 100 * ones / (bytes.length * 8);
}

/// Index du début de la commande raster, ou `-1`.
int _rasterStart(Uint8List bytes) {
  for (var i = 0; i + _gsV0.length <= bytes.length; i++) {
    var ok = true;
    for (var k = 0; k < _gsV0.length; k++) {
      if (bytes[i + k] != _gsV0[k]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

/// Contenu des flux du PDF, décompressé.
String _inflated(Uint8List bytes) {
  final raw = String.fromCharCodes(bytes);
  final buffer = StringBuffer();
  var index = raw.indexOf('stream');
  while (index >= 0) {
    final end = raw.indexOf('endstream', index);
    if (end < 0) break;
    var start = index + 'stream'.length;
    bool eol(int c) => c == 0x0A || c == 0x0D;
    while (start < end && eol(raw.codeUnitAt(start))) {
      start++;
    }
    var stop = end;
    while (stop > start && eol(raw.codeUnitAt(stop - 1))) {
      stop--;
    }
    try {
      buffer.write(
        String.fromCharCodes(zlib.decode(bytes.sublist(start, stop).toList())),
      );
    } catch (_) {
      // Flux non déflaté (l'image elle-même) : sans intérêt ici.
    }
    index = raw.indexOf('stream', end);
  }
  return buffer.toString();
}

/// Nombre de fois où une image est PEINTE — `/I<n> Do` dans un flux de contenu.
///
/// C'est la seule mesure qui distingue une bande posée une fois d'une bande
/// répétée par page : le PDF ne stocke l'image qu'UNE fois et la référence
/// ensuite, si bien que la taille du fichier ne bouge presque pas entre les
/// deux. Compter les octets ne discriminait rien.
int _imageDraws(Uint8List bytes) =>
    RegExp(r'/I\d+\s+Do').allMatches(_inflated(bytes)).length;

void main() {
  group('la bande elle-même', () {
    test('une bande bien formée est exploitable', () {
      expect(_band().isUsable, isTrue);
      expect(_band().bytesPerRow, 72);
    });

    /// Chacune de ces trois conditions produirait un défaut DIFFÉRENT si elle
    /// était supposée : un décalage d'un fragment d'octet à chaque ligne, un
    /// débordement de la tête d'impression, ou une lecture au-delà des données.
    test('une largeur non multiple de 8 est refusée', () {
      final bad = TicketLogoBand(
        widthDots: 100,
        heightDots: 8,
        bits: Uint8List(104),
      );
      expect(bad.isUsable, isFalse);
    });

    test('une largeur au-delà du plafond 80 mm est refusée', () {
      final bad = TicketLogoBand(
        widthDots: 584,
        heightDots: 8,
        bits: Uint8List(584 ~/ 8 * 8),
      );
      expect(bad.isUsable, isFalse);
    });

    test('un tableau de la mauvaise taille est refusé', () {
      final bad = TicketLogoBand(
        widthDots: 576,
        heightDots: 128,
        bits: Uint8List(10),
      );
      expect(bad.isUsable, isFalse);
    });
  });

  group('ESC/POS — la commande raster', () {
    /// GÉOMÉTRIE : calculée, donc assertée exactement. 576 points = 72 octets,
    /// et les deux dimensions voyagent en petit-boutiste.
    test('l\'en-tête porte la largeur EN OCTETS et la hauteur en points', () {
      final bytes = EscPosTicketRenderer.render(_model, logoBand: _band());
      final start = _rasterStart(bytes);

      expect(start, greaterThan(0));
      expect(bytes[start + 4], 72); // xL : 576 / 8
      expect(bytes[start + 5], 0); // xH
      expect(bytes[start + 6], 128); // yL
      expect(bytes[start + 7], 0); // yH
    });

    /// POSITION : après `ESC @` / `ESC t` / `ESC a 0`, et avant le texte.
    /// Posée avant la réinitialisation, elle serait effacée ; posée après la
    /// première ligne, elle ne serait plus un en-tête.
    test('elle vient après l\'alignement et avant la première ligne', () {
      final bytes = EscPosTicketRenderer.render(_model, logoBand: _band());
      final raster = _rasterStart(bytes);
      final align = bytes.indexOf(_escA0.first);
      final firstText = bytes.indexOf(0x43); // 'C' de COMPLEXE

      expect(align, lessThan(raster));
      expect(raster, lessThan(firstText));
    });

    /// ⚠️ **LE test de polarité.** Il ne compare pas des octets — une
    /// comparaison d'octets serait verte que l'inversion soit faite ou non,
    /// puisqu'elle vérifierait simplement que la sortie vaut l'entrée.
    ///
    /// Il compare la **proportion de points IMPRIMÉS**. La bande porte ~8 %
    /// d'encre ; le flux doit donc porter ~8 % de bits à 1, puisqu'un bit à 1
    /// est un point imprimé pour `GS v 0`. Sans l'inversion, il en porterait
    /// ~92 % — un rectangle noir avec le sceau en réserve.
    ///
    /// La borne est LARGE à dessein : elle sépare 8 de 92, ce qui est tout ce
    /// qu'elle a à faire, et ne bouge pas d'un dérivateur à l'autre.
    test('les points imprimés sont l\'ENCRE, pas le fond', () {
      final band = _band();
      final bytes = EscPosTicketRenderer.render(_model, logoBand: band);
      final start = _rasterStart(bytes);
      final payload = bytes.sublist(start + 8, start + 8 + band.bits.length);

      // Le fichier est très majoritairement blanc…
      expect(_onesPercent(band.bits), greaterThan(80));
      // …et le flux très majoritairement NON imprimé.
      expect(_onesPercent(payload), inInclusiveRange(3, 30));
    });

    test('chaque octet est l\'inverse exact de son entrée', () {
      final band = _band();
      final bytes = EscPosTicketRenderer.render(_model, logoBand: band);
      final start = _rasterStart(bytes);

      for (var i = 0; i < band.bits.length; i++) {
        expect(
          bytes[start + 8 + i],
          ~band.bits[i] & 0xFF,
          reason: 'octet $i non inversé',
        );
      }
    });

    test('un saut de ligne suit la bande', () {
      final band = _band();
      final bytes = EscPosTicketRenderer.render(_model, logoBand: band);
      final start = _rasterStart(bytes);
      expect(bytes[start + 8 + band.bits.length], 0x0A);
    });
  });

  group('le repli — sans logo, rien ne bouge', () {
    /// La propriété qui rend tout ce lot sûr : le flux d'une école sans logo est
    /// identique OCTET POUR OCTET à celui d'avant la bande.
    test('sans bande, le flux est identique à l\'octet près', () {
      final withNothing = EscPosTicketRenderer.render(_model);
      final withNull = EscPosTicketRenderer.render(_model, logoBand: null);
      expect(withNull, equals(withNothing));
      expect(_rasterStart(withNothing), -1);
    });

    /// Une bande inexploitable ne dégrade pas, elle s'efface : mieux vaut un
    /// ticket sans logo qu'un flux dont l'imprimante lirait la commande au-delà
    /// de ses données.
    test('une bande inexploitable ne laisse rien', () {
      final bytes = EscPosTicketRenderer.render(
        _model,
        logoBand: TicketLogoBand(
          widthDots: 100,
          heightDots: 4,
          bits: Uint8List(8),
        ),
      );
      expect(_rasterStart(bytes), -1);
      expect(bytes, equals(EscPosTicketRenderer.render(_model)));
    });

    /// ⚠️ La sonde de page de code passe par `renderLines`, et ne doit JAMAIS
    /// sortir de logo : elle imprime une ligne accentuée pour savoir ce que le
    /// matériel supporte, pas un ticket.
    test('la sonde de page de code ne sort aucun logo', () {
      final bytes = EscPosTicketRenderer.renderLines(const ['éàü']);
      expect(_rasterStart(bytes), -1);
    });
  });

  group('PDF — la bande sur les deux supports', () {
    String latin1(Uint8List b) => String.fromCharCodes(b);

    test('le rouleau reste une page unique, et grandit', () async {
      final without = await PdfTicketRenderer.render(_model);
      final with_ = await PdfTicketRenderer.render(_model, logoBand: _band());

      expect('MediaBox'.allMatches(latin1(with_)).length, 1);
      expect(with_.length, greaterThan(without.length));
    });

    /// La bande est peinte **exactement une fois**, même sur un ticket qui
    /// pagine : elle est un en-tête de document, pas de page.
    ///
    /// ⚠️ **Ce test ne prouve PAS que `header:` serait fautif.** Je l'ai
    /// éprouvé en déplaçant la bande dans `header:` : le paquet `pdf` la peint
    /// alors **une fois aussi**, et aucune assertion ne sépare les deux formes.
    /// Le choix de `build:` reste le bon — un en-tête de page se répéterait par
    /// contrat, et rien ne garantit que cette version se comporte ainsi pour
    /// toujours — mais il est tenu par le commentaire du renderer, pas par ce
    /// test. Le dire plutôt que de laisser croire à une garantie.
    ///
    /// Ce que ce test attrape réellement : une bande dupliquée par un futur
    /// remaniement, et une bande peinte alors qu'aucune n'est fournie.
    ///
    /// ⚠️ Et il ne compte pas les OCTETS : le PDF ne stocke l'image qu'une fois
    /// et la référence ensuite, si bien que le poids du fichier ne distingue
    /// rien. C'était ma première version, et elle était verte dans les deux cas.
    test('sur une feuille paginée, elle est peinte une seule fois', () async {
      final long = TicketReceiptModel(
        schoolName: 'Complexe scolaire La Colombe',
        studentFullName: 'Mbala Kasa Amina',
        reference: 'PROV-A1B2C3',
        isProvisional: true,
        paidAt: DateTime(2026, 9, 8, 1, 35),
        tenders: TicketTenderLine.identityFrom(
          MoneyBag.of(const [Money(150000, 'CDF')]),
        ),
        allocations: [
          for (var i = 0; i < 120; i++)
            TicketAllocationLine(
              label: 'Poste de frais numero $i',
              amountInCents: 1000,
              currency: 'CDF',
            ),
        ],
        labels: _labels,
      );

      const a4 = PdfPageFormat.a4;
      final without = await PdfTicketRenderer.render(long, format: a4);
      final with_ = await PdfTicketRenderer.render(
        long,
        format: a4,
        logoBand: _band(),
      );
      final pages = 'MediaBox'.allMatches(latin1(without)).length;
      expect(pages, greaterThan(1), reason: 'le cas ne pagine pas');

      // ⚠️ Compter les OCTETS ne discrimine rien : le PDF ne stocke l'image
      // qu'une fois et la référence ensuite, donc un `header:` produirait
      // presque exactement le même poids. Ce qui distingue, c'est le nombre de
      // fois où elle est PEINTE.
      expect(_imageDraws(without), 0);
      expect(_imageDraws(with_), 1, reason: 'la bande se répète par page');
    });

    test('sans bande, le PDF ne change pas de taille', () async {
      final a = await PdfTicketRenderer.render(_model);
      final b = await PdfTicketRenderer.render(_model, logoBand: null);
      expect(b.length, a.length);
    });

    /// Le PDF applique la convention du fichier telle quelle — c'est la sortie
    /// où l'on VOIT si la polarité est juste, là où le flux ESC/POS l'inverse.
    test('une bande inexploitable est ignorée', () async {
      final ignored = await PdfTicketRenderer.render(
        _model,
        logoBand: TicketLogoBand(
          widthDots: 100,
          heightDots: 4,
          bits: Uint8List(8),
        ),
      );
      expect(ignored.length, (await PdfTicketRenderer.render(_model)).length);
    });
  });
}
