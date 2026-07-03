import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

/// Point de la courbe de progression P1..Pn (vue focus).
///
/// [indexGlobal] (1..N sur l'année) porte l'ordre : les points arrivent déjà
/// ordonnés. [pourcentage] `null` = « non noté ». [dansGroupe] `true` signale une
/// sous-période du groupe sélectionné (colorée par l'UI).
class ProgressionPoint extends Equatable {
  final String sousPeriodeId;
  final int indexGlobal;
  final int periodeOrdre;
  final int sousPeriodeOrdre;
  final double? pourcentage;
  final StatutPeriode statut;
  final bool dansGroupe;

  const ProgressionPoint({
    required this.sousPeriodeId,
    required this.indexGlobal,
    required this.periodeOrdre,
    required this.sousPeriodeOrdre,
    this.pourcentage,
    required this.statut,
    required this.dansGroupe,
  });

  @override
  List<Object?> get props => [
    sousPeriodeId,
    indexGlobal,
    periodeOrdre,
    sousPeriodeOrdre,
    pourcentage,
    statut,
    dansGroupe,
  ];
}
