import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';

/// Lecteur ESC/POS minimal : rend les positions où `ESC @` est lu comme une
/// COMMANDE. Il ne connaît que ce que le renderer émet — `GS v 0` consomme son
/// en-tête puis largeur × hauteur octets de points, quoi qu'ils contiennent.
List<int> _initsSeenAsCommands(List<int> bytes) {
  final inits = <int>[];
  var i = 0;
  while (i < bytes.length) {
    final b = bytes[i];
    if (b == 0x1B && i + 1 < bytes.length) {
      final op = bytes[i + 1];
      if (op == 0x40) {
        inits.add(i);
        i += 2;
      } else {
        i += 3; // ESC t n, ESC a n, ESC E n, ESC d n
      }
    } else if (b == 0x1D && i + 2 < bytes.length && bytes[i + 1] == 0x76) {
      // GS v 0 m xL xH yL yH, puis les points.
      if (i + 7 >= bytes.length) return inits;
      final width = bytes[i + 4] | (bytes[i + 5] << 8);
      final rows = bytes[i + 6] | (bytes[i + 7] << 8);
      i += 8 + width * rows;
    } else {
      i++;
    }
  }
  return inits;
}

void main() {
  const url = 'https://api.eteelo.com/verify/RC/9f8e7d6c';

  // Le ticket de la photo du 2026-11-03 : logo en tête, QR en pied.
  final logo = TicketLogoBand(
    widthDots: 576,
    heightDots: 128,
    bits: Uint8List(72 * 128)..fillRange(0, 72 * 128, 0xFF),
  );
  final ticket = EscPosTicketRenderer.renderRichLines(const [
    TicketLine('COLLEGE'),
    TicketLine.qr(url),
    TicketLine('FIN'),
  ], logoBand: logo);

  /// Le canal natif préfixe chaque envoi d'un `LF`.
  List<int> send(List<int> bytes) => [0x0A, ...bytes];

  /// Ce que l'imprimante reçoit : la fin d'un envoi PRÉCÉDENT coupée [cut]
  /// octets avant son terme, puis l'envoi courant.
  List<int> afterTruncation(int cut, Uint8List current) => [
    ...send(EscPosTicketRenderer.withResync(ticket)).sublist(
      0,
      ticket.length + 1 + EscPosTicketRenderer.resyncPreambleLength - cut,
    ),
    ...send(EscPosTicketRenderer.withResync(current)),
  ];

  int ticketStart(int cut) =>
      1 +
      EscPosTicketRenderer.resyncPreambleLength +
      ticket.length -
      cut +
      1 +
      EscPosTicketRenderer.resyncPreambleLength;

  test('le bourrage est blanc et couvre une bande raster complète', () {
    final preamble = EscPosTicketRenderer.resyncPreamble;

    expect(preamble, hasLength(128 * 72));
    // Zéro = point non imprimé : une bande en attente se comble en blanc.
    expect(preamble, everyElement(0));
  });

  test('sans bourrage, le scénario de la photo se reproduit', () {
    // Coupé au milieu de la dernière bande du QR : l'imprimante avale
    // l'`ESC @` du ticket suivant comme des points.
    final cut = 40 * 72;
    final received = [
      ...send(ticket).sublist(0, ticket.length + 1 - cut),
      ...send(ticket),
    ];

    expect(
      _initsSeenAsCommands(received),
      isNot(contains(ticket.length + 1 - cut + 1)),
    );
  });

  // Coupures prises dans la dernière bande du QR, dans son en-tête, et dans le
  // texte de fin.
  for (final cut in [3, 20, 72, 40 * 72, 127 * 72, 128 * 72 + 4]) {
    test('coupé $cut octets avant la fin, le ticket suivant repart à zéro', () {
      final received = afterTruncation(cut, ticket);

      expect(_initsSeenAsCommands(received), contains(ticketStart(cut)));
    });
  }

  test('le bourrage précède un envoi, pas chaque exemplaire', () {
    final sent = EscPosTicketRenderer.withResync(
      EscPosTicketRenderer.joinCopies(ticket, 3),
    );

    expect(
      sent.length,
      EscPosTicketRenderer.resyncPreambleLength + ticket.length * 3 + 2 * 49,
    );
  });
}
