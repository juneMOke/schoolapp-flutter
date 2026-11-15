import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// La clôture d'une caisse pour une journée (R9) : la réponse de la caissière
/// (« Oui, c'est juste » / « Non »), l'attendu, le déclaré, l'écart et sa
/// justification — jamais modifiable ni supprimable (R16).
class CashClosure extends Equatable {
  final String id;
  final String registerId;
  final TreasuryCurrency currency;
  final DateTime cashDay;
  final DateTime closedAt;
  final String closedByName;

  /// `ACCOUNTANT`, `DIRECTOR`… : l'écran écrit « (promoteur) » quand ce n'est
  /// pas la caissière.
  final String closedByRole;

  /// « Oui, c'est juste ».
  final bool matches;
  final int expectedInCents;
  final int declaredInCents;
  final int gapInCents;
  final String? justification;

  /// Réouverture par le promoteur (R20) : la clôture reste lisible, mais ne
  /// verrouille plus la caisse.
  final DateTime? reopenedAt;
  final String? reopenedByName;
  final String? reopenReason;

  const CashClosure({
    required this.id,
    required this.registerId,
    required this.currency,
    required this.cashDay,
    required this.closedAt,
    required this.closedByName,
    required this.closedByRole,
    required this.matches,
    required this.expectedInCents,
    required this.declaredInCents,
    required this.gapInCents,
    this.justification,
    this.reopenedAt,
    this.reopenedByName,
    this.reopenReason,
  });

  bool get locksRegister => reopenedAt == null;

  bool get hasGap => gapInCents != 0;

  /// La caissière clôture ; tout autre rôle autorisé est le promoteur.
  bool get closedByCashier => closedByRole == 'ACCOUNTANT';

  @override
  List<Object?> get props => [
    id,
    registerId,
    currency,
    cashDay,
    closedAt,
    closedByName,
    closedByRole,
    matches,
    expectedInCents,
    declaredInCents,
    gapInCents,
    justification,
    reopenedAt,
    reopenedByName,
    reopenReason,
  ];
}
