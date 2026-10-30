import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_qr_band.dart';

const _url = 'https://api.eteelo.com/api/v1/editique/verify/9f8e7d6c-5b4a';

/// `1` = blanc (convention PNG de la bande), comme la bande de logo.
bool _isInk(TicketLogoBand band, int x, int y) {
  final byte = band.bits[y * band.bytesPerRow + (x >> 3)];
  return (byte >> (7 - (x & 7))) & 1 == 0;
}

void main() {
  test('la laize vient des colonnes, au multiple de 8 près', () {
    expect(TicketQrBand.paperDotsFor(48), 576);
    expect(TicketQrBand.paperDotsFor(32), 384);
    expect(TicketQrBand.paperDotsFor(80), TicketLogoBand.maxWidthDots);
  });

  for (final paper in const [576, 384]) {
    test('chaque module porte l encre de la matrice ($paper points)', () {
      final band = TicketQrBand.of(_url, paperDots: paper)!;
      final image = QrImage(
        QrCode.fromData(data: _url, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
      final modules = image.moduleCount + 8;
      final module = band.heightDots ~/ modules;
      final left = (band.widthDots - band.heightDots) ~/ 2;

      expect(band.isUsable, isTrue);
      expect(band.widthDots, paper);
      expect(band.heightDots, modules * module);
      expect(module, inInclusiveRange(3, 6));
      // Centré dans ses octets : autant de blanc de part et d'autre.
      expect(band.widthDots - band.heightDots - 2 * left, lessThan(2));

      for (var r = -4; r < image.moduleCount + 4; r++) {
        for (var c = -4; c < image.moduleCount + 4; c++) {
          final inside =
              r >= 0 &&
              c >= 0 &&
              r < image.moduleCount &&
              c < image.moduleCount;
          final expected = inside && image.isDark(r, c);
          final x = left + (c + 4) * module + module ~/ 2;
          final y = (r + 4) * module + module ~/ 2;
          expect(_isInk(band, x, y), expected, reason: 'module ($r, $c)');
        }
      }
      // Rien hors du carré : la laize reste blanche à gauche comme à droite.
      for (var y = 0; y < band.heightDots; y++) {
        expect(_isInk(band, 0, y), isFalse);
        expect(_isInk(band, band.widthDots - 1, y), isFalse);
      }
    });
  }

  test('une laize trop étroite pour un module lisible ne rend rien', () {
    expect(TicketQrBand.of(_url, paperDots: 64), isNull);
  });
}
