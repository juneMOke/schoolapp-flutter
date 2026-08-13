import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
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

/// Les montants imprimés dans le bloc ouvert par [heading], en centimes.
///
/// Relit le papier plutôt que le modèle : c'est la seule façon de vérifier que
/// ce qu'un parent additionne redonne bien ce qu'il a versé. Le bloc s'arrête à
/// la première ligne de séparation, celle qui précède le solde.
List<int> _amountsUnder(List<String> lines, String heading) {
  final start = lines.indexWhere((line) => line.trim() == heading);
  if (start < 0) return const [];

  final amounts = <int>[];
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('-') || line.trim().isEmpty) break;
    final match = RegExp(r'([\d ]+),(\d{2})\s+CDF\s*$').firstMatch(line);
    if (match == null) continue;
    final units = int.parse(match.group(1)!.replaceAll(' ', ''));
    amounts.add(units * 100 + int.parse(match.group(2)!));
  }
  return amounts;
}

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

    /// La pièce se nomme, et se nomme **avant** de se qualifier : le titre dit
    /// ce que c'est, le bandeau dit dans quel état c'est. Quelqu'un qui trie une
    /// liasse de fin de journée doit l'identifier sans lire le corps.
    ///
    /// ⚠️ « Ticket de perception », **jamais « note de perception »** — ce
    /// dernier nom désigne déjà une pièce annuelle scellée au niveau élève
    /// (`EditiqueDocumentType.notePerception`).
    test('se nomme en tête, avant le bandeau', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final titleIndex = lines.indexWhere(
        (l) => l.contains('TICKET DE PERCEPTION'),
      );
      final bannerIndex = lines.indexWhere((l) => l.contains('PROVISOIRE'));
      final schoolIndex = lines.indexWhere((l) => l.contains('LA COLOMBE'));

      expect(titleIndex, greaterThan(schoolIndex));
      expect(titleIndex, lessThan(bannerIndex));
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

  /// Le ticket **atteste le montant perçu** ; il n'arbitre pas son imputation,
  /// c'est le reçu scellé qui fait apparaître le trop-perçu. Reste qu'un écart
  /// entre le reçu et la ventilation imprimée ne peut pas être MUET : un parent
  /// qui additionne trouverait un trou, et un trou se lit comme une erreur de
  /// caisse.
  group('avance — la part reçue que rien n\'absorbe', () {
    test('un versement supérieur au dû imprime son avance', () {
      final out = _flat(
        TicketTextLayout.render(
          // 150 000 reçus, 120 000 imputés.
          _model(
            allocations: const [
              TicketAllocationLine(label: 'Minerval', amountInCents: 120000),
            ],
          ),
        ),
      );

      expect(out, contains('Avance'));
      expect(out, contains('300,00 CDF'));
    });

    test('la ventilation imprimée somme au montant reçu', () {
      final lines = TicketTextLayout.render(
        _model(
          allocations: const [
            TicketAllocationLine(label: 'Minerval', amountInCents: 100000),
            TicketAllocationLine(label: 'Assurance', amountInCents: 20000),
          ],
        ),
      );

      // C'est tout l'intérêt de la poser DANS la répartition plutôt qu'à côté :
      // additionner ce qui est imprimé redonne exactement le montant reçu.
      final printed = _amountsUnder(lines, 'Répartition');
      expect(printed.fold<int>(0, (sum, cents) => sum + cents), 150000);
    });

    test('rien à dire quand tout est imputé', () {
      final out = _flat(
        TicketTextLayout.render(
          _model(
            allocations: const [
              TicketAllocationLine(label: 'Minerval', amountInCents: 150000),
            ],
          ),
        ),
      );

      expect(out, isNot(contains('Avance')));
    });

    test('une ventilation SUPÉRIEURE au reçu n\'invente pas d\'avance', () {
      final out = _flat(
        TicketTextLayout.render(
          _model(
            allocations: const [
              TicketAllocationLine(label: 'Minerval', amountInCents: 200000),
            ],
          ),
        ),
      );

      // Saisie incohérente : on ne l'habille pas d'un libellé qui la ferait
      // passer pour normale, et surtout pas d'une avance négative. Le test vise
      // les MONTANTS : les lignes de séparation du gabarit sont faites de
      // tirets, et les compter comme des signes moins ne prouverait rien.
      expect(out, isNot(contains('Avance')));
      expect(RegExp(r'-\d[\d ]*,\d{2}').hasMatch(out), isFalse);
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
