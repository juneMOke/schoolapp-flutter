import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_layout.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';

const _labels = TicketCancellationLabels(
  title: 'Ticket d\'annulation',
  receiptLabel: 'Reçu n°',
  cancelledMark: 'Annulé',
  issuedAtLabel: 'Émis le :',
  amountLabel: 'Montant annulé :',
  cancelledAtLabel: 'Annulé le :',
  reasonLabel: 'Motif :',
  detailLabel: 'Précision :',
  cashReturnedLabel: 'Argent rendu :',
  yes: 'Oui',
  no: 'Non',
  cancelledByLabel: 'Par :',
  classroomLabel: 'Classe :',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  reasons: {'REFUNDED': 'Argent rendu au payeur'},
);

TicketCancellationModel _model({
  String? detail,
  bool cashMoved = true,
  String? by = 'Jean Kabeya',
  MoneyBag? amount,
}) => TicketCancellationModel(
  schoolName: 'Collège La Fontaine',
  schoolTillPhone: '+243 810 000 000',
  receiptNumber: 'CF-RC-2627-000821',
  originalPaidAt: DateTime(2026, 10, 5, 12, 43),
  studentFullName: 'Mbala Kasa Amina',
  classroomName: '5e A',
  amount: amount ?? MoneyBag.of(const [Money(15000, 'USD')]),
  cancelledAt: DateTime(2026, 10, 6, 9, 12),
  reason: 'Argent rendu au payeur',
  reasonDetail: detail,
  cashMoved: cashMoved,
  cancelledByName: by,
  labels: _labels,
);

/// Le ticket d'annulation (continuité des tickets RC, lot B) : le papier qui
/// prend la place d'un ticket annulé dans la pile du promoteur.
void main() {
  String text(TicketCancellationModel model, {int columns = 48}) =>
      TicketCancellationLayout.render(model, columns: columns).join('\n');

  test('porte le numéro annulé et le dit, en gras', () {
    final lines = TicketCancellationLayout.renderRich(_model());

    final number = lines.firstWhere(
      (l) => l.text.contains('CF-RC-2627-000821'),
    );
    final mark = lines.firstWhere((l) => l.text.contains('ANNULÉ'));
    expect(number.bold, isTrue);
    expect(mark.bold, isTrue);
    expect(mark.text, contains('*'));
  });

  test('dit quand le reçu était émis et quand il a été annulé', () {
    final out = text(_model());

    expect(out, contains('05/10/2026'));
    expect(out, contains('12:43'));
    expect(out, contains('06/10/2026'));
    expect(out, contains('09:12'));
  });

  test('porte l élève, le montant, le motif, l argent et l auteur', () {
    final out = text(_model(detail: 'Doublon de caisse'));

    expect(out, contains('MBALA KASA AMINA'));
    expect(out, contains('Classe : 5e A'));
    expect(out, contains('Montant annulé :'));
    expect(out, contains('Motif : Argent rendu au payeur'));
    expect(out, contains('Précision : Doublon de caisse'));
    expect(out, contains('Argent rendu : Oui'));
    expect(out, contains('Par : Jean Kabeya'));
  });

  test('une ligne absente s escamote, l argent non rendu se dit', () {
    final out = text(_model(cashMoved: false, by: null));

    expect(out, isNot(contains('Précision')));
    expect(out, isNot(contains('Par :')));
    expect(out, contains('Argent rendu : Non'));
  });

  test('deux devises, deux lignes de montant', () {
    final out = text(
      _model(
        amount: MoneyBag.of(const [Money(15000, 'USD'), Money(5000000, 'CDF')]),
      ),
    );

    expect(out, contains(r'$'));
    expect(out, contains('FC'));
  });

  test('aucune ligne ne dépasse la largeur du papier', () {
    for (final columns in const [32, 48]) {
      final lines = TicketCancellationLayout.render(
        _model(detail: 'Une précision assez longue pour devoir se replier'),
        columns: columns,
      );
      for (final line in lines) {
        expect(line.length, lessThanOrEqualTo(columns), reason: line);
      }
    }
  });
}
