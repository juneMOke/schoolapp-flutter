import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_sections.dart';

const _labels = SaleTicketLabels(
  documentTitle: 'Reçu de vente — Boutique',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  enteredAtLabel: 'Saisi le',
  cashierLabel: 'Caissier :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  articlesLabel: 'Articles',
  beneficiaryPrefix: 'pour',
  sizePrefix: 'T.',
  unitSuffix: '/u',
  totalLabel: 'Total',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  remainingLabel: 'Reste à payer',
  noRefundNotice: 'Aucun remboursement après remise de l\'article.',
  signatureLabel: 'Signature du caissier',
  verificationNotice: 'Scannez pour vérifier ce reçu',
  thanksNotice: 'Nous vous remercions pour votre confiance.',
  editorNotice: 'Reçu édité par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

const _school = TicketSchoolHeader(
  name: 'Complexe Scolaire La Colombe',
  address: '14, av. de la Justice',
  locality: 'Kinshasa',
  email: 'contact@colombe.cd',
  phone: '+243 810 000 000',
  tillPhone: '+243 811 111 111',
);

const _defaultLines = [
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
];

SaleTicketModel _model({
  TicketSchoolHeader school = _school,
  List<SaleTicketLine> lines = _defaultLines,
  List<TicketTenderLine>? tenders,
  String? cashier = 'Moke Junior',
  String? payer = 'Ndombo Lelo Willy',
  String? phone = '+243810220145',
  DateTime? issuedOn,
  String? verificationUrl,
}) => SaleTicketModel(
  school: school,
  receiptNumber: 'ETL-RV-2526-000413',
  soldAt: DateTime(2026, 8, 29, 11, 42),
  receiptIssuedOn: issuedOn,
  verificationUrl: verificationUrl,
  cashierFullName: cashier,
  payerFullName: payer,
  payerPhoneNumber: phone,
  lines: lines,
  tenders:
      tenders ??
      const [
        TicketTenderLine(
          amountInCents: 3500,
          currency: 'USD',
          pivotCurrency: 'USD',
        ),
      ],
  labels: _labels,
);

void main() {
  List<String> render({
    List<SaleTicketLine> lines = _defaultLines,
    List<TicketTenderLine>? tenders,
    String? cashier = 'Moke Junior',
    String? payer = 'Ndombo Lelo Willy',
    String? phone = '+243810220145',
    DateTime? issuedOn,
    String? verificationUrl,
  }) => SaleTicketTextLayout.render(
    _model(
      lines: lines,
      tenders: tenders,
      cashier: cashier,
      payer: payer,
      phone: phone,
      issuedOn: issuedOn,
      verificationUrl: verificationUrl,
    ),
  );

  group('l\'aspect du ticket de caisse', () {
    test('en-tête complet de l\'école, nom en gras', () {
      final rich = SaleTicketTextLayout.renderRich(_model());
      final ticket = rich.map((l) => l.text).join('\n');

      final name = rich.firstWhere(
        (l) => l.text.contains('COMPLEXE SCOLAIRE LA COLOMBE'),
      );
      expect(name.bold, isTrue);
      expect(ticket, contains('14, av. de la Justice'));
      expect(ticket, contains('Kinshasa'));
      expect(ticket, contains('contact@colombe.cd'));
      expect(ticket, contains('Tél. Promoteur : +243 810 000 000'));
      expect(ticket, contains('Tél. caisse : +243 811 111 111'));
    });

    test('le titre, puis la référence définitive', () {
      final ticket = render();

      expect(ticket.join('\n'), contains('REÇU DE VENTE - BOUTIQUE'));
      expect(ticket, contains('Réf. ETL-RV-2526-000413'));
    });

    test('aucune mention provisoire, nulle part', () {
      final ticket = render().join('\n').toLowerCase();

      expect(ticket, isNot(contains('provisoire')));
      expect(ticket, isNot(contains('prov-')));
      expect(ticket, isNot(contains('conservez')));
    });

    test('sans jour d\'émission, la vente tient la ligne « Date : »', () {
      final ticket = render();

      final date = ticket.firstWhere((l) => l.startsWith('Date :'));
      expect(date, contains('29/08/2026'));
      expect(date, endsWith('11:42'));
      expect(ticket.join('\n'), isNot(contains('Saisi le')));
    });

    test('avec le jour d\'émission, la vente passe en « Saisi le »', () {
      final ticket = render(issuedOn: DateTime(2026, 8, 30));

      expect(ticket, contains('Date : 30/08/2026'));
      final entered = ticket.firstWhere((l) => l.startsWith('Saisi le'));
      expect(entered, contains('29/08/2026'));
      expect(entered, endsWith('11:42'));
    });

    test('le caissier est nommé, puis la zone à signer', () {
      final rich = SaleTicketTextLayout.renderRich(_model());
      final ticket = rich.map((l) => l.text).toList();

      expect(ticket, contains('Caissier : Moke Junior'));
      final signature = rich.firstWhere(
        (l) => l.text == 'Signature du caissier',
      );
      expect(signature.bold, isTrue);
    });

    test('le pied ETEELO CONNECT ferme le ticket', () {
      final ticket = render();

      expect(ticket.last.trim(), 'eteeloconnect.com');
      expect(ticket.join('\n'), contains('Reçu édité par ETEELO CONNECT'));
      expect(
        ticket.join('\n'),
        contains('Nous vous remercions pour votre confiance.'),
      );
    });

    test('le QR n\'est posé qu\'avec une URL de vérification', () {
      const url = 'https://verify.eteeloconnect.com/d/q3Zr9Xb0c1D2e3F4g5H6iA';
      final withQr = SaleTicketTextLayout.renderRich(
        _model(verificationUrl: url),
      );
      final without = SaleTicketTextLayout.renderRich(_model());

      expect(withQr.where((l) => l.isQr).single.qrPayload, url);
      expect(
        withQr.map((l) => l.text.trim()),
        contains('Scannez pour vérifier ce reçu'),
      );
      expect(without.where((l) => l.isQr), isEmpty);
      expect(
        without.map((l) => l.text.trim()),
        isNot(contains('Scannez pour vérifier ce reçu')),
      );
    });
  });

  group('vente anonyme — le bloc payeur disparaît', () {
    test('ni nom ni numéro : aucune trace du payeur', () {
      final ticket = render(payer: null, phone: null).join('\n');

      expect(ticket, isNot(contains(_labels.payerLabel)));
      expect(ticket, isNot(contains('+243810220145')));
      expect(ticket, contains('Polo Lacoste'));
    });

    test('téléphone seul : le bloc reste, sans ligne de nom', () {
      final ticket = render(payer: null).join('\n');

      expect(ticket, contains('Tél. +243810220145'));
      expect(ticket, isNot(contains(_labels.payerLabel)));
    });

    test('nom seul : le bloc reste, sans ligne de numéro', () {
      final ticket = render(phone: null).join('\n');

      expect(ticket, contains('PAYEUR : NDOMBO LELO WILLY'));
      expect(ticket, isNot(contains('+243810220145')));
    });

    test('un nom vide vaut une absence', () {
      final ticket = render(payer: '   ', phone: null).join('\n');

      expect(ticket, isNot(contains(_labels.payerLabel)));
    });
  });

  group('l\'argent', () {
    test('« Montant reçu » en gras, et égal au total au comptant', () {
      final rich = SaleTicketTextLayout.renderRich(_model());
      final ticket = rich.map((l) => l.text).toList();

      final received = rich.firstWhere(
        (l) => l.text.startsWith('Montant reçu'),
      );
      expect(received.bold, isTrue);
      expect(received.text, endsWith('35,00 \$'));
      expect(
        ticket.firstWhere((l) => l.startsWith('Total')),
        endsWith('35,00 \$'),
      );
      expect(ticket.join('\n'), isNot(contains('Taux')));
    });

    test('un franc qui paie des dollars : le reçu en FC, et le taux', () {
      final ticket = render(
        tenders: const [
          TicketTenderLine(
            amountInCents: 9800000,
            currency: 'CDF',
            rateMicros: 2800 * ExchangeRate.scale,
            pivotCurrency: 'USD',
          ),
        ],
      );

      expect(
        ticket.firstWhere((l) => l.startsWith('Total')),
        endsWith('35,00 \$'),
      );
      expect(
        ticket.firstWhere((l) => l.startsWith('Montant reçu')),
        endsWith('98 000 FC'),
      );
      expect(
        ticket.firstWhere((l) => l.startsWith('Taux')),
        contains('FC / \$'),
      );
    });

    test('« Reste à payer » est TOUJOURS imprimé, à zéro', () {
      final ticket = render();

      expect(
        ticket.firstWhere((l) => l.startsWith('Reste à payer')),
        endsWith('0,00 \$'),
      );
    });

    test('deux devises au panier : un total et un reste par devise', () {
      final ticket = render(
        lines: const [
          SaleTicketLine(
            label: 'Polo',
            quantity: 1,
            unitPriceInCents: 1500,
            lineTotalInCents: 1500,
            currency: 'USD',
          ),
          SaleTicketLine(
            label: 'Manuel',
            quantity: 1,
            unitPriceInCents: 900000,
            lineTotalInCents: 900000,
            currency: 'CDF',
          ),
        ],
        tenders: const [
          TicketTenderLine(
            amountInCents: 1500,
            currency: 'USD',
            pivotCurrency: 'USD',
          ),
          TicketTenderLine(
            amountInCents: 900000,
            currency: 'CDF',
            pivotCurrency: 'CDF',
          ),
        ],
      );

      final remaining = ticket.indexWhere((l) => l.startsWith('Reste à payer'));
      expect(ticket[remaining], endsWith('0 FC'));
      expect(ticket[remaining + 1].trim(), '0,00 \$');
    });
  });

  group('le panier', () {
    test('un titre « Articles » en gras', () {
      final rich = SaleTicketTextLayout.renderRich(_model());

      expect(rich.firstWhere((l) => l.text == 'Articles').bold, isTrue);
    });

    test('un article à prix unique ne traîne ni niveau ni taille', () {
      final ticket = render();

      final index = ticket.indexWhere((l) => l.contains('Écusson brodé'));
      expect(ticket[index + 1].trim(), '10,00 \$ /u');
    });

    test('un article à grille porte son niveau, puis sa taille', () {
      final ticket = render();

      expect(ticket, contains('15,00 \$ /u - 1ère HUM - T. M'));
    });

    test('une ligne destinée à un enfant le nomme, sous l\'article', () {
      final ticket = render();
      final polo = ticket.indexWhere((l) => l.contains('Polo Lacoste'));
      expect(ticket[polo + 2], 'pour David Mwepu');
    });
  });

  test('la mention de non-remboursement est toujours là', () {
    expect(
      render().join('\n'),
      contains('Aucun remboursement après remise de l\'article.'),
    );
  });

  test('aucune ligne ne dépasse la largeur du rouleau', () {
    for (final columns in const [32, 48]) {
      for (final line in SaleTicketTextLayout.render(
        _model(verificationUrl: 'https://verify.eteeloconnect.com/d/abc'),
        columns: columns,
      )) {
        expect(line.length, lessThanOrEqualTo(columns), reason: line);
      }
    }
  });

  group('jeu de caractères', () {
    test('les accents Latin-1 sont CONSERVÉS', () {
      expect(render().join('\n'), contains('Écusson brodé'));
    });

    test('ce qui SORT du Latin-1 est translittéré avant la mise en page', () {
      final ticket = SaleTicketTextLayout.render(
        _model(school: const TicketSchoolHeader(name: 'Institut Sacré-Cœur')),
      ).join('\n');

      expect(ticket, contains('SACRÉ-COEUR'));
      expect(ticket, isNot(contains('Œ')));
    });
  });
}
