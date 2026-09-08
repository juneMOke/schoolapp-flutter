import 'dart:io';
import 'dart:typed_data';

import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';

/// Décode le PNG **1 bit en niveaux de gris, non entrelacé** que sert la route
/// `logo/thermal`, en une [TicketLogoBand].
///
/// ## Pourquoi un décodeur écrit ici plutôt qu'un paquet
///
/// Ce n'est pas « un décodeur PNG », c'est le décodeur **de ce format-là**, et
/// c'est toute la différence de périmètre. L'entrée vient de notre propre
/// serveur, sous un contrat épinglé des deux côtés : profondeur 1, type couleur
/// 0, non entrelacé, 576×128. L'entrelacement Adam7, les palettes, les seize
/// profondeurs et les transformations de couleur ne sont pas à écrire, et un
/// paquet généraliste les apporterait avec leur surface — sur une application
/// qui tourne hors ligne sur des tablettes d'école, une dépendance de plus n'est
/// jamais gratuite.
///
/// L'inflate, lui, ne s'écrit pas : `dart:io` le donne.
///
/// ## Le mode de défaillance est contenu, et c'est ce qui rend le choix tenable
///
/// Toute anomalie rend `null`, et `TicketLogoBand.isUsable` efface alors la
/// bande : le flux redevient identique à l'octet près à celui d'un ticket sans
/// logo. Un décodage raté coûte donc **l'absence du logo**, jamais un logo faux
/// sur un papier remis à une famille.
///
/// ⚠️ Le défiltrage se trompe **silencieusement** : une image légèrement fausse
/// reste une image. C'est pourquoi les cinq types sont implémentés — y compris
/// `Average`, qu'aucun de nos fichiers d'essai n'emploie — et pourquoi ils sont
/// éprouvés un par un contre les formules de la spécification, en plus du
/// décodage d'un fichier réellement produit par la chaîne serveur.
abstract final class MonoPngDecoder {
  static const List<int> _signature = [137, 80, 78, 71, 13, 10, 26, 10];

  /// Rend la bande, ou `null` si les octets ne sont pas le format attendu.
  static TicketLogoBand? decode(Uint8List bytes) {
    try {
      return _decode(bytes);
    } catch (_) {
      // Toute anomalie — en-tête tronqué, flux non déflatable, longueur
      // incohérente — se lit « pas de logo ». Voir la note de classe : c'est le
      // repli, pas une dégradation.
      return null;
    }
  }

  static TicketLogoBand? _decode(Uint8List bytes) {
    if (bytes.length < 8) return null;
    for (var i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) return null;
    }

    int? width;
    int? height;
    final idat = BytesBuilder();

    var pos = 8;
    while (pos + 8 <= bytes.length) {
      final data = ByteData.sublistView(bytes, pos, pos + 8);
      final length = data.getUint32(0);
      final type = String.fromCharCodes(bytes, pos + 4, pos + 8);
      final start = pos + 8;
      final end = start + length;
      if (end > bytes.length) return null;

      if (type == 'IHDR') {
        final header = ByteData.sublistView(bytes, start, end);
        width = header.getUint32(0);
        height = header.getUint32(4);
        final depth = bytes[start + 8];
        final colorType = bytes[start + 9];
        final interlace = bytes[start + 12];
        // Le contrat, vérifié plutôt que supposé : tout autre PNG serait décodé
        // de travers en silence si on se contentait de lire ses dimensions.
        if (depth != 1 || colorType != 0 || interlace != 0) return null;
      } else if (type == 'IDAT') {
        idat.add(bytes.sublist(start, end));
      } else if (type == 'IEND') {
        break;
      }
      pos = end + 4; // + CRC
    }

    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }

    final raw = Uint8List.fromList(zlib.decode(idat.takeBytes()));
    final stride = (width + 7) ~/ 8;
    // Une ligne = un octet de filtre + `stride` octets de données.
    if (raw.length != (stride + 1) * height) return null;

    final out = Uint8List(stride * height);
    final previous = Uint8List(stride);
    final current = Uint8List(stride);

    var cursor = 0;
    for (var y = 0; y < height; y++) {
      final filter = raw[cursor++];
      current.setRange(0, stride, raw, cursor);
      cursor += stride;

      if (!_unfilter(filter, current, previous, stride)) return null;

      out.setRange(y * stride, (y + 1) * stride, current);
      previous.setRange(0, stride, current);
    }

    return TicketLogoBand(widthDots: width, heightDots: height, bits: out);
  }

  /// Défiltre une ligne **en place**, selon les formules de la spécification
  /// PNG (§9.2). `bpp` vaut 1 pour un gris 1 bit : le « pixel précédent » est
  /// l'octet précédent.
  ///
  /// Rend `false` sur un type inconnu — un filtre qu'on ne sait pas défaire
  /// produirait une image plausible et fausse.
  static bool _unfilter(
    int filter,
    Uint8List line,
    Uint8List previous,
    int stride,
  ) {
    const bpp = 1;
    switch (filter) {
      case 0: // None
        return true;
      case 1: // Sub
        for (var x = bpp; x < stride; x++) {
          line[x] = (line[x] + line[x - bpp]) & 0xFF;
        }
        return true;
      case 2: // Up
        for (var x = 0; x < stride; x++) {
          line[x] = (line[x] + previous[x]) & 0xFF;
        }
        return true;
      case 3: // Average
        for (var x = 0; x < stride; x++) {
          final left = x >= bpp ? line[x - bpp] : 0;
          line[x] = (line[x] + ((left + previous[x]) >> 1)) & 0xFF;
        }
        return true;
      case 4: // Paeth
        for (var x = 0; x < stride; x++) {
          final left = x >= bpp ? line[x - bpp] : 0;
          final up = previous[x];
          final upLeft = x >= bpp ? previous[x - bpp] : 0;
          line[x] = (line[x] + _paeth(left, up, upLeft)) & 0xFF;
        }
        return true;
      default:
        return false;
    }
  }

  /// Le prédicteur de Paeth (spécification PNG §9.4) : celui des trois voisins
  /// dont la valeur est la plus proche de `a + b - c`, les égalités tranchées
  /// dans l'ordre gauche, haut, haut-gauche.
  static int _paeth(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p - a).abs();
    final pb = (p - b).abs();
    final pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }
}
