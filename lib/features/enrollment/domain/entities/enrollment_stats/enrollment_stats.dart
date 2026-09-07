import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/cycle_distribution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_evolution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_kpis.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_distribution.dart';

class EnrollmentStats extends Equatable {
  final StatsContext context;

  /// L'effectif inscrit, **indépendant de la fenêtre**.
  ///
  /// Cumulé depuis l'ouverture des inscriptions, dossiers terminés seulement.
  /// Ce n'est **jamais** une somme des barres ni des cartes : il ne se
  /// recalcule pas, il se lit.
  ///
  /// ⚠️ `headcount.total` **n'égale pas** `kpis.totalEnrollments`, même sur la
  /// fenêtre « année » : le second ajoute les pré-inscriptions et les dossiers
  /// en cours. Les réconcilier serait une erreur.
  ///
  /// Son total EST la somme de ses segments, ce qui rend les deux chiffres de
  /// parité du bloc « Filles / Garçons » comparables.
  final GenderDistribution headcount;

  final EnrollmentKpis kpis;
  final EnrollmentEvolution evolution;
  final CycleDistribution distributionByCycle;
  final GenderDistribution distributionByGender;

  const EnrollmentStats({
    required this.context,
    required this.headcount,
    required this.kpis,
    required this.evolution,
    required this.distributionByCycle,
    required this.distributionByGender,
  });

  @override
  List<Object?> get props => [
    context,
    headcount,
    kpis,
    evolution,
    distributionByCycle,
    distributionByGender,
  ];
}
