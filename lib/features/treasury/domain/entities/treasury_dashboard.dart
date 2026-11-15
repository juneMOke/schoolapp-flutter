import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';

/// L'année scolaire que couvrent les écrans de trésorerie : de son ouverture
/// (début des inscriptions) à sa fin.
class TreasuryAcademicYear extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  const TreasuryAcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, name, startDate, endDate];
}

/// Une caisse sur le tableau de bord (A2) : ce qu'elle détient, ce qui a
/// bougé depuis la clôture d'hier, ses 8 derniers jours de caisse.
class RegisterOverview extends Equatable {
  final CashRegister register;

  /// Le déclaré si la caisse est close aujourd'hui, l'attendu sinon (R2).
  final int balanceInCents;

  /// Solde − solde de clôture d'hier (R3).
  final int deltaTodayInCents;

  /// Les 8 derniers jours de caisse, du plus ancien au plus récent.
  final List<DayBalance> last8Days;
  final CashClosure? todayClosure;

  const RegisterOverview({
    required this.register,
    required this.balanceInCents,
    required this.deltaTodayInCents,
    required this.last8Days,
    this.todayClosure,
  });

  @override
  List<Object?> get props => [
    register,
    balanceInCents,
    deltaTodayInCents,
    last8Days,
    todayClosure,
  ];
}

class TreasuryOverview extends Equatable {
  /// « Aujourd'hui » selon le serveur, jamais l'horloge de la tablette.
  final DateTime businessDate;
  final TreasuryAcademicYear academicYear;
  final List<RegisterOverview> registers;

  const TreasuryOverview({
    required this.businessDate,
    required this.academicYear,
    required this.registers,
  });

  @override
  List<Object?> get props => [businessDate, academicYear, registers];
}

/// La période d'évolution demandée (A3) ; le mois par défaut.
enum EvolutionPeriod {
  today('TODAY'),
  week('WEEK'),
  month('MONTH'),
  year('YEAR'),
  custom('CUSTOM');

  const EvolutionPeriod(this.wire);

  final String wire;

  static EvolutionPeriod? fromWire(String? value) {
    for (final p in values) {
      if (p.wire == value) return p;
    }
    return null;
  }
}

/// La granularité **choisie par le serveur** (R5) ; la tablette ne la
/// calcule jamais.
enum EvolutionGranularity {
  hour('HOUR'),
  day('DAY'),
  week('WEEK'),
  month('MONTH');

  const EvolutionGranularity(this.wire);

  final String wire;

  static EvolutionGranularity? fromWire(String? value) {
    for (final g in values) {
      if (g.wire == value) return g;
    }
    return null;
  }
}

/// Une tranche de la courbe : instants UTC, fin exclue.
class EvolutionPoint extends Equatable {
  final DateTime start;
  final DateTime end;

  /// `null` pour une tranche à venir.
  final int? balanceInCents;
  final int inflowsInCents;
  final int outflowsInCents;
  final int gapsInCents;

  /// La tranche qui contient aujourd'hui : son solde est celui du moment.
  final bool partial;

  const EvolutionPoint({
    required this.start,
    required this.end,
    required this.inflowsInCents,
    required this.outflowsInCents,
    required this.gapsInCents,
    required this.partial,
    this.balanceInCents,
  });

  @override
  List<Object?> get props => [
    start,
    end,
    balanceInCents,
    inflowsInCents,
    outflowsInCents,
    gapsInCents,
    partial,
  ];
}

/// Une caisse sur la période : sa synthèse et sa courbe.
class RegisterSeries extends Equatable {
  final CashRegister register;
  final CashSynthesis synthesis;
  final List<EvolutionPoint> points;

  const RegisterSeries({
    required this.register,
    required this.synthesis,
    required this.points,
  });

  @override
  List<Object?> get props => [register, synthesis, points];
}

class TreasuryEvolution extends Equatable {
  final EvolutionPeriod period;
  final DateTime from;
  final DateTime to;
  final EvolutionGranularity granularity;

  /// Jours de caisse (lundi → samedi) écoulés dans la plage.
  final int cashDays;
  final List<RegisterSeries> series;

  const TreasuryEvolution({
    required this.period,
    required this.from,
    required this.to,
    required this.granularity,
    required this.cashDays,
    required this.series,
  });

  @override
  List<Object?> get props => [period, from, to, granularity, cashDays, series];
}
