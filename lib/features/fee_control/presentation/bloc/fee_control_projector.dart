import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_contracts.dart';

/// Part de [count] sur [total], en pourcentage entier **prêt à afficher**.
///
/// ⚠️ **100 % ne s'écrit que si personne ne reste, 0 % que si personne n'y
/// est.** Un arrondi ordinaire annonce « 100 % » sur 249 soldés pour 250
/// concernés : le préfet lit « niveau en règle » et le dernier débiteur
/// disparaît du radar. Symétriquement, un seul élève soldé sur 400 ne doit pas
/// s'annoncer « 0 % » — c'est effacer le seul qui a payé. D'où le clamp à
/// [1, 99] entre les deux bornes, qui restent exactes.
///
/// Une seule fonction pour tout le module : le bandeau du contrôle et le
/// classement du tableau de bord doivent arrondir pareil, sans quoi le même
/// niveau s'annonce à 100 % sur un écran et à 99 % sur l'autre.
int feeSharePercent(int count, int total) {
  if (total <= 0 || count <= 0) return 0;
  if (count >= total) return 100;
  return (count * 100 / total).round().clamp(1, 99);
}

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

  /// Part d'élèves **en ordre**, en pourcentage entier prêt à afficher
  /// (cf. [feeSharePercent]).
  ///
  /// Pour **comparer** deux répartitions, ne pas passer par ce nombre : il crée
  /// des ex æquo qui n'existent pas (99,4 % et 99,8 % y valent tous deux 99).
  /// Le classement du tableau de bord compare les fractions exactes.
  int get settledPercent => feeSharePercent(settled, total);

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
