import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';

/// Répartition des élèves d'une classe sur le frais contrôlé.
///
/// Comptée sur la population **concernée** (ceux qui portent une créance de ce
/// frais), pas sur la liste affichée : le bandeau doit répondre « où en est la
/// classe » même quand le tableau ne montre qu'un statut. Sans quoi, filtrer sur
/// « Soldé » afficherait « 12 soldés, 0 partiel, 0 aucun » — une synthèse qui ne
/// synthétise plus rien.
class FeeControlBreakdown extends Equatable {
  final int settled;
  final int partial;
  final int none;

  const FeeControlBreakdown({
    this.settled = 0,
    this.partial = 0,
    this.none = 0,
  });

  int get total => settled + partial + none;

  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => [settled, partial, none];
}

/// Résultat du croisement élèves × créances, avant et après le filtre de statut.
///
/// Les deux listes sont renvoyées parce que leur ÉCART est une information :
/// une classe peuplée dont aucun élève ne porte le frais ([charged] vide) est un
/// constat très différent d'une classe dont personne ne correspond au statut
/// demandé ([filtered] vide, [charged] non). L'état vide de l'écran s'appuie
/// dessus pour ne pas envoyer chercher une erreur de saisie là où il n'y a
/// qu'une grille tarifaire incomplète.
class FeeControlJoin {
  /// Élèves portant réellement une créance du frais contrôlé.
  final List<FeeControlRow> charged;

  /// Parmi eux, ceux qui correspondent au statut demandé.
  final List<FeeControlRow> filtered;

  /// Répartition de [charged] par statut — la synthèse de la classe, que le
  /// filtre de statut ne doit pas réduire.
  final FeeControlBreakdown breakdown;

  const FeeControlJoin({
    required this.charged,
    required this.filtered,
    required this.breakdown,
  });
}

/// Croisement **pur** des élèves inscrits et de leur position sur un frais.
class FeeControlProjector {
  const FeeControlProjector._();

  /// Apparie chaque résumé à son agrégat, puis applique le filtre de statut.
  ///
  /// Un élève **sans agrégat est écarté** : « aucun paiement » n'est pas
  /// « aucune créance ». Il n'est pas concerné par ce frais, l'afficher à zéro
  /// le ferait passer pour un mauvais payeur.
  ///
  /// L'ordre des [summaries] est préservé (celui du DAO, puis du raffinement).
  static FeeControlJoin join({
    required List<EnrollmentSummary> summaries,
    required List<LocalFeeChargeAggregate> aggregates,
    required FeeControlPaymentFilter filter,
  }) {
    final byStudent = <String, LocalFeeChargeAggregate>{
      for (final aggregate in aggregates) aggregate.studentId: aggregate,
    };

    final charged = <FeeControlRow>[];
    var settled = 0;
    var partial = 0;
    var none = 0;
    for (final summary in summaries) {
      final aggregate = byStudent[summary.student.id];
      if (aggregate == null) continue;
      final row = FeeControlRow(summary: summary, aggregate: aggregate);
      charged.add(row);
      switch (row.status) {
        case StudentChargeStatus.paid:
          settled++;
        case StudentChargeStatus.partial:
          partial++;
        case StudentChargeStatus.due:
          none++;
      }
    }

    return FeeControlJoin(
      charged: charged,
      filtered: charged
          .where((row) => row.matches(filter))
          .toList(growable: false),
      breakdown: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
    );
  }
}
