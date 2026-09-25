import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_gesture_policy.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_transitions.dart';

/// Deux des trois filtres de F29 — l'état et la propriété. Le troisième, la
/// permission, n'est pas ici : il vit à l'écran, et c'est voulu.
///
/// Ce que ce fichier protège : qu'aucun geste ne soit **offert pour échouer**.
/// Un bouton offert sans que l'état ou la propriété ne le permettent fabrique
/// une entrée d'outbox morte (403 comme 422 sont terminaux) et une ligne « à
/// corriger » que son auteur ne peut pas corriger.
void main() {
  const moi = 'u-moi';
  const autre = 'u-autre';

  Expense expense({
    ExpenseStatus status = ExpenseStatus.pending,
    String? recordedById = autre,
    DateTime? deletedAt,
  }) => Expense(
    id: 'e-1',
    typeId: 't-1',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: status,
    expenseDate: DateTime(2026, 9, 3),
    recordedById: recordedById,
    clientUpdatedAt: DateTime.utc(2026, 9, 3),
    deletedAt: deletedAt,
  );

  Set<ExpenseGesture> offered({
    ExpenseStatus status = ExpenseStatus.pending,
    String? recordedById = autre,
    String? accountId = moi,
    DateTime? deletedAt,
  }) => ExpenseGesturePolicy.offeredOn(
    expense(status: status, recordedById: recordedById, deletedAt: deletedAt),
    accountId: accountId,
  ).toSet();

  group('la demande d\'un collègue', () {
    test('en attente : on la tranche, on ne la relance ni ne la retire', () {
      expect(offered(), {
        ExpenseGesture.approve,
        ExpenseGesture.refuse,
        ExpenseGesture.comment,
      });
    });

    test('accordée : on la paie ou on annule la décision', () {
      expect(offered(status: ExpenseStatus.approved), {
        ExpenseGesture.pay,
        ExpenseGesture.reopen,
        ExpenseGesture.comment,
      });
    });

    test('payée : plus rien à payer, la décision reste annulable', () {
      expect(offered(status: ExpenseStatus.paid), {
        ExpenseGesture.reopen,
        ExpenseGesture.comment,
      });
    });

    test('refusée : la corriger est au demandeur, pas au décideur', () {
      expect(offered(status: ExpenseStatus.refused), {
        ExpenseGesture.reopen,
        ExpenseGesture.comment,
      });
    });

    test('retirée par son demandeur : elle n\'est plus offerte à personne '
        'd\'autre que le fil', () {
      expect(offered(status: ExpenseStatus.retracted), {
        ExpenseGesture.comment,
      });
    });
  });

  group('sa propre demande', () {
    test('en attente : relancer, retirer, et aussi la trancher', () {
      // A11 abandonnée le 2026-09-25 : seule la direction décide, et refuser
      // l'auto-approbation gèlerait pour toujours les demandes du directeur.
      // La permission `expense.decide` filtre à l'écran, pas la propriété.
      expect(offered(recordedById: moi), {
        ExpenseGesture.approve,
        ExpenseGesture.refuse,
        ExpenseGesture.retract,
        ExpenseGesture.remind,
        ExpenseGesture.comment,
      });
    });

    test('refusée ou retirée : corriger et renvoyer', () {
      for (final status in [ExpenseStatus.refused, ExpenseStatus.retracted]) {
        expect(
          offered(status: status, recordedById: moi),
          contains(ExpenseGesture.resubmit),
          reason: status.name,
        );
      }
    });

    test('accordée : la payer reste possible, la renvoyer non', () {
      final gestes = offered(status: ExpenseStatus.approved, recordedById: moi);
      expect(gestes, contains(ExpenseGesture.pay));
      expect(gestes, isNot(contains(ExpenseGesture.resubmit)));
    });
  });

  group('propriété indécidable', () {
    // Ce qu'on ne sait pas prouver sien n'ouvre pas les gestes du demandeur ;
    // décider, qui ne dépend plus de la propriété, reste offert.
    test('demandeur inconnu : décider reste offert, relancer non', () {
      final gestes = offered(recordedById: null);
      expect(gestes, contains(ExpenseGesture.approve));
      expect(gestes, isNot(contains(ExpenseGesture.remind)));
    });

    test('session sans identifiant : même conduite', () {
      final gestes = offered(recordedById: moi, accountId: null);
      expect(gestes, contains(ExpenseGesture.approve));
      expect(gestes, isNot(contains(ExpenseGesture.retract)));
    });

    test('deux identifiants vides ne se ressemblent pas', () {
      final gestes = offered(recordedById: '', accountId: '');
      expect(gestes, isNot(contains(ExpenseGesture.remind)));
    });
  });

  test('retirée du registre : aucun geste, pas même un commentaire', () {
    // Le serveur n'a plus rien à trancher ; un geste y attendrait un état qui
    // ne reviendra pas. La restauration la remet dans le circuit telle
    // qu'elle était.
    for (final status in ExpenseStatus.values) {
      expect(
        offered(status: status, deletedAt: DateTime.utc(2026, 9, 4)),
        isEmpty,
        reason: status.name,
      );
    }
  });

  test('aucune transition offerte n\'est absente de la table', () {
    for (final status in ExpenseStatus.values) {
      for (final accountId in [moi, autre]) {
        final demande = expense(status: status, recordedById: autre);
        for (final gesture in ExpenseGesturePolicy.offeredOn(
          demande,
          accountId: accountId,
        )) {
          final target = gesture.target;
          if (target == null) continue;
          expect(
            ExpenseTransitions.isAllowed(status, target),
            isTrue,
            reason: '${gesture.name} depuis ${status.name}',
          );
        }
      }
    }
  });
}
