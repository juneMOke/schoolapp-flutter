import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

/// Grande période scolaire (trimestre / semestre) d'une classe.
///
/// [id] est le `periodeScolaireId` exigé par les endpoints résultats. [ordre]
/// (1..N) pilote le libellé T{n} / S{n}. [decoupage] provient du `periodType`
/// (SEMESTER/TRIMESTER, `null` → unknown). [libelle] est synthétisé côté serveur
/// (« Semestre 1 »…), prêt à afficher. [courant] marque la période contenant
/// aujourd'hui (auto-sélection ; `false` partout = normal hors année scolaire).
/// [startDate] / [endDate] sont des dates pures (bornes, `null` possible).
class PeriodeScolaire extends Equatable {
  final String id;
  final int ordre;
  final Decoupage decoupage;
  final StatutPeriode statut;
  final String? libelle;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool courant;

  const PeriodeScolaire({
    required this.id,
    required this.ordre,
    required this.decoupage,
    required this.statut,
    this.libelle,
    this.startDate,
    this.endDate,
    this.courant = false,
  });

  @override
  List<Object?> get props => [
    id,
    ordre,
    decoupage,
    statut,
    libelle,
    startDate,
    endDate,
    courant,
  ];
}
