import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_gesture_columns.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Ce qu'un geste réécrit sur la ligne — la carte est **étroite** par
/// construction : tout ce qui n'y figure pas reste tel que le dernier accusé
/// ou le dernier pull l'a laissé.
void main() {
  final at = DateTime.utc(2026, 9, 20, 8, 30);

  Map<String, Object?> columns(ExpenseGesture gesture, {String? reason}) =>
      ExpenseGestureColumns.of(
        gesture,
        actorId: 'u-direction',
        actorName: 'Mbala Thérèse',
        at: at,
        reason: reason,
      );

  test('approuver pose le décideur, sans motif', () {
    expect(columns(ExpenseGesture.approve), {
      'status': 'APPROVED',
      'decided_by_id': 'u-direction',
      'decided_by_name': 'Mbala Thérèse',
      'decided_at': '2026-09-20T08:30:00.000Z',
      'decision_reason': null,
    });
  });

  test('approuver n\'hérite jamais du motif d\'un refus précédent', () {
    // Le motif est passé quoi qu'il arrive — c'est le corps du message. Le
    // recopier dans `decision_reason` ferait lire « accordée » au-dessus du
    // texte d'un refus.
    expect(
      columns(ExpenseGesture.approve, reason: 'Devis non joint'),
      containsPair('decision_reason', null),
    );
  });

  test('refuser porte son motif', () {
    expect(
      columns(ExpenseGesture.refuse, reason: 'Devis non joint'),
      containsPair('decision_reason', 'Devis non joint'),
    );
  });

  test('payer pose la date de règlement et ne décide pas', () {
    final map = columns(ExpenseGesture.pay);
    expect(map, containsPair('status', 'PAID'));
    expect(map, containsPair('paid_on', '2026-09-20'));
    // L'approbation garde son auteur : l'écran continue d'afficher qui a
    // accordé, pas qui a décaissé.
    expect(map.keys, isNot(contains('decided_by_id')));
    expect(map.keys, isNot(contains('decided_at')));
  });

  test('retirer sa demande ne pose aucune décision', () {
    expect(columns(ExpenseGesture.retract), {'status': 'RETRACTED'});
  });

  for (final gesture in [ExpenseGesture.resubmit, ExpenseGesture.reopen]) {
    test('${gesture.name} : retour en attente, tout est effacé', () {
      expect(columns(gesture), {
        'status': 'PENDING',
        'decided_by_id': null,
        'decided_by_name': null,
        'decided_at': null,
        'decision_reason': null,
        // Un retour en attente défait aussi le décaissement : une demande
        // rouverte n'est plus payée.
        'paid_on': null,
        // Une nouvelle version repart avec un compteur neuf.
        'reminder_count': 0,
      });
    });
  }

  for (final gesture in [ExpenseGesture.remind, ExpenseGesture.comment]) {
    test('${gesture.name} ne déplace pas la demande', () {
      // Le compteur de relances n'est PAS ici : `+ 1` se lit dans la
      // transaction, pas dans une carte de colonnes.
      expect(columns(gesture), isEmpty);
    });
  }

  test('aucun geste n\'écrit une colonne de contenu ni de synchro', () {
    const interdites = {
      'title',
      'amount_in_cents',
      'currency',
      'expense_date',
      'supplier',
      'type_id',
      'client_updated_at',
      'sync_status',
      'expense_number',
      'version',
      'deleted_at',
    };
    for (final gesture in ExpenseGesture.values) {
      expect(
        columns(gesture, reason: 'motif').keys.toSet().intersection(interdites),
        isEmpty,
        reason: gesture.name,
      );
    }
  });
}
