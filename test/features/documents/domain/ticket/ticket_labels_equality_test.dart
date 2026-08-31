import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

const _base = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalBanner: 'Provisoire',
  referenceLabel: 'Réf.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance (non imputée)',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice: 'Conservez ce ticket.',
);

/// `TicketLabels` est comparé par valeur, et cette comparaison remonte jusqu'au
/// modèle entier : `TicketReceiptModel.props` embarque `labels`. Un champ oublié
/// dans `props` rend donc **le ticket entier** aveugle à ce libellé — deux
/// tickets qui n'ont ni le même titre ni la même ventilation se déclarent
/// identiques.
///
/// L'omission est déjà arrivée, et sur les deux derniers libellés ajoutés :
/// exactement ceux dont une régression serait invisible, puisque rien d'autre
/// ne les surveille.
void main() {
  test('chaque libellé compte dans l\'égalité', () {
    // Un cas par champ : si un seul manque à `props`, sa variante compare égale
    // à la base et le test le nomme.
    final variants = <String, TicketLabels>{
      'documentTitle': _copyWith(documentTitle: 'Autre pièce'),
      'provisionalBanner': _copyWith(provisionalBanner: 'Définitif'),
      'referenceLabel': _copyWith(referenceLabel: 'Ref'),
      'cashierLabel': _copyWith(cashierLabel: 'Agent :'),
      'studentLabel': _copyWith(studentLabel: 'Enfant :'),
      'matriculationLabel': _copyWith(matriculationLabel: 'Mat :'),
      'classroomLabel': _copyWith(classroomLabel: 'Salle :'),
      'amountReceivedLabel': _copyWith(amountReceivedLabel: 'Reçu'),
      'allocationsLabel': _copyWith(allocationsLabel: 'Détail'),
      'advanceLabel': _copyWith(advanceLabel: 'Excédent'),
      'balanceLabel': _copyWith(balanceLabel: 'Reste'),
      'balanceReservation': _copyWith(balanceReservation: 'à confirmer'),
      'keepTicketNotice': _copyWith(keepTicketNotice: 'Gardez ce papier.'),
    };

    for (final entry in variants.entries) {
      expect(
        entry.value,
        isNot(_base),
        reason: '`${entry.key}` est absent de TicketLabels.props',
      );
    }
  });

  test('la cécité se propagerait au modèle entier', () {
    final model = _model(_base);
    final renamed = _model(_copyWith(documentTitle: 'Autre pièce'));

    expect(model, isNot(renamed));
  });
}

TicketLabels _copyWith({
  String? documentTitle,
  String? provisionalBanner,
  String? referenceLabel,
  String? cashierLabel,
  String? studentLabel,
  String? matriculationLabel,
  String? classroomLabel,
  String? amountReceivedLabel,
  String? allocationsLabel,
  String? advanceLabel,
  String? balanceLabel,
  String? balanceReservation,
  String? keepTicketNotice,
}) => TicketLabels(
  documentTitle: documentTitle ?? _base.documentTitle,
  provisionalBanner: provisionalBanner ?? _base.provisionalBanner,
  referenceLabel: referenceLabel ?? _base.referenceLabel,
  cashierLabel: cashierLabel ?? _base.cashierLabel,
  studentLabel: studentLabel ?? _base.studentLabel,
  matriculationLabel: matriculationLabel ?? _base.matriculationLabel,
  classroomLabel: classroomLabel ?? _base.classroomLabel,
  amountReceivedLabel: amountReceivedLabel ?? _base.amountReceivedLabel,
  allocationsLabel: allocationsLabel ?? _base.allocationsLabel,
  advanceLabel: advanceLabel ?? _base.advanceLabel,
  balanceLabel: balanceLabel ?? _base.balanceLabel,
  balanceReservation: balanceReservation ?? _base.balanceReservation,
  keepTicketNotice: keepTicketNotice ?? _base.keepTicketNotice,
);

TicketReceiptModel _model(TicketLabels labels) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  studentFullName: 'Mbala Kasa Amina',
  provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
  paidAt: DateTime(2026, 8, 12, 14, 7),
  amountReceived: MoneyBag.of(const [Money(150000, 'CDF')]),
  labels: labels,
);
