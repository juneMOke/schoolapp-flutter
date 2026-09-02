import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

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
  String? payer = 'Ndombo Lelo Willy',
  String? phone = '+243810220145',
}) => SaleTicketModel(
  schoolName: 'Complexe Scolaire La Colombe',
  schoolAddress: '14, av. de la Justice · Gombe · Kinshasa',
  reference: provisional ? 'PROV-000413' : 'ETL-RV-2526-000413',
  isProvisional: provisional,
  soldAt: DateTime(2026, 8, 29, 11, 42),
  cashierFullName: cashier,
  payerFullName: payer,
  payerPhoneNumber: phone,
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
          currency: 'USD',
        ),
        SaleTicketLine(
          label: 'Écusson brodé',
          quantity: 2,
          unitPriceInCents: 1000,
          lineTotalInCents: 2000,
          currency: 'USD',
        ),
      ],
  totals: MoneyBag.of(const [Money(3500, 'USD')]),
  labels: _labels,
);

void main() {
  List<String> render({
    bool provisional = true,
    List<SaleTicketLine>? lines,
    String? cashier = 'Moke Junior',
    String? payer = 'Ndombo Lelo Willy',
    String? phone = '+243810220145',
  }) => SaleTicketTextLayout.render(
    _model(
      provisional: provisional,
      lines: lines,
      cashier: cashier,
      payer: payer,
      phone: phone,
    ),
  );

  group('vente anonyme — le bloc payeur disparaît', () {
    /// Sur une pièce, un cadre laissé vide se lit comme une mention EFFACÉE, et
    /// invite à chercher ce qu'on aurait retiré. Mieux vaut n'avoir rien à lire
    /// que quelque chose à interpréter — et le reçu reste complet par ailleurs :
    /// articles, total et référence prouvent l'achat, qui est précisément ce que
    /// le porteur du papier vient prouver.
    test('ni nom ni numéro : aucune trace du payeur, et rien d\'autre ne '
        'bouge', () {
      final ticket = render(payer: null, phone: null).join('\n');

      expect(ticket, isNot(contains(_labels.payerLabel)));
      expect(ticket, isNot(contains(_labels.phoneLabel)));
      // La preuve d'achat, elle, est intacte.
      expect(ticket, contains('PROV-000413'));
      expect(ticket, contains('Polo Lacoste'));
      expect(ticket, contains(_labels.totalLabel));
    });

    /// Il a été TAPÉ, donc il désigne quelqu'un. Même règle que le reçu scellé
    /// rendu par le serveur : deux pièces du même acte qui ne disent pas la même
    /// chose se paient au premier rapprochement de caisse.
    test('téléphone seul : le bloc reste, sans ligne de nom', () {
      final ticket = render(payer: null).join('\n');

      expect(ticket, contains(_labels.phoneLabel));
      expect(ticket, contains('+243810220145'));
      expect(ticket, isNot(contains(_labels.payerLabel)));
    });

    test('nom seul : le bloc reste, sans ligne de numéro', () {
      final ticket = render(phone: null).join('\n');

      expect(ticket, contains(_labels.payerLabel));
      expect(ticket, contains('NDOMBO LELO WILLY'));
      expect(ticket, isNot(contains(_labels.phoneLabel)));
    });

    /// Le `''` que le pull écrivait avant la v43 vaut une absence, pas un nom.
    test('un nom vide vaut une absence', () {
      final ticket = render(payer: '   ', phone: null).join('\n');

      expect(ticket, isNot(contains(_labels.payerLabel)));
    });

    /// Le ticket doit rester imprimable : chaque ligne tient dans le rouleau,
    /// même quand un bloc entier a disparu.
    test('aucune ligne ne dépasse la largeur, payeur absent', () {
      for (final line in render(payer: null, phone: null)) {
        expect(
          line.length,
          lessThanOrEqualTo(SaleTicketTextLayout.defaultColumns),
          reason: 'ligne trop longue : "$line"',
        );
      }
    });
  });

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
            currency: 'USD',
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
            currency: 'USD',
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
            currency: 'USD',
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
              currency: 'USD',
            ),
          ],
          totals: MoneyBag.of(const [Money(100, 'USD')]),
          labels: _labels,
        ),
      ).join('\n');

      expect(ticket, contains('SACRÉ-COEUR'));
      expect(ticket, isNot(contains('Œ')));
    });
  });
}
