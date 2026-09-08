import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/ticket/mono_png_decoder.dart';

// Le décodage du PNG 1 bit servi par la route `logo/thermal`.
//
// ## Deux niveaux, et aucun ne suffit seul
//
// **Les cinq filtres, un par un, contre les formules de la spécification.**
// Les valeurs attendues sont calculées à la main depuis §9.2 du format, jamais
// produites par un encodeur écrit ici : un décodeur éprouvé contre son propre
// encodeur est le cas d'école de la vérification qui ne discrimine rien — les
// deux partageraient la même erreur et tomberaient d'accord.
//
// ⚠️ Ce niveau est **indispensable et pas seulement prudent**. La dérivation
// d'essai dont nous disposons emploie les filtres 0, 1, 2 et 4 — **jamais 3
// (Average)**. Aucune image réelle ne garantit de couvrir les cinq types, donc
// se reposer sur un fichier, fût-il produit par la vraie chaîne, laisserait un
// chemin entier inéprouvé. Et le défiltrage se trompe **silencieusement** :
// une image légèrement fausse reste une image.
//
// **Le second niveau — décoder les octets réellement produits par la chaîne
// serveur — n'est pas encore là.** Il prouve l'interopérabilité, ce que des
// vecteurs spécifiés ne peuvent pas prouver. Il arrive avec la ressource de
// test permanente, et ce fichier n'est pas complet sans lui.

// Assemble un PNG gris 1 bit non entrelacé à partir de lignes **déjà
// filtrées** — chaque entrée est `[type, ...octets]`.
//
// Les CRC sont laissés à zéro : le décodeur ne les vérifie pas, et c'est
// délibéré. L'intégrité des octets est garantie plus haut et plus fort, par
// l'empreinte SHA-256 que la route sert en `ETag` et que le cache conserve.
Uint8List _png(int width, int height, List<List<int>> filteredRows) {
  final out = BytesBuilder()..add(const [137, 80, 78, 71, 13, 10, 26, 10]);

  void chunk(String type, List<int> data) {
    final header = ByteData(4)..setUint32(0, data.length);
    out
      ..add(header.buffer.asUint8List())
      ..add(type.codeUnits)
      ..add(data)
      ..add(const [0, 0, 0, 0]); // CRC non vérifié
  }

  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 1) // profondeur : 1 bit
    ..setUint8(9, 0) // type couleur : gris
    ..setUint8(10, 0) // compression
    ..setUint8(11, 0) // méthode de filtrage
    ..setUint8(12, 0); // non entrelacé
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', zlib.encode(filteredRows.expand((r) => r).toList()));
  chunk('IEND', const []);

  return out.takeBytes();
}

void main() {
  group('les cinq filtres, contre la spécification', () {
    /// Une première ligne sans filtre sert de référence aux suivantes : les
    /// filtres 2, 3 et 4 lisent la ligne PRÉCÉDENTE déjà défiltrée.
    const previous = [0x10, 0x20];

    /// `None` — les octets passent tels quels.
    test('0 — None', () {
      final band = MonoPngDecoder.decode(
        _png(16, 1, [
          [0, 0xAB, 0xCD],
        ]),
      );
      expect(band!.bits, equals(Uint8List.fromList([0xAB, 0xCD])));
    });

    /// `Sub` : `decodé[x] = filtré[x] + decodé[x-1]`, l'octet de gauche.
    ///   x=0 → 0x0A + 0    = 0x0A
    ///   x=1 → 0x05 + 0x0A = 0x0F
    test('1 — Sub ajoute l\'octet de gauche', () {
      final band = MonoPngDecoder.decode(
        _png(16, 1, [
          [1, 0x0A, 0x05],
        ]),
      );
      expect(band!.bits, equals(Uint8List.fromList([0x0A, 0x0F])));
    });

    /// `Up` : `decodé[x] = filtré[x] + précédent[x]`.
    ///   [0x01, 0x02] + [0x10, 0x20] = [0x11, 0x22]
    test('2 — Up ajoute la ligne du dessus', () {
      final band = MonoPngDecoder.decode(
        _png(16, 2, [
          [0, ...previous],
          [2, 0x01, 0x02],
        ]),
      );
      expect(band!.bits.sublist(2), equals(Uint8List.fromList([0x11, 0x22])));
    });

    /// `Average` : `decodé[x] = filtré[x] + ⌊(gauche + haut) / 2⌋`.
    ///   x=0 → 0x04 + ⌊(0  + 16)/2⌋ = 4  + 8  = 12 = 0x0C
    ///   x=1 → 0x08 + ⌊(12 + 32)/2⌋ = 8  + 22 = 30 = 0x1E
    ///
    /// ⚠️ **Le type qu'aucun de nos fichiers réels n'emploie.** Sans ce vecteur,
    /// il resterait entièrement non exercé — et une moyenne mal arrondie rend
    /// une image plausible.
    test('3 — Average ajoute la moyenne ENTIÈRE de gauche et haut', () {
      final band = MonoPngDecoder.decode(
        _png(16, 2, [
          [0, ...previous],
          [3, 0x04, 0x08],
        ]),
      );
      expect(band!.bits.sublist(2), equals(Uint8List.fromList([0x0C, 0x1E])));
    });

    /// `Paeth` : `decodé[x] = filtré[x] + Paeth(gauche, haut, haut-gauche)`,
    /// le prédicteur retenant le voisin le plus proche de `a + b - c`.
    ///   x=0 : a=0,  b=16, c=0  → p=16, pa=16 pb=0  pc=16 → b=16 ; 3 + 16 = 0x13
    ///   x=1 : a=19, b=32, c=16 → p=35, pa=16 pb=3  pc=19 → b=32 ; 6 + 32 = 0x26
    test('4 — Paeth choisit le voisin le plus proche du prédicteur', () {
      final band = MonoPngDecoder.decode(
        _png(16, 2, [
          [0, ...previous],
          [4, 0x03, 0x06],
        ]),
      );
      expect(band!.bits.sublist(2), equals(Uint8List.fromList([0x13, 0x26])));
    });

    /// Un type inconnu ne doit pas être ignoré comme un `None` : la ligne
    /// sortirait plausible et fausse. Le décodage entier échoue, et la bande
    /// s'efface.
    test('un type de filtre inconnu fait échouer le décodage', () {
      expect(
        MonoPngDecoder.decode(
          _png(16, 1, [
            [9, 0x00, 0x00],
          ]),
        ),
        isNull,
      );
    });
  });

  group('ce que le décodeur refuse', () {
    test('des octets qui ne sont pas un PNG', () {
      expect(MonoPngDecoder.decode(Uint8List.fromList([1, 2, 3])), isNull);
    });

    /// Le contrat est VÉRIFIÉ, pas supposé. Un PNG 8 bits dont on ne lirait que
    /// les dimensions serait défiltré de travers en silence.
    test('une profondeur autre que 1 bit', () {
      final bytes = _png(16, 1, [
        [0, 0x00, 0x00],
      ]);
      bytes[24] = 8; // profondeur, dans IHDR
      expect(MonoPngDecoder.decode(bytes), isNull);
    });

    test('un PNG entrelacé', () {
      final bytes = _png(16, 1, [
        [0, 0x00, 0x00],
      ]);
      bytes[28] = 1; // entrelacement Adam7
      expect(MonoPngDecoder.decode(bytes), isNull);
    });

    /// Une longueur incohérente est le cas où un décodeur naïf lit au-delà de
    /// ses données et rend une image tronquée sans le dire.
    test('un flux dont la taille ne colle pas aux dimensions', () {
      final bytes = _png(16, 4, [
        [0, 0x00, 0x00],
      ]);
      expect(MonoPngDecoder.decode(bytes), isNull);
    });
  });

  group('la bande produite', () {
    test('porte les dimensions du PNG et devient exploitable', () {
      final rows = [
        for (var y = 0; y < 8; y++) [0, ...List<int>.filled(72, 0xFF)],
      ];
      final band = MonoPngDecoder.decode(_png(576, 8, rows));

      expect(band!.widthDots, 576);
      expect(band.heightDots, 8);
      expect(band.bytesPerRow, 72);
      expect(band.isUsable, isTrue);
    });
  });
}
