import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_charset.dart';
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
  keepTicketNotice:
      'Conservez ce ticket jusqu\'à la remise de votre reçu définitif.',
  thanksNotice: 'Nous vous remercions pour votre confiance.',
  editorNotice: 'Recu edite par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

/// Les mêmes libellés, le TITRE du bloc solde en moins.
///
/// Une traduction incomplète produit exactement cela, sans bruit : une chaîne
/// vide là où le gabarit attend une phrase.
final TicketLabels _labelsWithoutBalanceTitle = TicketLabels(
  documentTitle: _labels.documentTitle,
  provisionalMention: _labels.provisionalMention,
  referenceLabel: _labels.referenceLabel,
  dateLabel: _labels.dateLabel,
  payerLabel: _labels.payerLabel,
  phoneLabel: _labels.phoneLabel,
  cashierLabel: _labels.cashierLabel,
  studentLabel: _labels.studentLabel,
  matriculationLabel: _labels.matriculationLabel,
  classroomLabel: _labels.classroomLabel,
  amountReceivedLabel: _labels.amountReceivedLabel,
  rateLabel: _labels.rateLabel,
  derivedAmountPrefix: _labels.derivedAmountPrefix,
  allocationsLabel: _labels.allocationsLabel,
  advanceLabel: _labels.advanceLabel,
  balanceLabel: '',
  balanceTotalLabel: _labels.balanceTotalLabel,
  keepTicketNotice: _labels.keepTicketNotice,
  thanksNotice: _labels.thanksNotice,
  editorNotice: _labels.editorNotice,
  editorSite: _labels.editorSite,
);

TicketReceiptModel _model({
  String studentFullName = 'Mbala Kasa Amina',
  String? matriculationNumber = 'MAT-0042',
  String? classroomName = '5e primaire A',
  String? cashierFullName = 'Jean Kabeya',
  int? remainingBalanceInCents = 250000,

  /// Passe outre [remainingBalanceInCents] quand il est fourni — le seul moyen
  /// de composer un solde à DEUX devises, que la forme en centimes ne sait pas
  /// dire.
  MoneyBag? remainingBalance,
  List<TicketAllocationLine> remainingByCharge = const [],

  /// Permet de composer un ticket dont le TITRE de solde est vide — ce qu'une
  /// traduction incomplète produit sans bruit, et le seul cas où les deux
  /// filets du bloc pourraient se toucher.
  TicketLabels labels = _labels,
  List<TicketAllocationLine> allocations = const [
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
}) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  schoolLocality: 'Kinshasa · Ngaliema',
  studentFullName: studentFullName,
  matriculationNumber: matriculationNumber,
  classroomName: classroomName,
  reference: 'PROV-A1B2C3-9F8E7D6C',
  isProvisional: true,
  paidAt: DateTime(2026, 8, 4, 14, 7),
  cashierFullName: cashierFullName,
  tenders: TicketTenderLine.identityFrom(
    MoneyBag.of(const [Money(150000, 'CDF')]),
  ),
  allocations: allocations,
  remainingBalance:
      remainingBalance ??
      (remainingBalanceInCents == null
          ? null
          : MoneyBag.of([Money(remainingBalanceInCents, 'CDF')])),
  remainingByCharge: remainingByCharge,
  labels: labels,
);

/// Un solde à deux devises, détaillé — la forme que le porteur veut voir sur le
/// papier : « 5 000 FC + 309,00 $ ».
TicketReceiptModel _biDevise() => _model(
  remainingBalance: MoneyBag.of(const [
    Money(500000, 'CDF'),
    Money(30900, 'USD'),
  ]),
  remainingByCharge: const [
    TicketAllocationLine(
      label: 'Frais scolaires',
      amountInCents: 500000,
      currency: 'CDF',
    ),
    TicketAllocationLine(
      label: 'Organisation',
      amountInCents: 30900,
      currency: 'USD',
    ),
  ],
);

String _flat(List<String> lines) => lines.join('\n');

/// Vrai si deux lignes de séparation pleine largeur se suivent.
///
/// Hissé au niveau du fichier depuis le groupe « nom d'élève vide » : le bloc
/// solde pose désormais un filet de plus, et le défaut qu'il garde — deux
/// filets collés — n'appartient plus à un seul cas de figure.
bool _touchingRules(List<String> lines, int width) {
  final rule = '-' * width;
  for (var i = 0; i + 1 < lines.length; i++) {
    if (lines[i] == rule && lines[i + 1] == rule) return true;
  }
  return false;
}

/// Les montants imprimés dans le bloc ouvert par [heading], en centimes.
///
/// Relit le papier plutôt que le modèle : c'est la seule façon de vérifier que
/// ce qu'un parent additionne redonne bien ce qu'il a versé. Le bloc s'arrête à
/// la première ligne de séparation, celle qui précède le solde.
List<int> _amountsUnder(List<String> lines, String heading) {
  final start = lines.indexWhere((line) => line.trim() == heading);
  if (start < 0) return const [];

  final amounts = <int>[];
  // ⚠️ Le titre est suivi d'un FILET, et le bloc s'arrête au filet suivant : on
  // saute donc le premier. Sans ce saut, la lecture s'arrêterait immédiatement
  // et le test compterait zéro montant — vert sur une liste vide.
  for (final line in lines.skip(start + 2)) {
    if (line.startsWith('-') || line.trim().isEmpty) break;
    // Les décimales sont facultatives : le franc n'en porte que s'il en a
    // réellement, depuis que la règle d'écriture se décide sur la devise.
    final match = RegExp(r'([\d ]+)(?:,(\d{2}))?\s+FC\s*$').firstMatch(line);
    if (match == null) continue;
    final units = int.parse(match.group(1)!.replaceAll(' ', ''));
    amounts.add(units * 100 + int.parse(match.group(2) ?? '0'));
  }
  return amounts;
}

void main() {
  group('formatAmount', () {
    // Le ticket suit désormais la règle du socle : les décimales se décident
    // sur la DEVISE, et `CDF` s'écrit « FC ». Il imprimait jusqu'ici
    // « 1 500,00 CDF » — deux décimales sur une devise qui n'en a pas, et le
    // code ISO au lieu de l'abréviation que l'école emploie.
    test('le franc rond n\'a pas de décimales, et s\'écrit FC', () {
      expect(TicketTextLayout.formatAmount(150000, 'CDF'), '1 500 FC');
      expect(TicketTextLayout.formatAmount(0, 'CDF'), '0 FC');
    });

    test('un franc qui porte des centimes réels les garde', () {
      // Une convention d'écriture ne doit jamais arrondir sous les yeux du
      // lecteur — sur un ticket moins qu'ailleurs.
      expect(TicketTextLayout.formatAmount(1234567, 'CDF'), '12 345,67 FC');
      expect(TicketTextLayout.formatAmount(5, 'CDF'), '0,05 FC');
    });

    test('gère un montant négatif et une devise absente', () {
      expect(TicketTextLayout.formatAmount(-2500, 'USD'), r'-25,00 $');
      expect(TicketTextLayout.formatAmount(2500, '  '), '25,00');
    });

    test('groupe avec l\'espace ORDINAIRE, qu\'une ESC/POS sait rendre', () {
      expect(
        TicketTextLayout.formatAmount(150000, 'CDF').contains('\u00A0'),
        isFalse,
      );
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

    /// La pièce se nomme, sous l'en-tête et avant l'élève : le titre dit ce que
    /// c'est, et quelqu'un qui trie une liasse de fin de journée doit
    /// l'identifier sans lire le corps.
    ///
    /// ⚠️ « Ticket de perception », **jamais « note de perception »** — ce
    /// dernier nom désigne déjà une pièce annuelle scellée au niveau élève
    /// (`EditiqueDocumentType.notePerception`).
    ///
    /// La seconde moitié de ce test — « avant le bandeau » — a disparu avec le
    /// bandeau lui-même, pas avec sa règle : le titre garde sa place, il n'a
    /// simplement plus rien à précéder.
    test('se nomme sous l\'en-tête, avant l\'élève', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final titleIndex = lines.indexWhere(
        (l) => l.contains('TICKET DE PERCEPTION'),
      );
      final schoolIndex = lines.indexWhere((l) => l.contains('LA COLOMBE'));
      final studentIndex = lines.indexWhere((l) => l.contains('MBALA'));

      expect(titleIndex, greaterThan(schoolIndex));
      expect(titleIndex, lessThan(studentIndex));
    });

    /// Zone Z4 : aucun QR, jamais. Un code vérifiable sur une pièce non scellée
    /// serait un mensonge.
    ///
    /// Le **bandeau pleine largeur** qui vivait ici est supprimé : le ticket
    /// devient officiel dès qu'il porte un numéro définitif, et le cas non
    /// scellé porte désormais une mention discrète sur la ligne de référence.
    /// Ce qui reste à vérifier, c'est qu'aucun bandeau ne subsiste — assertion
    /// NÉGATIVE, sans quoi un gabarit qui poserait les deux passerait.
    test('n\'affiche plus aucun bandeau pleine largeur', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      for (final line in lines) {
        expect(line, isNot(startsWith('*')), reason: line);
      }
    });

    // RG-012-13 : le montant reçu et la répartition sont des FAITS (la
    // répartition est une saisie, pas un calcul) — seul le solde est incertain.
    // Le doute est donc porté par le TITRE du bloc solde, et par lui seul.
    test(
      'ne qualifie de « restant au moment de l\'impression » que le solde',
      () {
        final lines = TicketTextLayout.render(_model());
        final titleIndex = lines.indexWhere(
          (l) => l.contains('restant au moment de l\'impression'),
        );
        final amountIndex = lines.indexWhere((l) => l.contains('Montant reçu'));

        expect(titleIndex, greaterThan(amountIndex));

        // Assertion NÉGATIVE : aucune autre ligne ne porte le qualificatif. Sans
        // elle, un gabarit qui le remettrait sous le total passerait — c'est
        // exactement ce qu'on vient de retirer.
        expect(
          lines
              .where((l) => l.contains('restant au moment de l\'impression'))
              .length,
          1,
        );
        expect(lines[amountIndex], isNot(contains('au moment de')));
      },
    );

    /// La forme exacte du bloc, exigée par le porteur : ligne blanche, titre,
    /// détail indenté, filet, `Total`.
    ///
    /// Ancré sur les INDEX les uns par rapport aux autres, pas sur des numéros
    /// de ligne absolus : le bloc bouge dès qu'une ligne d'en-tête change, et
    /// un test qui compterait depuis le haut du papier casserait pour la
    /// mauvaise raison.
    test('le bloc solde : blanche, filet, titre, détail, filet, total', () {
      final lines = TicketTextLayout.render(_biDevise(), columns: 48);
      final title = lines.indexWhere(
        (l) => l.startsWith('Solde restant au moment de l\'impression'),
      );
      final total = lines.indexWhere((l) => l.startsWith('Total'));

      expect(title, greaterThan(1));
      // Le filet SÉPARE de la répartition, la blanche donne l'air au-dessus.
      expect(lines[title - 1], '-' * 48, reason: 'un filet ouvre le bloc');
      expect(lines[title - 2], '', reason: 'une ligne blanche le précède');
      expect(total, greaterThan(title));
      expect(lines[total - 1], '-' * 48, reason: 'un filet coiffe le total');

      // Entre le titre et le filet : le détail, indenté de deux espaces comme
      // les lignes de la répartition.
      for (var i = title + 1; i < total - 1; i++) {
        expect(lines[i], startsWith('  '), reason: lines[i]);
      }
      expect(
        total - 1 - (title + 1),
        greaterThan(0),
        reason: 'détail non vide',
      );
    });

    /// Le total sur UNE ligne, les deux devises reliées par un `+`.
    ///
    /// Le `+` porte du sens : il dit que ce sont deux montants DISTINCTS, non
    /// additionnés. Un simple espace les ferait lire comme un seul nombre.
    test('le total relie les devises par un +, avec le même formateur', () {
      final lines = TicketTextLayout.render(_biDevise(), columns: 48);
      final total = lines.firstWhere((l) => l.startsWith('Total'));

      expect(total, contains(' + '));
      expect(total.length, 48);
      // MÊME formateur que les lignes au-dessus : espace de groupement
      // ordinaire, « FC » et non « CDF », deux décimales sur le dollar et
      // aucune sur le franc.
      expect(total, endsWith('5 000 FC + 309,00 \$'));
    });

    /// Le `+` tient aussi sur le gabarit étroit : c'est la mesure qui a décidé
    /// de la forme, pas l'intention. « Total » + « 5 000 FC + 309,00 $ » fait
    /// 24 caractères pour 32 colonnes.
    test('à 32 colonnes, le total garde le + et rien ne déborde', () {
      final lines = TicketTextLayout.render(_biDevise(), columns: 32);
      final total = lines.firstWhere((l) => l.startsWith('Total'));

      expect(total, contains(' + '));
      expect(total.trimRight(), endsWith('5 000 FC + 309,00 \$'));
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(32), reason: line);
      }
    });

    /// Le repli, sur un solde que le papier étroit ne peut pas tenir sur une
    /// ligne : le total revient à UNE LIGNE PAR DEVISE — la seconde forme que
    /// le porteur accepte — au lieu de déborder la largeur.
    ///
    /// Le seuil est mesuré : à 32 colonnes, `Total` laisse 26 caractères à la
    /// valeur. « 10 000 000 FC + 10 000,00 $ » en fait 27.
    test(
      'un solde trop large pour 32 colonnes repasse à une ligne par devise',
      () {
        final lines = TicketTextLayout.render(
          _model(
            remainingBalance: MoneyBag.of(const [
              Money(1000000000, 'CDF'),
              Money(1000000, 'USD'),
            ]),
            remainingByCharge: const [
              TicketAllocationLine(
                label: 'Frais scolaires',
                amountInCents: 1000000000,
                currency: 'CDF',
              ),
            ],
          ),
          columns: 32,
        );

        final total = lines.indexWhere((l) => l.startsWith('Total'));
        expect(total, greaterThan(0));
        expect(lines[total], isNot(contains(' + ')));
        expect(lines[total].trimRight(), endsWith('10 000 000 FC'));
        // La seconde devise sur la ligne suivante, sans répéter le libellé.
        expect(lines[total + 1].trimRight(), endsWith('10 000,00 \$'));
        expect(lines[total + 1].trimLeft(), isNot(startsWith('Total')));

        // Ce que le repli d'`addPair` n'aurait pas donné : aucune ligne ne
        // dépasse la largeur du papier.
        for (final line in lines) {
          expect(line.length, lessThanOrEqualTo(32), reason: line);
        }
      },
    );

    /// Le filet neuf du bloc solde ne colle jamais à un autre.
    ///
    /// Le cas à surveiller n'est pas celui qu'on imprime d'ordinaire : c'est le
    /// solde SANS détail. Le bloc se réduit alors à « titre / filet / total »,
    /// et il suffirait que le total cesse d'émettre une ligne — un `bag` vide
    /// mal gardé, un repli qui rendrait tôt — pour que le filet du bloc et
    /// celui qui ferme la zone se retrouvent collés.
    test('le filet du solde ne touche aucun autre filet', () {
      final shapes = <String, TicketReceiptModel>{
        'solde à deux devises, détaillé': _biDevise(),
        'solde simple, détaillé': _model(
          remainingByCharge: const [
            TicketAllocationLine(
              label: 'Frais scolaires',
              amountInCents: 250000,
              currency: 'CDF',
            ),
          ],
        ),
        'solde SANS détail': _model(),
        'aucun solde': _model(remainingBalanceInCents: null),
        'aucun solde, aucune répartition': _model(
          remainingBalanceInCents: null,
          allocations: const [],
        ),
        // ⚠️ LA forme dangereuse. Le titre est ce qui sépare le filet
        // d'ouverture du bloc de celui qui coiffe le total ; vidé, il les
        // laisserait se toucher. Le gabarit pose les deux ensemble ou aucun.
        'titre de solde vide': _model(
          labels: _labelsWithoutBalanceTitle,
          remainingByCharge: const [
            TicketAllocationLine(
              label: 'Frais scolaires',
              amountInCents: 250000,
              currency: 'CDF',
            ),
          ],
        ),
        'titre de solde vide, sans détail': _model(
          labels: _labelsWithoutBalanceTitle,
        ),
      };

      shapes.forEach((name, model) {
        for (final columns in const [32, 48]) {
          final lines = TicketTextLayout.render(model, columns: columns);
          expect(
            _touchingRules(lines, columns),
            isFalse,
            reason: '$name, à $columns colonnes',
          );
        }
      });
    });

    test('imprime la répartition ligne à ligne', () {
      final out = _flat(TicketTextLayout.render(_model()));

      expect(out, contains('Frais scolaires'));
      expect(out, contains('1 200 FC'));
      expect(out, contains('Fournitures'));
      expect(out, contains('300 FC'));
    });

    test('aligne les montants à droite', () {
      final lines = TicketTextLayout.render(_model(), columns: 48);
      final line = lines.firstWhere((l) => l.contains('Montant reçu'));

      expect(line.length, 48);
      expect(line, endsWith('1 500 FC'));
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

    /// ⚠️ Tests de CARACTÉRISATION — ils figent le comportement actuel, ils ne
    /// demandent PAS de le corriger.
    ///
    /// Le gabarit est le contrat partagé des deux sorties (ESC/POS et PDF), et
    /// l'identité de leur rendu est verrouillée par le critère d'acceptation de
    /// l'ADR-012 (« deux rendus du même modèle sont identiques », plus bas). Y
    /// glisser une ligne de garde — un « élève inconnu », une ligne blanche —
    /// changerait le papier des DEUX sorties et se lirait comme une donnée que
    /// l'établissement affirme, alors que c'est une donnée qui manque.
    ///
    /// C'est pourquoi le refus vit en AMONT, dans
    /// `provisional_ticket_print_flow.dart` : on ne rend pas le trou joli, on
    /// n'imprime pas. Ce qui suit existe pour qu'un lecteur futur voie
    /// exactement ce que ce papier dirait, et ne « corrige » pas le gabarit en
    /// croyant bien faire.
    group('nom d\'élève vide — ce que la garde amont évite', () {
      test('ne produit pas une ligne blanche : il ne produit AUCUNE ligne', () {
        final lines = TicketTextLayout.render(
          _model(
            studentFullName: '',
            matriculationNumber: null,
            classroomName: null,
          ),
          columns: 48,
        );

        // `_wrapped('')` rend une liste VIDE : la zone Z2 ne laisse pas de
        // trace, pas même une ligne d'espaces. Les deux séparateurs qui
        // l'encadraient se retrouvent collés, juste sous le titre.
        //
        // ⚠️ Ancré sur le TITRE et non sur le bandeau disparu. Avec l'ancien
        // repère, `indexWhere` rendrait -1, le test lirait `lines[0]`/`lines[1]`
        // et passerait peut-être — en mesurant tout autre chose.
        final title = lines.indexWhere(
          (l) => l.contains('TICKET DE PERCEPTION'),
        );
        expect(title, greaterThanOrEqualTo(0));
        final rule = '-' * 48;
        expect(lines[title + 1], rule);
        expect(lines[title + 2], rule);
        expect(_touchingRules(lines, 48), isTrue);
        // Rien, sur ce papier, ne signale qu'un nom manque.
        expect(_flat(lines), isNot(contains('MBALA')));
      });

      test('le ticket sort quand même, entier et cohérent', () {
        final out = _flat(
          TicketTextLayout.render(
            _model(
              studentFullName: '',
              matriculationNumber: null,
              classroomName: null,
            ),
          ),
        );

        // Voilà le vrai danger : rien ne casse. Le gabarit ne lève pas, la
        // référence, le montant et la phrase de conservation sont là — le papier
        // a toute l'apparence d'un justificatif, sauf qu'il n'atteste personne.
        expect(out, contains('Réf.'));
        expect(out, contains('Montant reçu'));
        expect(out, contains('Conservez ce ticket'));
      });

      /// La nuance qui explique la forme exacte de la garde amont : elle porte
      /// sur `studentFullName` SEUL, jamais sur « la zone Z2 est vide ».
      test('une classe hydratée sans le nom : les rules ne se touchent pas', () {
        final lines = TicketTextLayout.render(
          _model(studentFullName: '', matriculationNumber: null),
          columns: 48,
        );

        // « ---- / Classe : … / ---- » : la zone Z2 n'est pas vide, le ticket
        // a même l'air normal. Il reste anonyme. Une garde qui aurait testé le
        // bloc entier laisserait donc passer ce cas-là.
        expect(_touchingRules(lines, 48), isFalse);
        expect(_flat(lines), contains('Classe : 5e primaire A'));
        expect(_flat(lines), isNot(contains('MBALA')));
      });
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
              TicketAllocationLine(
                label: 'Minerval',
                amountInCents: 120000,
                currency: 'CDF',
              ),
            ],
          ),
        ),
      );

      expect(out, contains('Avance'));
      expect(out, contains('300 FC'));
    });

    test('la ventilation imprimée somme au montant reçu', () {
      final lines = TicketTextLayout.render(
        _model(
          allocations: const [
            TicketAllocationLine(
              label: 'Minerval',
              amountInCents: 100000,
              currency: 'CDF',
            ),
            TicketAllocationLine(
              label: 'Assurance',
              amountInCents: 20000,
              currency: 'CDF',
            ),
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
              TicketAllocationLine(
                label: 'Minerval',
                amountInCents: 150000,
                currency: 'CDF',
              ),
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
              TicketAllocationLine(
                label: 'Minerval',
                amountInCents: 200000,
                currency: 'CDF',
              ),
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
      schoolLocality: 'Kinshasa — Ngaliema',
      studentFullName: 'Lɔkɔ Ngɛlɛ Мбала',
      matriculationNumber: 'MAT—0042',
      classroomName: '5ᵉ primaire A',
      reference: 'PROV-A1B2C3',
      isProvisional: true,
      paidAt: DateTime(2026, 8, 4, 14, 7),
      cashierFullName: 'Ĳsselmeer Ǎmba',
      tenders: TicketTenderLine.identityFrom(
        MoneyBag.of(const [Money(150000, 'CDF')]),
      ),
      allocations: const [
        TicketAllocationLine(
          label: 'Frais “scolaires”',
          amountInCents: 120000,
          currency: 'CDF',
        ),
      ],
      remainingBalance: MoneyBag.of(const [Money(250000, 'CDF')]),
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
