import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

enum MovementDirection {
  inflow('IN'),
  outflow('OUT');

  const MovementDirection(this.wire);
  final String wire;

  static MovementDirection? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

/// D'où vient l'argent d'une ligne du registre. Le mobile money et la carte
/// n'entrent jamais dans une caisse.
enum MovementSource {
  fees('FEES'),
  shop('SHOP'),
  expense('EXPENSE'),
  payroll('PAYROLL'),
  bankDeposit('BANK_DEPOSIT'),
  adjustment('ADJUSTMENT'),
  closingGap('CLOSING_GAP');

  const MovementSource(this.wire);
  final String wire;

  static MovementSource? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

/// Ce que fait une ligne : inscrire un fait d'argent, en défaire un autre, ou
/// compenser une ligne arrivée après une clôture et « déjà en caisse » (R19).
enum MovementNature {
  entry('ENTRY'),
  cancellation('CANCELLATION'),
  afterClosureOffset('AFTER_CLOSURE_OFFSET');

  const MovementNature(this.wire);
  final String wire;

  static MovementNature? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

/// Une ligne du registre d'une caisse — jamais modifiée (ajout seul).
class CashMovement extends Equatable {
  final String id;
  final String registerId;
  final TreasuryCurrency currency;

  /// La journée de caisse où la ligne compte.
  final DateTime cashDay;

  /// Le jour où l'argent a changé de mains. Diffère de [cashDay] seulement
  /// quand [afterClosure] est vrai.
  final DateTime businessDay;
  final DateTime occurredAt;
  final MovementDirection direction;

  /// Toujours positif : [direction] porte le sens.
  final int amountInCents;
  final MovementSource source;
  final MovementNature nature;

  /// Écrit par le serveur (« Frais de scolarité — Kabongo Mwamba · 6e A »).
  final String label;
  final String? reference;
  final String? createdByName;

  /// Arrivée après la clôture de son jour métier : elle compte pour la
  /// journée ouverte suivante et attend une réponse (R19).
  final bool afterClosure;

  /// Réponse à une ligne [afterClosure] ; `null` tant qu'elle attend.
  final bool? alreadyCounted;

  /// La ligne que celle-ci défait (une annulation, une compensation R19).
  final String? undoesMovementId;

  const CashMovement({
    required this.id,
    required this.registerId,
    required this.currency,
    required this.cashDay,
    required this.businessDay,
    required this.occurredAt,
    required this.direction,
    required this.amountInCents,
    required this.source,
    required this.nature,
    required this.label,
    this.reference,
    this.createdByName,
    this.afterClosure = false,
    this.alreadyCounted,
    this.undoesMovementId,
  });

  /// Le montant signé, tel qu'il pèse dans le reste.
  int get signedInCents =>
      direction == MovementDirection.inflow ? amountInCents : -amountInCents;

  bool get awaitsAnswer => afterClosure && alreadyCounted == null;

  @override
  List<Object?> get props => [
    id,
    registerId,
    currency,
    cashDay,
    businessDay,
    occurredAt,
    direction,
    amountInCents,
    source,
    nature,
    label,
    reference,
    createdByName,
    afterClosure,
    alreadyCounted,
    undoesMovementId,
  ];
}
