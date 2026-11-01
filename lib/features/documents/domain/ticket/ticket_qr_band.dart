import 'dart:typed_data';

import 'package:qr/qr.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';

/// Le QR de vérification d'un reçu scellé, en **points d'imprimante** — la
/// même forme qu'une bande de logo, donc les deux renderers le posent comme
/// elle : `GS v 0` sur la thermique, une image dans le PDF.
///
/// ## Pourquoi une image, et non la commande QR native (`GS ( k`)
///
/// `GS ( k` n'a jamais été éprouvé sur la NT-8003DD, et une commande qu'une
/// imprimante ignore ne laisse **rien** sur le papier, en silence. `GS v 0`,
/// lui, y imprime déjà la bande de logo. Une seule matrice nourrit aussi le
/// PDF : les deux sorties montrent le même QR, comme elles montrent le même
/// texte.
///
/// ## Les dimensions
///
/// Un module tient au moins **3 points** (0,375 mm à 203 dpi), le seuil sous
/// lequel un téléphone peine à lire un QR thermique ; au plus 6, au-delà le QR
/// mange du rouleau à chaque encaissement. La **zone de silence** de quatre
/// modules, exigée par la norme, fait partie de l'image. Le QR est centré dans
/// ses octets : `ESC a 1` est interdit dans ce gabarit.
abstract final class TicketQrBand {
  static const int _quietModules = 4;
  static const int _minModuleDots = 3;
  static const int _maxModuleDots = 6;

  /// Part de la laize que le QR peut occuper : assez pour se scanner de loin,
  /// pas au point de ressembler à une pièce d'identité.
  static const double _widthShare = 0.6;

  /// Points d'une ligne de [columns] caractères en police A (12 points par
  /// caractère) : 576 pour 48 colonnes (80 mm), 384 pour 32 (58 mm).
  static int paperDotsFor(int columns) {
    final dots = (columns * 12).clamp(8, TicketLogoBand.maxWidthDots);
    return dots - dots % 8;
  }

  /// Le QR de [payload] tient-il lisiblement sur [columns] colonnes ? Le
  /// gabarit le demande avant de poser la légende : une légende sans QR
  /// dessous inviterait à scanner du blanc.
  static bool fits(String payload, {required int columns}) =>
      payload.trim().isNotEmpty &&
      of(payload, paperDots: paperDotsFor(columns)) != null;

  /// La bande du QR de [payload], large de [paperDots] ; `null` si le contenu
  /// ne s'encode pas ou si le QR ne tient pas lisiblement sur la laize.
  static TicketLogoBand? of(String payload, {required int paperDots}) {
    final QrImage image;
    try {
      image = QrImage(
        QrCode.fromData(
          data: payload,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        ),
      );
    } on Object {
      return null;
    }

    final modules = image.moduleCount + 2 * _quietModules;
    final module = ((paperDots * _widthShare) ~/ modules).clamp(
      0,
      _maxModuleDots,
    );
    if (module < _minModuleDots) return null;

    final side = modules * module;
    final width = paperDots - paperDots % 8;
    final left = (width - side) ~/ 2;
    final bytesPerRow = width ~/ 8;
    // Convention PNG, celle de `TicketLogoBand` : `1` = blanc, `0` = encre.
    final bits = Uint8List(bytesPerRow * side)
      ..fillRange(0, bytesPerRow * side, 0xFF);

    for (var y = 0; y < side; y++) {
      final row = y ~/ module - _quietModules;
      for (var x = 0; x < side; x++) {
        final col = x ~/ module - _quietModules;
        final dark =
            row >= 0 &&
            col >= 0 &&
            row < image.moduleCount &&
            col < image.moduleCount &&
            image.isDark(row, col);
        if (!dark) continue;
        final dot = left + x;
        bits[y * bytesPerRow + (dot >> 3)] &= ~(0x80 >> (dot & 7)) & 0xFF;
      }
    }

    return TicketLogoBand(widthDots: width, heightDots: side, bits: bits);
  }
}
