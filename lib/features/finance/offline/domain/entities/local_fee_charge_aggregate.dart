import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

/// Position d'un élève sur un frais, **dans une devise**.
///
/// Une créance n'a qu'une devise, et le grand-livre peut en porter plusieurs
/// pour le même `fee_code` (une provisoire déjà imputée que le seed conserve,
/// par exemple) : on somme celles qui partagent la devise, jamais celles qui en
/// changent.
class FeeChargePosition extends Equatable {
  final String currency;

  /// Total attendu pour ce frais, dans cette devise.
  final int expectedInCents;

  /// Miroir serveur (autoritaire), jamais incrémenté localement.
  final int paidMirrorInCents;

  /// Encaissements de ce poste non encore remontés (composés au read).
  final int paidPendingInCents;

  const FeeChargePosition({
    required this.currency,
    required this.expectedInCents,
    required this.paidMirrorInCents,
    required this.paidPendingInCents,
  });

  /// Payé TOTAL (FRONT §5 « paid_total »). Dérivé, jamais stocké.
  int get paidTotalInCents => paidMirrorInCents + paidPendingInCents;

  /// Reste composé : `max(0, expected - paid_total)` (FRONT §5).
  int get remainingInCents {
    final remaining = expectedInCents - paidTotalInCents;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  List<Object?> get props => [
    currency,
    expectedInCents,
    paidMirrorInCents,
    paidPendingInCents,
  ];
}

/// Position d'un élève sur **un frais donné**, agrégée à la lecture (Contrôle
/// des frais).
///
/// Une seule ligne par élève, mais **une position par devise** : le SQL groupait
/// jusqu'ici sur le seul `student_id` et étiquetait le résultat d'un
/// `MIN(sc.currency)` — la devise la plus petite alphabétiquement, choisie au
/// hasard des données.
///
/// En pratique, cet écran est borné à **un `fee_code` et un niveau**, donc à un
/// tarif, donc à une devise : les positions n'en portent presque jamais deux.
/// C'est précisément pourquoi le défaut serait passé inaperçu, et pourquoi il ne
/// coûte rien de le fermer proprement.
///
/// `paidPendingInCents` est la part **composée à la lecture** — les allocations
/// des paiements de ce poste pas encore remontés (`sync_status <> 'SYNCED'`,
/// donc `PENDING_SYNC` **et** `SYNC_ERROR`). Sans elle, un encaissement fait
/// hors-ligne le matin ressortirait « aucun paiement » l'après-midi.
class LocalFeeChargeAggregate extends Equatable {
  final String studentId;

  /// Une entrée par devise, triée par code croissant. Jamais vide : un élève
  /// sans créance sur ce frais n'a pas d'agrégat du tout — « aucun paiement »
  /// n'est pas « aucune créance ».
  final List<FeeChargePosition> positions;

  const LocalFeeChargeAggregate({
    required this.studentId,
    required this.positions,
  });

  /// Raccourci du cas courant : une seule devise.
  factory LocalFeeChargeAggregate.single({
    required String studentId,
    required String currency,
    required int expectedInCents,
    required int paidMirrorInCents,
    required int paidPendingInCents,
  }) => LocalFeeChargeAggregate(
    studentId: studentId,
    positions: [
      FeeChargePosition(
        currency: currency,
        expectedInCents: expectedInCents,
        paidMirrorInCents: paidMirrorInCents,
        paidPendingInCents: paidPendingInCents,
      ),
    ],
  );

  MoneyBag get expected => MoneyBag.sumBy(
    positions,
    (p) => Money.parse(p.expectedInCents, p.currency),
  );

  MoneyBag get paidTotal => MoneyBag.sumBy(
    positions,
    (p) => Money.parse(p.paidTotalInCents, p.currency),
  );

  MoneyBag get remaining => MoneyBag.sumBy(
    positions,
    (p) => Money.parse(p.remainingInCents, p.currency),
  );

  /// Statut dérivé **des montants**, toutes devises confondues.
  ///
  /// Soldé seulement si **toutes** les devises le sont : un élève à jour en
  /// dollars mais débiteur en francs n'est pas en règle sur ce frais.
  StudentChargeStatus get status {
    final allSettled = positions.every((p) => p.remainingInCents <= 0);
    if (allSettled) return StudentChargeStatus.paid;
    final nothingPaid = positions.every((p) => p.paidTotalInCents <= 0);
    return nothingPaid ? StudentChargeStatus.due : StudentChargeStatus.partial;
  }

  /// Clé de tri du tableau, en centimes.
  ///
  /// ⚠️ **N'a de sens strict qu'en mono-devise** — ce qui est le cas de cet
  /// écran, borné à un frais et un niveau. Un reste en francs et un reste en
  /// dollars ne se comparent pas : leur rapport d'échelle est de ×2 800, et
  /// aucun taux n'entre ici. En présence de deux devises, l'ordre reste
  /// **stable et reproductible** (la devise la plus petite alphabétiquement
  /// décide), sans jamais faire écrire un montant faux à l'écran.
  int get sortableRemainingInCents {
    // Dérivé du SAC, pas de `positions.first` : la liste n'est triée que par
    // convention du DAO (`ORDER BY … , sc.currency`), et une convention ne
    // survit pas à un second producteur. Le sac, lui, trie toujours — donc
    // deux agrégats de mêmes montants rendent la même clé, quel que soit
    // l'ordre dans lequel leurs positions ont été assemblées.
    final entries = remaining.entries;
    return entries.isEmpty ? 0 : entries.first.amountInCents;
  }

  @override
  List<Object?> get props => [studentId, positions];
}
