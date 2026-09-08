import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/mono_png_decoder.dart';

// Le décodeur contre les octets RÉELLEMENT produits par la chaîne serveur.
//
// C'est le niveau que des vecteurs spécifiés ne peuvent pas atteindre : il
// prouve l'INTEROPÉRABILITÉ. Un décodeur éprouvé seulement contre un encodeur
// écrit ici serait le cas d'école de la vérification qui ne discrimine rien —
// les deux partageraient la même erreur de défiltrage et tomberaient d'accord.
//
// Le fichier vient du `SchoolLogoDeriver` du serveur, par le chemin de
// production (normaliser, décoder, dériver) : sceau circulaire du Collège La
// Fontaine, texte en réserve blanche sur anneau bleu marine, seuillé — pas
// tramé, un Floyd-Steinberg détruirait l'anneau et le texte.
//
// ## Ce qui est asserté, et ce qui ne l'est PAS
//
// **La géométrie, au point.** Elle est calculée — 576 = (128 + 224 + 224), 72
// octets par ligne — et ne dépend d'aucun rééchantillonneur. Les deux
// dérivations, Java et Python, tombent dessus à l'identique.
//
// **Le taux d'encre, en fourchette large.** Il dépend du rendu : les deux
// chaînes donnent 92,23 % et 92,3 % de blanc sur cette figure. L'écart est
// minuscule, mais le borner serré n'apporterait rien et casserait au premier
// changement d'outil. Ce que la fourchette doit séparer, c'est un basculement
// de polarité — 8 % contre 92 % — et elle le fait.
//
// ⚠️ **Le `sha256` du fichier n'est pas asserté, et ce n'est pas un oubli.**
// Le fichier est versionné : il ne peut pas dériver en silence, git s'en charge.
// Ce que ces tests doivent tenir, ce sont les PROPRIÉTÉS de la bande, pas
// l'identité d'un octet — une empreinte figée rougirait à la moindre
// re-dérivation, y compris légitime, et pour une raison qui ne serait pas un
// défaut.
//
// L'arbitrage qui menaçait ces octets est d'ailleurs rendu : le vrai logo était
// refusé par le plafond de stockage du serveur (1499 ko après normalisation
// contre 1024 autorisés), et c'est le PLAFOND qui est relevé, pas la
// normalisation durcie. Ces octets-ci restent donc ceux de la production. Mais
// les assertions ci-dessous auraient survécu à l'autre issue, et c'est ce qui
// les rend bonnes.

Uint8List _fixture() => File(
  'test/fixtures/logo/thermal_la_fontaine_576x128.png',
).readAsBytesSync();

/// Les colonnes qui portent au moins un point d'encre.
({int first, int last}) _inkedColumns(Uint8List bits, int width, int height) {
  final stride = width ~/ 8;
  var first = width;
  var last = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final byte = bits[y * stride + (x >> 3)];
      final isInk = (byte >> (7 - (x & 7))) & 1 == 0;
      if (!isInk) continue;
      if (x < first) first = x;
      if (x > last) last = x;
    }
  }
  return (first: first, last: last);
}

double _whitePercent(Uint8List bits) {
  var ones = 0;
  for (final b in bits) {
    ones += b.toRadixString(2).split('').where((c) => c == '1').length;
  }
  return 100 * ones / (bits.length * 8);
}

void main() {
  test('la bande du serveur se décode, et sa géométrie tombe au point', () {
    final band = MonoPngDecoder.decode(_fixture());

    expect(band, isNotNull, reason: 'le décodage a échoué sur un fichier réel');
    expect(band!.widthDots, 576);
    expect(band.heightDots, 128);
    expect(band.bytesPerRow, 72);
    expect(band.bits, hasLength(72 * 128));
    expect(band.isUsable, isTrue);
  });

  /// Le centrage est **cuit dans l'image**, et il le faut : le flux force
  /// `ESC a 0` et le contrat de la classe interdit `ESC a 1`, donc le renderer
  /// ne peut pas centrer. `(576 − 128) / 2 = 224` de chaque côté.
  test('le logo est centré au pixel dans ses octets', () {
    final band = MonoPngDecoder.decode(_fixture())!;
    final ink = _inkedColumns(band.bits, band.widthDots, band.heightDots);

    expect(ink.first, 224);
    expect(ink.last, 351);
    expect(ink.last - ink.first + 1, 128, reason: 'le logo est carré');
    expect(band.widthDots - 1 - ink.last, ink.first, reason: 'marges égales');
  });

  /// Convention PNG, confirmée des deux côtés : `1` = blanc. Le coin est donc
  /// blanc, et l'image très majoritairement à 1.
  test('la convention est bien celle du PNG : 1 est blanc', () {
    final band = MonoPngDecoder.decode(_fixture())!;

    expect(band.bits.first & 0x80, 0x80, reason: 'coin (0,0) non blanc');
    expect(_whitePercent(band.bits), inInclusiveRange(80, 98));
  });

  /// Le bout du chemin : ce que la tête d'impression recevrait vraiment.
  /// L'encre du fichier — ~8 % — devient ~8 % de points IMPRIMÉS. Sans
  /// l'inversion, ce serait ~92 %, soit un rectangle noir portant le sceau en
  /// réserve.
  test('versée dans GS v 0, elle imprime l\'encre et non le fond', () {
    final band = MonoPngDecoder.decode(_fixture())!;
    final bytes = EscPosTicketRenderer.renderLines(const [
      'ligne',
    ], logoBand: band);

    const marker = [0x1D, 0x76, 0x30, 0x00];
    var start = -1;
    for (var i = 0; i + 4 <= bytes.length; i++) {
      if (bytes[i] == marker[0] &&
          bytes[i + 1] == marker[1] &&
          bytes[i + 2] == marker[2] &&
          bytes[i + 3] == marker[3]) {
        start = i;
        break;
      }
    }
    expect(start, greaterThan(0));

    // La largeur voyage EN OCTETS : 576 / 8 = 72.
    expect(bytes[start + 4], 72);
    expect(bytes[start + 6], 128);

    final payload = bytes.sublist(start + 8, start + 8 + band.bits.length);
    // ⚠️ Sur la charge utile INVERSÉE, un bit à 1 est un point IMPRIMÉ —
    // l'inverse du fichier. `_whitePercent` compte les bits à 1 : appliquée
    // ici, elle mesure donc l'ENCRE, pas le fond.
    final printedPercent = _whitePercent(payload);
    expect(
      printedPercent,
      inInclusiveRange(3, 30),
      reason:
          'polarité inversée : le fond s\'imprimerait à la place de l\'encre',
    );
  });
}
