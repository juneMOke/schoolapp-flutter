import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// L'en-tête complet, la ligne « Date : » et le bloc payeur.
///
/// Les **replis** sont le vrai sujet de ce fichier. Le gabarit ne décide de
/// presque rien quand tout est renseigné ; c'est sur les champs absents qu'il
/// décide — et une ligne blanche sur une pièce se lit comme une mention
/// effacée, pas comme une donnée manquante.
const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalMention: 'provisoire',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  derivedAmountPrefix: 'soit',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance',
  balanceLabel: 'Solde restant au moment de l\'impression',
  balanceTotalLabel: 'Total',
  keepTicketNotice: 'Conservez ce ticket.',
  thanksNotice: 'Merci.',
  editorNotice: 'Recu edite par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

TicketReceiptModel _model({
  String schoolName = 'Complexe scolaire La Colombe',
  String? schoolAddress = '12, avenue de la Liberation',
  String? schoolLocality = 'Kinshasa',
  String? schoolEmail = 'secretariat@lacolombe.cd',
  String? schoolPhone = '+243900000000',
  String? payerFullName,
  String? payerPhoneNumber,
  bool isProvisional = true,
  String reference = 'PROV-A1B2C3-9F8E7D6C',
}) => TicketReceiptModel(
  schoolName: schoolName,
  schoolAddress: schoolAddress,
  schoolLocality: schoolLocality,
  schoolEmail: schoolEmail,
  schoolPhone: schoolPhone,
  studentFullName: 'Mbala Kasa Amina',
  classroomName: '5e primaire A',
  reference: reference,
  isProvisional: isProvisional,
  paidAt: DateTime(2026, 9, 8, 1, 35),
  cashierFullName: 'Jean Kabeya',
  payerFullName: payerFullName,
  payerPhoneNumber: payerPhoneNumber,
  tenders: TicketTenderLine.identityFrom(
    MoneyBag.of(const [Money(150000, 'CDF')]),
  ),
  labels: _labels,
);

/// Index de la première ligne qui contient [needle], ou `-1`.
int _indexOf(List<String> lines, String needle) =>
    lines.indexWhere((l) => l.contains(needle));

void main() {
  group('en-tête de l\'établissement', () {
    test('les cinq lignes sortent dans l\'ordre, puis le filet', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);

      final name = _indexOf(lines, 'COMPLEXE SCOLAIRE LA COLOMBE');
      final address = _indexOf(lines, 'avenue de la Liberation');
      final locality = _indexOf(lines, 'Kinshasa');
      final email = _indexOf(lines, 'secretariat@lacolombe.cd');
      final phone = _indexOf(lines, '+243900000000');

      expect(name, 0);
      expect(address, name + 1);
      expect(locality, address + 1);
      expect(email, locality + 1);
      expect(phone, email + 1);
      expect(lines[phone + 1], '-' * 48);
    });

    test('chaque ligne est centrée', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final email = lines[_indexOf(lines, 'secretariat')];
      expect(email, startsWith(' '));
      expect(email.trim(), 'secretariat@lacolombe.cd');
    });

    /// Le repli qui décide vraiment : un champ absent n'ajoute AUCUNE ligne.
    /// `wrapped('')` rend une liste vide, donc rien n'est à garder à la main —
    /// mais si quelqu'un remplaçait `_centered(x ?? '')` par un `_centered(x!)`
    /// gardé, ce test le dirait.
    test('un champ absent ne laisse pas de ligne blanche', () {
      final lines = TicketTextLayout.render(
        _model(schoolAddress: null, schoolEmail: null),
        columns: 48,
      );

      // Aucune ligne vide ni faite d'espaces avant le premier filet.
      final rule = lines.indexOf('-' * 48);
      expect(rule, greaterThan(0));
      for (final line in lines.take(rule)) {
        expect(line.trim(), isNotEmpty, reason: 'ligne blanche : «$line»');
      }
      // Et l'en-tête a bien RÉTRÉCI, il ne s'est pas troué.
      expect(rule, 3);
    });

    test('école réduite au nom seul : une ligne, puis le filet', () {
      final lines = TicketTextLayout.render(
        _model(
          schoolAddress: null,
          schoolLocality: null,
          schoolEmail: null,
          schoolPhone: null,
        ),
        columns: 48,
      );
      expect(lines.first.trim(), 'COMPLEXE SCOLAIRE LA COLOMBE');
      expect(lines[1], '-' * 48);
    });

    /// Le référentiel non pullé : le repository compose alors un nom vide.
    /// Le ticket doit sortir quand même — il vaut par son montant, pas par son
    /// en-tête.
    test('référentiel absent : le ticket sort, sans en-tête', () {
      final lines = TicketTextLayout.render(
        _model(
          schoolName: '',
          schoolAddress: null,
          schoolLocality: null,
          schoolEmail: null,
          schoolPhone: null,
        ),
        columns: 48,
      );
      expect(lines.first, '-' * 48);
      expect(lines.join('\n'), contains('Montant reçu'));
    });

    /// Rien ne tronque jamais : une adresse trop longue se replie sur deux
    /// lignes centrées, et la concaténation redonne le texte.
    test('une adresse trop longue se replie sans rien perdre', () {
      const long =
          '145 bis, avenue du Commerce prolongee, quartier Matonge II, '
          'commune de Kalamu';
      final lines = TicketTextLayout.render(
        _model(schoolAddress: long),
        columns: 48,
      );
      final rule = lines.indexOf('-' * 48);
      final header = lines.take(rule).map((l) => l.trim()).join(' ');
      expect(header, contains(long));
      for (final line in lines.take(rule)) {
        expect(line.length, lessThanOrEqualTo(48));
      }
    });

    test('32 colonnes : aucune ligne ne déborde', () {
      final lines = TicketTextLayout.render(_model(), columns: 32);
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(32), reason: line);
      }
    });
  });

  group('la ligne Date', () {
    /// Le libellé n'existait pas : la date occupait le créneau de gauche sans
    /// être nommée. L'heure reste à droite, sur la MÊME ligne — la décision
    /// tient à ce qu'aucune ligne de papier ne soit ajoutée.
    test('le libellé coiffe la date, l\'heure reste à droite', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final line = lines.firstWhere((l) => l.contains('Date :'));

      expect(line, startsWith('Date : 08/09/2026'));
      expect(line, endsWith('01:35'));
      expect(line.length, 48);
    });

    test('à 32 colonnes elle tient encore sur une ligne', () {
      final lines = TicketTextLayout.render(_model(), columns: 32);
      final line = lines.firstWhere((l) => l.contains('Date :'));
      expect(line, startsWith('Date : 08/09/2026'));
      expect(line, endsWith('01:35'));
    });
  });

  group('le bloc payeur', () {
    test('nom et téléphone sortent, suivis du filet', () {
      final lines = TicketTextLayout.render(
        _model(payerFullName: 'Mbala Kasa Papa', payerPhoneNumber: '+2438100'),
        columns: 48,
      );
      final payer = _indexOf(lines, 'PAYEUR :');
      expect(lines[payer], contains('MBALA KASA PAPA'));
      expect(lines[payer + 1], contains('Tél. +2438100'));
      expect(lines[payer + 2], '-' * 48);
    });

    /// Le bloc ENTIER disparaît — et surtout **pas de filet orphelin**, qui
    /// laisserait deux séparateurs collés et se lirait comme un bloc retiré.
    test('sans payeur, le bloc entier disparaît', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      expect(lines.join('\n'), isNot(contains('PAYEUR')));
      expect(lines.join('\n'), isNot(contains('Tél.')));

      final rule = '-' * 48;
      for (var i = 0; i < lines.length - 1; i++) {
        expect(
          lines[i] == rule && lines[i + 1] == rule,
          isFalse,
          reason: 'deux filets collés en $i',
        );
      }
    });

    /// Un numéro seul a été TAPÉ, donc il désigne quelqu'un. C'est le cas
    /// limite qu'une implémentation naïve casse en testant le seul nom.
    test('un téléphone seul garde le bloc', () {
      final lines = TicketTextLayout.render(
        _model(payerPhoneNumber: '+243810000000'),
        columns: 48,
      );
      expect(lines.join('\n'), contains('Tél. +243810000000'));
      expect(lines.join('\n'), isNot(contains('PAYEUR :')));
    });

    test('un nom seul garde le bloc, sans ligne de téléphone', () {
      final lines = TicketTextLayout.render(
        _model(payerFullName: 'Mbala Kasa Papa'),
        columns: 48,
      );
      expect(lines.join('\n'), contains('PAYEUR : MBALA KASA PAPA'));
      expect(lines.join('\n'), isNot(contains('Tél.')));
    });

    test('un nom composé long se replie sans troncature', () {
      const long = 'Mbala Kasa Papa Jean-Baptiste Ngoy Wa Kabasele Tshilombo';
      final lines = TicketTextLayout.render(
        _model(payerFullName: long),
        columns: 48,
      );
      final payer = _indexOf(lines, 'PAYEUR :');
      final joined = [
        lines[payer],
        lines[payer + 1],
      ].map((l) => l.trim()).join(' ');
      expect(joined, contains(long.toUpperCase()));
    });
  });

  group('la mention provisoire', () {
    /// Elle s'accole au LIBELLÉ, pas à la fin de la ligne : ainsi elle qualifie
    /// le NUMÉRO. L'argent, lui, est reçu — et le ticket l'affirme.
    test('non scellé : la mention coiffe la référence', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final ref = lines.firstWhere((l) => l.contains('Réf.'));
      expect(ref, startsWith('Réf. provisoire PROV-A1B2C3-9F8E7D6C'));
    });

    /// Assertion NÉGATIVE explicite : sans elle, un gabarit qui poserait à la
    /// fois la mention et un bandeau passerait le test précédent.
    test('non scellé : aucun bandeau pleine largeur ne subsiste', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      for (final line in lines) {
        expect(line, isNot(startsWith('*')), reason: line);
      }
    });

    test('scellé : la référence est nue', () {
      final lines = TicketTextLayout.render(
        _model(isProvisional: false, reference: 'ETL-RC-2526-000212'),
        columns: 48,
      );
      final ref = lines.firstWhere((l) => l.contains('Réf.'));
      expect(ref, 'Réf. ETL-RC-2526-000212');
      expect(lines.join('\n'), isNot(contains('provisoire')));
    });

    /// Le repli sur l'UUID du paiement, qui est le cas où l'ancienne forme à
    /// parenthèse se coupait en deux. Ici la coupure tombe entre le libellé et
    /// le numéro : rien d'orphelin, rien de tronqué.
    test('le repli sur l\'UUID se replie proprement', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final lines = TicketTextLayout.render(
        _model(reference: uuid),
        columns: 48,
      );
      final first = lines.indexWhere((l) => l.contains('Réf.'));
      expect(lines[first].trim(), 'Réf. provisoire');
      expect(lines[first + 1].trim(), uuid);
    });
  });
}
