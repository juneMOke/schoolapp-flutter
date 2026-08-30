import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';

const _labels = SaleTicketLabels(
  documentTitle: 'Reçu de vente — Boutique',
  provisionalBanner: 'Document provisoire',
  provisionalNotice: 'Reçu définitif scellé à la synchronisation.',
  sealedNotice: 'Reçu scellé — vaut quittance',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  totalLabel: 'TOTAL',
  cashReceivedLabel: 'Espèces reçues',
  remainingLabel: 'Reste à payer',
  beneficiaryPrefix: 'pour',
  sizePrefix: 'T.',
  unitSuffix: '/u',
  noRefundNotice: 'Aucun remboursement après remise de l\'article.',
);

SaleTicketModel _model({
  bool provisional = true,
  List<SaleTicketLine>? lines,
  String? cashier = 'Moke Junior',
}) => SaleTicketModel(
  schoolName: 'Complexe Scolaire La Colombe',
  schoolAddress: '14, av. de la Justice · Gombe · Kinshasa',
  reference: provisional ? 'PROV-000413' : 'ETL-RV-2526-000413',
  isProvisional: provisional,
  soldAt: DateTime(2026, 8, 29, 11, 42),
  cashierFullName: cashier,
  payerFullName: 'Ndombo Lelo Willy',
  payerPhoneNumber: '+243810220145',
  lines:
      lines ??
      const [
        SaleTicketLine(
          label: 'Polo Lacoste',
          quantity: 1,
          unitPriceInCents: 1500,
          lineTotalInCents: 1500,
          levelLabel: '1ère HUM',
          size: 'M',
          beneficiaryName: 'David Mwepu',
        ),
        SaleTicketLine(
          label: 'Écusson brodé',
          quantity: 2,
          unitPriceInCents: 1000,
          lineTotalInCents: 2000,
        ),
      ],
  totalInCents: 3500,
  currency: 'USD',
  labels: _labels,
);

void main() {
  List<String> render({
    bool provisional = true,
    List<SaleTicketLine>? lines,
    String? cashier = 'Moke Junior',
  }) => SaleTicketTextLayout.render(
    _model(provisional: provisional, lines: lines, cashier: cashier),
  );

  test('aucune ligne ne dépasse la largeur du rouleau', () {
    // L'invariant sur lequel repose tout le gabarit : une ligne trop longue
    // s'enroule côté imprimante et décale la colonne des montants.
    for (final line in render()) {
      expect(
        line.length,
        lessThanOrEqualTo(SaleTicketTextLayout.defaultColumns),
        reason: line,
      );
    }
  });

  group('💀 la preuve du comptant intégral', () {
    test('« Reste à payer » est TOUJOURS imprimé, à zéro', () {
      // C'est la seule ligne qui atteste au porteur qu'il ne doit rien.
      // L'escamoter parce qu'elle vaut zéro lui retirerait cette preuve.
      final ticket = render().join('\n');

      expect(ticket, contains('Reste à payer'));
      expect(ticket, contains('0,00 \$'));
    });

    test('le montant reçu EST le total — jamais un écart', () {
      final ticket = render();
      final total = ticket.firstWhere((l) => l.startsWith('TOTAL'));
      final received = ticket.firstWhere((l) => l.startsWith('Espèces reçues'));

      expect(total, contains('35,00 \$'));
      expect(received, contains('35,00 \$'));
    });
  });

  group('méta de ligne — aucun séparateur orphelin', () {
    test('un article à prix unique ne traîne ni niveau ni taille', () {
      // Un « - » orphelin ferait chercher une information absente.
      final ticket = render(
        lines: const [
          SaleTicketLine(
            label: 'Écusson brodé',
            quantity: 2,
            unitPriceInCents: 1000,
            lineTotalInCents: 2000,
          ),
        ],
      );

      final meta = ticket.firstWhere((l) => l.contains('/u'));
      expect(meta.trim(), '10,00 \$ /u');
    });

    test('un article à grille porte son niveau, puis sa taille', () {
      final meta = render().firstWhere((l) => l.contains('1ère HUM'));

      expect(meta, contains('15,00 \$ /u'));
      expect(meta, contains('1ère HUM'));
      expect(meta, contains('T. M'));
    });

    test('un niveau sans taille ne traîne pas de séparateur final', () {
      final ticket = render(
        lines: const [
          SaleTicketLine(
            label: 'Polo',
            quantity: 1,
            unitPriceInCents: 1500,
            lineTotalInCents: 1500,
            levelLabel: '1ère HUM',
          ),
        ],
      );

      final meta = ticket.firstWhere((l) => l.contains('/u'));
      expect(meta.trim().endsWith('1ère HUM'), isTrue, reason: meta);
    });
  });

  group('bénéficiaire', () {
    test('une ligne destinée à un enfant le nomme, indenté', () {
      final ticket = render();

      expect(ticket.any((l) => l.contains('pour David Mwepu')), isTrue);
    });

    test('une ligne walk-in n\'invente personne', () {
      final ticket = render(
        lines: const [
          SaleTicketLine(
            label: 'Écusson',
            quantity: 1,
            unitPriceInCents: 1000,
            lineTotalInCents: 1000,
          ),
        ],
      ).join('\n');

      expect(ticket, isNot(contains('pour ')));
    });
  });

  group('provisoire vs scellé', () {
    test('un ticket provisoire le DIT deux fois', () {
      // Le bandeau se lit avant le contenu, la mention l'explique en bas : une
      // seule des deux et le porteur peut croire tenir la pièce définitive.
      final ticket = render().join('\n');

      expect(ticket, contains('DOCUMENT PROVISOIRE'));
      expect(ticket, contains('scellé à la synchronisation'));
    });

    test('un ticket scellé n\'a AUCUN bandeau provisoire', () {
      final ticket = render(provisional: false).join('\n');

      expect(ticket, isNot(contains('DOCUMENT PROVISOIRE')));
      expect(ticket, contains('vaut quittance'));
    });
  });

  test('le caissier est nommé — l\'imputabilité humaine', () {
    // Sur une pièce non scellée, elle remplace l'imputabilité cryptographique :
    // sans elle, un écart de tiroir ne s'arbitre pas.
    expect(render().join('\n'), contains('Caissier : Moke Junior'));
  });

  test('un caissier inconnu n\'empêche pas le ticket', () {
    // Mieux vaut un ticket sans caissier qu'aucune preuve remise au client.
    final ticket = render(cashier: null).join('\n');

    expect(ticket, isNot(contains('Caissier')));
    expect(ticket, contains('TOTAL'));
  });

  test('la mention de non-remboursement est toujours là', () {
    // Le seul levier de l'école quand l'article est déjà parti.
    expect(render().join('\n'), contains('Aucun remboursement'));
  });

  group('jeu de caractères', () {
    test('les accents Latin-1 sont CONSERVÉS', () {
      // Le rendu (PDF Courier comme ESC/POS) porte le Latin-1 : « é » s'imprime.
      // Le translittérer appauvrirait une pièce remise à une famille sans
      // aucune nécessité.
      expect(render().join('\n'), contains('Écusson brodé'));
    });

    test('ce qui SORT du Latin-1 est translittéré avant la mise en page', () {
      // `œ` → `oe` gagne un caractère : plier après la mise en colonnes
      // décalerait la colonne des montants. Et rien ne disparaît en silence —
      // une perte muette sur une pièce remise est le pire des comportements.
      final ticket = SaleTicketTextLayout.render(
        SaleTicketModel(
          schoolName: 'Institut Sacré-Cœur',
          reference: 'PROV-1',
          isProvisional: true,
          soldAt: DateTime(2026, 8, 29, 11, 42),
          payerFullName: 'Ndombo',
          lines: const [
            SaleTicketLine(
              label: 'Article',
              quantity: 1,
              unitPriceInCents: 100,
              lineTotalInCents: 100,
            ),
          ],
          totalInCents: 100,
          currency: 'USD',
          labels: _labels,
        ),
      ).join('\n');

      expect(ticket, contains('SACRÉ-COEUR'));
      expect(ticket, isNot(contains('Œ')));
    });
  });
}
