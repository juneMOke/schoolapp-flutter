import 'package:equatable/equatable.dart';

/// Position d'un élève sur **un frais donné**, agrégée à la lecture (Contrôle
/// des frais).
///
/// Une seule ligne par élève même si le grand-livre en porte plusieurs pour le
/// même `fee_code` (une provisoire déjà imputée que le seed conserve, par
/// exemple) : on somme, comme le fait le détail Facturation, plutôt que d'en
/// retenir une au hasard.
///
/// `paidPendingInCents` est la part **composée à la lecture** — les allocations
/// des paiements de ce poste pas encore remontés (`sync_status <> 'SYNCED'`,
/// donc `PENDING_SYNC` **et** `SYNC_ERROR`). Sans elle, un encaissement fait
/// hors-ligne le matin ressortirait « aucun paiement » l'après-midi.
class LocalFeeChargeAggregate extends Equatable {
  final String studentId;

  /// Total attendu pour ce frais.
  final int expectedInCents;

  /// Miroir serveur (autoritaire), jamais incrémenté localement.
  final int paidMirrorInCents;

  /// Encaissements de ce poste non encore remontés (composés au read).
  final int paidPendingInCents;

  final String currency;

  const LocalFeeChargeAggregate({
    required this.studentId,
    required this.expectedInCents,
    required this.paidMirrorInCents,
    required this.paidPendingInCents,
    required this.currency,
  });

  /// Payé TOTAL (FRONT §5 « paid_total »). Dérivé, jamais stocké.
  int get paidTotalInCents => paidMirrorInCents + paidPendingInCents;

  /// Reste composé : `max(0, expected - paid_total)` (FRONT §5). C'est LA seule
  /// vérité locale pour classer un élève — jamais la colonne `status`, qui est
  /// un miroir serveur et remonterait « dû » un poste soldé hors-ligne.
  int get remainingInCents {
    final remaining = expectedInCents - paidTotalInCents;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  List<Object?> get props => [
    studentId,
    expectedInCents,
    paidMirrorInCents,
    paidPendingInCents,
    currency,
  ];
}
