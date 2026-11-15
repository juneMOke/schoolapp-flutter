import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';

/// Les chiffres d'une caisse sur une plage (R2) : solde = ouverture + entrées
/// − sorties + écarts. Les écarts ne comptent jamais dans les entrées ni les
/// sorties.
class CashSynthesis extends Equatable {
  final int openingInCents;
  final int inflowsInCents;
  final int outflowsInCents;
  final int gapsInCents;
  final int closingInCents;

  /// (entrées − sorties) / ouverture, à l'unité ; `null` si l'ouverture vaut 0.
  final int? variationPercent;

  const CashSynthesis({
    required this.openingInCents,
    required this.inflowsInCents,
    required this.outflowsInCents,
    required this.gapsInCents,
    required this.closingInCents,
    this.variationPercent,
  });

  @override
  List<Object?> get props => [
    openingInCents,
    inflowsInCents,
    outflowsInCents,
    gapsInCents,
    closingInCents,
    variationPercent,
  ];
}

/// Le statut de clôture d'une caisse sur une journée.
enum ClosureStatus {
  /// Clôturée ce jour-là.
  closed('CLOSED'),

  /// Aujourd'hui, pas encore clôturée.
  open('OPEN'),

  /// Un jour passé que personne n'a clôturé (« Non clôturée »).
  notClosed('NOT_CLOSED');

  const ClosureStatus(this.wire);

  final String wire;

  static ClosureStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Une caisse sur une journée de la plage.
class PeriodDayCell extends Equatable {
  final String registerId;
  final int inflowsInCents;
  final int outflowsInCents;
  final int gapInCents;
  final int closingBalanceInCents;
  final ClosureStatus status;

  /// La justification de l'écart, quand la journée s'est close avec un écart.
  final String? justification;

  const PeriodDayCell({
    required this.registerId,
    required this.inflowsInCents,
    required this.outflowsInCents,
    required this.gapInCents,
    required this.closingBalanceInCents,
    required this.status,
    this.justification,
  });

  @override
  List<Object?> get props => [
    registerId,
    inflowsInCents,
    outflowsInCents,
    gapInCents,
    closingBalanceInCents,
    status,
    justification,
  ];
}

/// Une journée écoulée de la plage : une cellule par caisse en service ce
/// jour-là (une caisse créée en cours de plage n'en a pas avant).
class PeriodDayRow extends Equatable {
  final DateTime day;
  final List<PeriodDayCell> cells;

  const PeriodDayRow({required this.day, required this.cells});

  PeriodDayCell? cellOf(String registerId) {
    for (final cell in cells) {
      if (cell.registerId == registerId) return cell;
    }
    return null;
  }

  @override
  List<Object?> get props => [day, cells];
}

/// Une caisse et ses totaux sur la plage.
class PeriodRegisterTotals extends Equatable {
  final CashRegister register;
  final CashSynthesis synthesis;

  const PeriodRegisterTotals({required this.register, required this.synthesis});

  @override
  List<Object?> get props => [register, synthesis];
}

/// Une semaine ou un mois de l'écran de clôture (B7) : les totaux par caisse,
/// puis les journées écoulées, la plus récente en tête.
class TreasuryPeriod extends Equatable {
  final DateTime from;
  final DateTime to;
  final List<PeriodRegisterTotals> registers;
  final List<PeriodDayRow> days;

  const TreasuryPeriod({
    required this.from,
    required this.to,
    required this.registers,
    required this.days,
  });

  @override
  List<Object?> get props => [from, to, registers, days];
}
