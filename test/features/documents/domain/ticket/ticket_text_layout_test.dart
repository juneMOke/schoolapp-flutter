import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
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
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice:
      'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.',
);

TicketReceiptModel _model({
  String? matriculationNumber = 'MAT-0042',
  String? classroomName = '5e primaire A',
  String? cashierFullName = 'Jean Kabeya',
  int? remainingBalanceInCents = 250000,
  List<TicketAllocationLine> allocations = const [
    TicketAllocationLine(label: 'Frais scolaires', amountInCents: 120000),
    TicketAllocationLine(label: 'Fournitures', amountInCents: 30000),
  ],
}) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  schoolMunicipality: 'Kinshasa · Ngaliema',
  studentFullName: 'Mbala Kasa Amina',
  matriculationNumber: matriculationNumber,
  classroomName: classroomName,
  provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
  paidAt: DateTime(2026, 8, 4, 14, 7),
  cashierFullName: cashierFullName,
  amountReceivedInCents: 150000,
  allocations: allocations,
  remainingBalanceInCents: remainingBalanceInCents,
  currency: 'CDF',
  labels: _labels,
);

String _flat(List<String> lines) => lines.join('\n');

void main() {
  group('formatAmount', () {
    test('groupe les milliers et garde deux décimales', () {
      expect(TicketTextLayout.formatAmount(150000, 'CDF'), '1 500,00 CDF');
      expect(TicketTextLayout.formatAmount(1234567, 'CDF'), '12 345,67 CDF');
      expect(TicketTextLayout.formatAmount(5, 'CDF'), '0,05 CDF');
      expect(TicketTextLayout.formatAmount(0, 'CDF'), '0,00 CDF');
    });

    test('gère un montant négatif et une devise absente', () {
      expect(TicketTextLayout.formatAmount(-2500, 'USD'), '-25,00 USD');
      expect(TicketTextLayout.formatAmount(2500, '  '), '25,00');
    });
  });

  group('mise en page', () {
    test('aucune ligne ne dépasse la largeur demandée', () {
      for (final columns in const [32, 42, 48]) {
        final lines = TicketTextLayout.render(_model(), columns: columns);
        for (final line in lines) {
          expect(
            line.length,
            lessThanOrEqualTo(columns),
            reason: 'ligne trop longue à $columns colonnes : "$line"',
          );
        }
      }
    });

    test('porte l établissement, l élève et la référence', () {
      final out = _flat(TicketTextLayout.render(_model()));

      expect(out, contains('COMPLEXE SCOLAIRE LA COLOMBE'));
      expect(out, contains('Kinshasa'));
      expect(out, contains('MBALA KASA AMINA'));
      expect(out, contains('PROV-A1B2C3-9F8E7D6C'));
    });

    // RG-012-11 : sur une pièce non scellée, l'imputabilité humaine remplace
    // l'imputabilité cryptographique.
    test('nomme le caissier', () {
      expect(_flat(TicketTextLayout.render(_model())), contains('Jean Kabeya'));
    });

    // RG-012-12 : sans elle, l'établissement n'a aucun levier pour rappeler un
    // parent dont le versement poserait problème.
    test('porte la phrase de conservation', () {
      expect(
        _flat(TicketTextLayout.render(_model())),
        contains('Conservez ce ticket'),
      );
    });

    // Zone Z4 : aucun QR, jamais. Un code vérifiable sur une pièce non scellée
    // serait un mensonge.
    test('affiche le bandeau PROVISOIRE, pleine largeur', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final banner = lines.firstWhere((l) => l.contains('PROVISOIRE'));

      expect(banner.length, 48);
      expect(banner, startsWith('*'));
      expect(banner, endsWith('*'));
    });

    // RG-012-13 : le montant reçu et la répartition sont des FAITS (la
    // répartition est une saisie, pas un calcul) — seul le solde est incertain.
    test('ne met la réserve que sur le solde', () {
      final lines = TicketTextLayout.render(_model());
      final reservationIndex = lines.indexWhere(
        (l) => l.contains('sous réserve'),
      );
      final balanceIndex = lines.indexWhere((l) => l.contains('Solde'));
      final amountIndex = lines.indexWhere((l) => l.contains('Montant reçu'));

      expect(reservationIndex, greaterThan(balanceIndex));
      expect(balanceIndex, greaterThan(amountIndex));
      expect(lines[amountIndex], isNot(contains('sous réserve')));
    });

    test('imprime la répartition ligne à ligne', () {
      final out = _flat(TicketTextLayout.render(_model()));

      expect(out, contains('Frais scolaires'));
      expect(out, contains('1 200,00 CDF'));
      expect(out, contains('Fournitures'));
      expect(out, contains('300,00 CDF'));
    });

    test('aligne les montants à droite', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final line = lines.firstWhere((l) => l.contains('Montant reçu'));

      expect(line.length, 48);
      expect(line, endsWith('1 500,00 CDF'));
    });
  });

  group('ce que le local ne sait pas', () {
    // `students.matriculation_number` est NULL hors ligne PAR CONSTRUCTION : il
    // est attribué à l'ACK. Le ticket doit s'imprimer sans.
    test('omet le matricule inconnu au lieu d en inventer un', () {
      final out = _flat(
        TicketTextLayout.render(_model(matriculationNumber: null)),
      );

      expect(out, isNot(contains('Matricule')));
      expect(out, contains('MBALA KASA AMINA'));
    });

    test('omet la classe quand le roster n a pas été pullé', () {
      expect(
        _flat(TicketTextLayout.render(_model(classroomName: null))),
        isNot(contains('Classe')),
      );
    });

    test('omet le caissier plutôt que de laisser un libellé vide', () {
      expect(
        _flat(TicketTextLayout.render(_model(cashierFullName: null))),
        isNot(contains('Caissier')),
      );
    });

    // Mieux vaut omettre la ligne que d'imprimer un chiffre faux sur un papier
    // remis à un parent.
    test('omet le solde et sa réserve quand il n est pas calculable', () {
      final out = _flat(
        TicketTextLayout.render(_model(remainingBalanceInCents: null)),
      );

      expect(out, isNot(contains('Solde')));
      expect(out, isNot(contains('sous réserve')));
      expect(out, contains('Montant reçu'));
    });

    test('reste rendable sans aucune répartition', () {
      final out = _flat(TicketTextLayout.render(_model(allocations: const [])));

      expect(out, isNot(contains('Répartition')));
      expect(out, contains('Montant reçu'));
    });
  });

  // C'est l'invariant que le critère d'acceptation de l'ADR mesure : le même
  // modèle, rendu deux fois, produit exactement le même texte. Sans lui, la
  // « réimpression strictement identique » n'est pas vérifiable.
  test('deux rendus du même modèle sont identiques', () {
    final model = _model();

    expect(
      TicketTextLayout.render(model),
      equals(TicketTextLayout.render(model)),
    );
  });

  test('une référence plus longue que la ligne est coupée, pas tronquée', () {
    final lines = TicketTextLayout.render(_model(), columns: 24);
    final joined = _flat(lines).replaceAll('\n', '').replaceAll(' ', '');

    expect(joined, contains('PROV-A1B2C3-9F8E7D6C'));
  });

  // La police du ticket est une base-14 Latin-1 : tout ce qui en sort est
  // SUPPRIMÉ sans erreur. Le gabarit doit donc rendre le texte imprimable —
  // et le faire AVANT de mesurer, sinon `œ` → `oe` décale les colonnes.
  group('jeu de caractères', () {
    TicketReceiptModel exotic() => TicketReceiptModel(
      schoolName: 'Institut Sacré-Cœur d’Élite',
      schoolMunicipality: 'Kinshasa — Ngaliema',
      studentFullName: 'Lɔkɔ Ngɛlɛ Мбала',
      matriculationNumber: 'MAT—0042',
      classroomName: '5ᵉ primaire A',
      provisionalReference: 'PROV-A1B2C3',
      paidAt: DateTime(2026, 8, 4, 14, 7),
      cashierFullName: 'Ĳsselmeer Ǎmba',
      amountReceivedInCents: 150000,
      allocations: const [
        TicketAllocationLine(label: 'Frais “scolaires”', amountInCents: 120000),
      ],
      remainingBalanceInCents: 250000,
      currency: 'CDF',
      labels: _labels,
    );

    test('aucune ligne ne sort du Latin-1', () {
      for (final line in TicketTextLayout.render(exotic())) {
        expect(
          TicketCharset.isPrintable(line),
          isTrue,
          reason: 'ligne non imprimable : $line',
        );
      }
    });

    test('translittère au lieu de perdre le glyphe', () {
      final rendu = _flat(TicketTextLayout.render(exotic()));

      expect(rendu, contains('SACRÉ-COEUR'));
      expect(rendu, contains("D'ÉLITE"));
      expect(rendu, contains('LOKO NGELE'));
      // Ce qui n'a pas de translittération reste VISIBLE.
      expect(rendu, contains('?????'));
    });

    // L'invariant que la translittération pourrait casser : elle rallonge le
    // texte, donc elle doit précéder toute mesure de largeur.
    test('l\'alignement à 48 colonnes tient malgré l\'allongement', () {
      for (final line in TicketTextLayout.render(exotic())) {
        expect(line.length, lessThanOrEqualTo(48), reason: line);
      }
    });
  });
}
