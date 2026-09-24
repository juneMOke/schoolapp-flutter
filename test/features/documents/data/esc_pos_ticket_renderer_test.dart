import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_line.dart';
import 'package:school_app_flutter/features/documents/data/ticket/ticket_code_page.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalMention: 'provisoire',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  annualMatriculationLabel: 'Mat. annuel :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  derivedAmountPrefix: 'soit',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde restant à payer pour ce(s) frais',
  balanceTotalLabel: 'Total',
  historyLabel: 'Historique des paiements',
  historyTotalLabel: 'Total verse',
  signatureLabel: 'Signature du caissier',
  keepTicketNotice:
      'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.',
  thanksNotice: 'Nous vous remercions pour votre confiance.',
  editorNotice: 'Recu edite par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

TicketReceiptModel _model({String schoolName = 'Institut Sacré-Cœur'}) =>
    TicketReceiptModel(
      schoolName: schoolName,
      schoolLocality: 'Kinshasa · Ngaliema',
      studentFullName: 'Mbala Kasa Amina',
      matriculationNumber: null,
      classroomName: '5e primaire A',
      reference: 'PROV-A1B2C3-9F8E7D6C',
      isProvisional: true,
      paidAt: DateTime(2026, 8, 11, 14, 7),
      cashierFullName: 'Jean Kabeya',
      tenders: TicketTenderLine.identityFrom(
        MoneyBag.of(const [Money(150000, 'CDF')]),
      ),
      allocations: const [
        TicketAllocationLine(
          label: 'Frais scolaires',
          amountInCents: 120000,
          currency: 'CDF',
        ),
        TicketAllocationLine(
          label: 'Fournitures',
          amountInCents: 30000,
          currency: 'CDF',
        ),
      ],
      remainingBalance: MoneyBag.of(const [Money(250000, 'CDF')]),
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

/// Retire les séquences d'ATTRIBUT du corps — `ESC E n` — comme le ferait
/// l'imprimante, qui les **consomme** au lieu de les imprimer.
///
/// C'est ce qui permet au critère d'acceptation de l'ADR-012 de continuer à se
/// vérifier mot pour mot : il porte sur le **contenu textuel** des deux sorties,
/// et le gras n'en est pas. Au passage, cette relecture prouve que les
/// séquences sont bien formées — trois octets, jamais une de plus, jamais une
/// tronquée en fin de flux.
///
/// ⚠️ Ce retrait est aveugle par construction ; ce qui BORNE le nombre de
/// séquences réellement présentes est le test de la garde d'injection, qui
/// compte les accentuations du corps et les compare à celles du gabarit.
///
/// ⚠️ Suppose un corps SANS bande raster : les octets d'une image pourraient
/// contenir `1B 45` par hasard. Les modèles de ce fichier n'en portent aucune,
/// et le décodage en latin1 juste en dessous fait déjà cette hypothèse.
Uint8List _withoutAttributes(Uint8List body) {
  final out = <int>[];
  for (var i = 0; i < body.length; i++) {
    if (i + 2 < body.length && body[i] == 0x1B && body[i + 1] == 0x45) {
      i += 2;
      continue;
    }
    out.add(body[i]);
  }
  return Uint8List.fromList(out);
}

/// Relit le corps comme le ferait l'imprimante sous une page identité.
List<String> _decodedLines(
  Uint8List bytes, {
  int feedLines = EscPosTicketRenderer.defaultFeedLines,
  TicketCutMode cut = TicketCutMode.none,
}) {
  final body = _withoutAttributes(_body(bytes, feedLines: feedLines, cut: cut));
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
        final model = _model(schoolName: 'Institut\u001B\u0040 Sacré');
        final bytes = EscPosTicketRenderer.render(model);

        // Les seules commandes admises dans le corps sont les accentuations que
        // le renderer pose LUI-MÊME, et on en compte le nombre exact.
        //
        // ⚠️ Compter est ce qui ferme l'angle mort : se contenter de sauter les
        // triplets `ESC E n` laisserait passer une commande injectée qui aurait
        // cette forme. Ici, une accentuation de plus que le gabarit n'en
        // déclare fait rougir, d'où qu'elle vienne.
        final attendues = TicketTextLayout.renderRich(
          model,
        ).where((l) => l.bold).length;
        var ouvertes = 0;

        final body = _body(bytes);
        for (var i = 0; i < body.length; i++) {
          if (i + 2 < body.length && body[i] == 0x1B && body[i + 1] == 0x45) {
            expect(body[i + 2], anyOf(0, 1));
            if (body[i + 2] == 1) ouvertes++;
            i += 2;
            continue;
          }
          // Le seul autre octet de contrôle admis est le saut de ligne que le
          // renderer pose lui-même.
          expect(
            body[i] >= 0x20 || body[i] == 0x0A,
            isTrue,
            reason: 'octet de contrôle 0x${body[i].toRadixString(16)} en $i',
          );
        }

        expect(
          ouvertes,
          attendues,
          reason: 'aucune accentuation de plus que celles du gabarit',
        );
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

  group('accentuation', () {
    /// Les positions de `ESC E n` dans le flux, avec leur argument.
    List<(int, int)> escE(List<int> bytes) => [
      for (var i = 0; i + 2 < bytes.length; i++)
        if (bytes[i] == 0x1B && bytes[i + 1] == 0x45) (i, bytes[i + 2]),
    ];

    test('une ligne grasse est encadrée, et refermée', () {
      final bytes = EscPosTicketRenderer.renderRichLines(const [
        TicketLine('TITRE', bold: true),
      ], feedLines: 0);

      expect(escE(bytes).map((e) => e.$2), [1, 0]);

      // L'ordre compte : ouverte AVANT le texte, refermée APRÈS.
      final texte = bytes.indexOf(0x54); // 'T' de TITRE
      expect(escE(bytes).first.$1, lessThan(texte));
      expect(escE(bytes).last.$1, greaterThan(texte));
    });

    test('une ligne maigre n\'émet aucune accentuation', () {
      final bytes = EscPosTicketRenderer.renderRichLines(const [
        TicketLine('detail'),
      ], feedLines: 0);

      expect(escE(bytes), isEmpty);
    });

    /// Refermer à CHAQUE ligne, et pas par plages : n'importe quelle ligne peut
    /// être lue, retirée ou réordonnée sans laisser le mécanisme en gras.
    test('deux lignes grasses consécutives sont refermées chacune', () {
      final bytes = EscPosTicketRenderer.renderRichLines(const [
        TicketLine('UN', bold: true),
        TicketLine('DEUX', bold: true),
      ], feedLines: 0);

      expect(escE(bytes).map((e) => e.$2), [1, 0, 1, 0]);
    });

    /// La façade texte nu — celle qu'utilisent la sonde de page de code et le
    /// ticket de vente boutique — ne doit pas se mettre à graisser.
    test('la façade texte nu n\'émet jamais d\'accentuation', () {
      final bytes = EscPosTicketRenderer.renderLines(const [
        'TITRE',
        'detail',
      ], feedLines: 0);

      expect(escE(bytes), isEmpty);
    });

    test('un ticket entier ouvre et referme autant de fois', () {
      final bytes = EscPosTicketRenderer.render(_model());
      final marques = escE(bytes).map((e) => e.$2).toList();

      expect(marques, isNotEmpty);
      expect(marques.where((n) => n == 1).length, marques.length ~/ 2);
      // Alternance stricte : jamais deux ouvertures de suite.
      for (var i = 0; i < marques.length; i++) {
        expect(marques[i], i.isEven ? 1 : 0);
      }
    });

    /// L'invariant que le gras aurait pu casser : `ESC E` est une double frappe
    /// dans la MÊME cellule, donc la largeur ne bouge pas.
    test('le texte imprimé reste celui de la façade', () {
      final model = _model();
      for (final line in TicketTextLayout.renderRich(model)) {
        expect(line.text.length, lessThanOrEqualTo(48), reason: line.text);
      }
    });
  });
}
