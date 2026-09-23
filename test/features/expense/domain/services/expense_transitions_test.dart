import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_transitions.dart';

/// La matrice attendue, **réécrite ici** plutôt que lue de la bibliothèque :
/// un test qui itère sur la table qu'il vérifie ne dit rien, et laisserait
/// passer une paire ajoutée par mégarde.
///
/// Source : spec §01. `attente → approuvée | refusée | retirée` ·
/// `approuvée → payée` · `refusée | retirée → attente` (correction) ·
/// `approuvée | payée | refusée → attente` (annulation de décision).
const Map<ExpenseStatus, Set<ExpenseStatus>> _expected = {
  ExpenseStatus.pending: {
    ExpenseStatus.approved,
    ExpenseStatus.refused,
    ExpenseStatus.retracted,
  },
  ExpenseStatus.approved: {ExpenseStatus.paid, ExpenseStatus.pending},
  ExpenseStatus.paid: {ExpenseStatus.pending},
  ExpenseStatus.refused: {ExpenseStatus.pending},
  ExpenseStatus.retracted: {ExpenseStatus.pending},
};

void main() {
  group('la matrice complète — 25 paires, aucune oubliée', () {
    test('chaque paire permise l’est, chaque autre est refusée', () {
      for (final from in ExpenseStatus.values) {
        for (final to in ExpenseStatus.values) {
          final allowed = from == to || _expected[from]!.contains(to);
          expect(
            ExpenseTransitions.isAllowed(from, to),
            allowed,
            reason: '${from.wireValue} → ${to.wireValue}',
          );
        }
      }
    });

    test('un geste qui ne change rien est inerte, jamais une erreur', () {
      for (final status in ExpenseStatus.values) {
        expect(ExpenseTransitions.isAllowed(status, status), isTrue);
      }
    });
  });

  group('les interdits qui comptent', () {
    test('payer ne précède JAMAIS l’approbation', () {
      expect(
        ExpenseTransitions.isAllowed(ExpenseStatus.pending, ExpenseStatus.paid),
        isFalse,
        reason: 'ce serait décaisser sans accord',
      );
      expect(ExpenseTransitions.canPay(ExpenseStatus.pending), isFalse);
      expect(ExpenseTransitions.canPay(ExpenseStatus.approved), isTrue);
      expect(ExpenseTransitions.canPay(ExpenseStatus.refused), isFalse);
    });

    test('une demande tranchée ne se re-tranche pas sans repasser en '
        'attente', () {
      expect(ExpenseTransitions.canDecide(ExpenseStatus.pending), isTrue);
      for (final status in [
        ExpenseStatus.approved,
        ExpenseStatus.paid,
        ExpenseStatus.refused,
        ExpenseStatus.retracted,
      ]) {
        expect(ExpenseTransitions.canDecide(status), isFalse);
      }
    });

    test('une impasse ne mène pas directement à l’autre', () {
      expect(
        ExpenseTransitions.isAllowed(
          ExpenseStatus.refused,
          ExpenseStatus.retracted,
        ),
        isFalse,
      );
      expect(
        ExpenseTransitions.isAllowed(
          ExpenseStatus.retracted,
          ExpenseStatus.refused,
        ),
        isFalse,
      );
    });
  });

  group('les gestes, par leur nom', () {
    test('corriger et renvoyer : depuis une impasse, et elle seule', () {
      expect(ExpenseTransitions.canResubmit(ExpenseStatus.refused), isTrue);
      expect(ExpenseTransitions.canResubmit(ExpenseStatus.retracted), isTrue);
      expect(ExpenseTransitions.canResubmit(ExpenseStatus.pending), isFalse);
      expect(ExpenseTransitions.canResubmit(ExpenseStatus.paid), isFalse);
    });

    test('annuler une décision : seulement s’il y en a une', () {
      expect(ExpenseTransitions.canReopen(ExpenseStatus.approved), isTrue);
      expect(ExpenseTransitions.canReopen(ExpenseStatus.paid), isTrue);
      expect(ExpenseTransitions.canReopen(ExpenseStatus.refused), isTrue);
      expect(ExpenseTransitions.canReopen(ExpenseStatus.pending), isFalse);
      expect(
        ExpenseTransitions.canReopen(ExpenseStatus.retracted),
        isFalse,
        reason: 'un retrait n’est pas une décision : il se reprend',
      );
    });

    test(
      'le retour en attente efface la décision ; rien d’autre ne l’efface',
      () {
        expect(
          ExpenseTransitions.clearsDecision(ExpenseStatus.pending),
          isTrue,
        );
        for (final status in [
          ExpenseStatus.approved,
          ExpenseStatus.paid,
          ExpenseStatus.refused,
          ExpenseStatus.retracted,
        ]) {
          expect(ExpenseTransitions.clearsDecision(status), isFalse);
        }
      },
    );

    test('seul le refus exige un motif', () {
      expect(ExpenseTransitions.requiresReason(ExpenseStatus.refused), isTrue);
      for (final status in [
        ExpenseStatus.pending,
        ExpenseStatus.approved,
        ExpenseStatus.paid,
        ExpenseStatus.retracted,
      ]) {
        expect(ExpenseTransitions.requiresReason(status), isFalse);
      }
    });
  });

  group('le drapeau ferme — ce qui compte comme de l’argent', () {
    test('approuvée et payée, elles seules', () {
      expect(ExpenseStatus.approved.isFirm, isTrue);
      expect(ExpenseStatus.paid.isFirm, isTrue);
      expect(ExpenseStatus.pending.isFirm, isFalse);
      expect(ExpenseStatus.refused.isFirm, isFalse);
      expect(ExpenseStatus.retracted.isFirm, isFalse);
    });

    test('une valeur illisible se lit « en attente » : jamais de l’argent '
        'engagé sans preuve', () {
      expect(ExpenseStatus.fromWire(null), ExpenseStatus.pending);
      expect(ExpenseStatus.fromWire(''), ExpenseStatus.pending);
      expect(ExpenseStatus.fromWire('UNPAID'), ExpenseStatus.pending);
      expect(ExpenseStatus.fromWire('  approved '), ExpenseStatus.approved);
      expect(ExpenseStatus.fromWire('paid').isFirm, isTrue);
    });
  });
}
