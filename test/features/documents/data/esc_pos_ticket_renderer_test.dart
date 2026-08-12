import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/ticket_code_page.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

const _labels = TicketLabels(
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
  keepTicketNotice:
      'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.',
);

TicketReceiptModel _model({String schoolName = 'Institut Sacré-Cœur'}) =>
    TicketReceiptModel(
      schoolName: schoolName,
      schoolMunicipality: 'Kinshasa · Ngaliema',
      studentFullName: 'Mbala Kasa Amina',
      matriculationNumber: null,
      classroomName: '5e primaire A',
      provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
      paidAt: DateTime(2026, 8, 11, 14, 7),
      cashierFullName: 'Jean Kabeya',
      amountReceivedInCents: 150000,
      allocations: const [
        TicketAllocationLine(label: 'Frais scolaires', amountInCents: 120000),
        TicketAllocationLine(label: 'Fournitures', amountInCents: 30000),
      ],
      remainingBalanceInCents: 250000,
      currency: 'CDF',
      labels: _labels,
    );

/// Longueur de l'en-tête : `ESC @` (2) + `ESC t n` (3) + `ESC a 0` (3).
const int _headerLength = 8;

int _trailerLength({required int feedLines, required TicketCutMode cut}) =>
    (feedLines > 0 ? 3 : 0) + (cut == TicketCutMode.none ? 0 : 3);

/// Octets du corps, en-tête et commandes de fin retirés.
Uint8List _body(
  Uint8List bytes, {
  int feedLines = EscPosTicketRenderer.defaultFeedLines,
  TicketCutMode cut = TicketCutMode.none,
}) => Uint8List.sublistView(
  bytes,
  _headerLength,
  bytes.length - _trailerLength(feedLines: feedLines, cut: cut),
);

/// Relit le corps comme le ferait l'imprimante sous une page identité.
List<String> _decodedLines(
  Uint8List bytes, {
  int feedLines = EscPosTicketRenderer.defaultFeedLines,
  TicketCutMode cut = TicketCutMode.none,
}) {
  final body = _body(bytes, feedLines: feedLines, cut: cut);
  final text = latin1.decode(body, allowInvalid: true);
  final lines = text.split('\n');
  // Chaque ligne est suivie d'un LF : le dernier découpage est donc vide.
  expect(lines.last, isEmpty);
  return lines.sublist(0, lines.length - 1);
}

void main() {
  group('critère d\'acceptation ADR-012 — un modèle, deux renderers', () {
    test('le flux porte EXACTEMENT le texte du gabarit partagé', () {
      final model = _model();
      final bytes = EscPosTicketRenderer.render(model);

      expect(
        _decodedLines(bytes),
        equals(TicketTextLayout.render(model, columns: 48)),
      );
    });

    test('48 colonnes : aucune ligne du flux ne dépasse la largeur', () {
      final bytes = EscPosTicketRenderer.render(_model());
      for (final line in _decodedLines(bytes)) {
        expect(line.length, lessThanOrEqualTo(48), reason: line);
      }
    });

    test('la largeur demandée est transmise au gabarit', () {
      final bytes = EscPosTicketRenderer.render(_model(), columns: 32);
      for (final line in _decodedLines(bytes)) {
        expect(line.length, lessThanOrEqualTo(32), reason: line);
      }
    });
  });

  group('en-tête', () {
    test(
      'initialise, sélectionne la page, puis force l\'alignement gauche',
      () {
        final bytes = EscPosTicketRenderer.render(_model());

        expect(
          bytes.sublist(0, _headerLength),
          equals(<int>[
            0x1B, 0x40, // ESC @  — remise à zéro
            0x1B, 0x74, 16, // ESC t 16 — WPC1252
            0x1B, 0x61, 0x00, // ESC a 0 — alignement gauche
          ]),
        );
      },
    );

    test('le sélecteur suit la page de code demandée', () {
      final bytes = EscPosTicketRenderer.render(
        _model(),
        codePage: TicketCodePage.probe(2),
      );
      expect(bytes.sublist(3, 6), equals(<int>[0x74, 2, 0x1B]));
    });
  });

  group('page de code', () {
    test('WPC1252 écrit le Latin-1 tel quel, sans table', () {
      // « é » = U+00E9 = 0xE9 en Latin-1 comme en CP1252.
      final bytes = EscPosTicketRenderer.encodeLine(
        'éàü',
        TicketCodePage.cp1252,
      );
      expect(bytes, equals(<int>[0xE9, 0xE0, 0xFC]));
    });

    test('une correspondance déclarée remplace l\'octet', () {
      const folded = TicketCodePage(
        selector: 0,
        debugName: 'test',
        overrides: {0xE9: 0x82}, // « é » de CP850
      );
      expect(
        EscPosTicketRenderer.encodeLine('éa', folded),
        equals(<int>[0x82, 0x61]),
      );
    });

    test(
      'la translittération de TicketCharset s\'applique avant l\'encodage',
      () {
        // « Œ » n'a pas d'octet Latin-1 : il devient « OE », soit DEUX octets.
        expect(
          EscPosTicketRenderer.encodeLine('Œuf', TicketCodePage.cp1252),
          equals(<int>[0x4F, 0x45, 0x75, 0x66]),
        );
      },
    );
  });

  group('garde d\'injection', () {
    test('un octet de commande venu des données devient « ? »', () {
      // ESC (0x1B) n'est pas une espace : il traverse le gabarit intact.
      final bytes = EscPosTicketRenderer.encodeLine(
        'A\u001BB',
        TicketCodePage.cp1252,
      );
      expect(bytes, equals(<int>[0x41, 0x3F, 0x42]));
    });

    test('DEL et les commandes C1 sont refusés aussi', () {
      expect(
        EscPosTicketRenderer.encodeLine('\u007F\u0080', TicketCodePage.cp1252),
        equals(<int>[0x3F, 0x3F]),
      );
    });

    test(
      'un nom d\'école piégé ne place aucune commande dans le corps du flux',
      () {
        final bytes = EscPosTicketRenderer.render(
          _model(schoolName: 'Institut\u001B\u0040 Sacré'),
        );

        final body = _body(bytes);
        for (var i = 0; i < body.length; i++) {
          // Le seul octet de contrôle admis dans le corps est le saut de ligne
          // que le renderer pose lui-même.
          expect(
            body[i] >= 0x20 || body[i] == 0x0A,
            isTrue,
            reason: 'octet de contrôle 0x${body[i].toRadixString(16)} en $i',
          );
        }
      },
    );

    test('la largeur du gabarit survit à une donnée piégée', () {
      final bytes = EscPosTicketRenderer.render(
        _model(schoolName: 'Institut\u001B Sacré-Cœur'),
      );
      for (final line in _decodedLines(bytes)) {
        expect(line.length, lessThanOrEqualTo(48), reason: line);
      }
    });
  });

  group('fin de ticket', () {
    test('avance le papier pour dégager le mécanisme', () {
      final bytes = EscPosTicketRenderer.render(_model());
      expect(
        bytes.sublist(bytes.length - 3),
        equals(<int>[0x1B, 0x64, EscPosTicketRenderer.defaultFeedLines]),
      );
    });

    test('aucune avance quand elle est explicitement refusée', () {
      final bytes = EscPosTicketRenderer.render(_model(), feedLines: 0);
      expect(bytes.last, equals(0x0A));
    });

    test('aucune commande de coupe par défaut', () {
      final bytes = EscPosTicketRenderer.render(_model());
      expect(bytes.contains(0x1D), isFalse);
    });

    test('coupe partielle et coupe complète', () {
      final partial = EscPosTicketRenderer.render(
        _model(),
        cut: TicketCutMode.partial,
      );
      expect(partial.sublist(partial.length - 3), equals(<int>[0x1D, 0x56, 1]));

      final full = EscPosTicketRenderer.render(
        _model(),
        cut: TicketCutMode.full,
      );
      expect(full.sublist(full.length - 3), equals(<int>[0x1D, 0x56, 0]));
    });

    test('la coupe vient APRÈS l\'avance, jamais avant', () {
      final bytes = EscPosTicketRenderer.render(
        _model(),
        cut: TicketCutMode.full,
      );
      expect(
        bytes.sublist(bytes.length - 6),
        equals(<int>[
          0x1B,
          0x64,
          EscPosTicketRenderer.defaultFeedLines,
          0x1D,
          0x56,
          0,
        ]),
      );
    });
  });
}
