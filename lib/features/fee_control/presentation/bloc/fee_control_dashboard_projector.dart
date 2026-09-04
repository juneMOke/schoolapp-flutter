import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';

/// Une ligne du classement : un groupe d'élèves et sa position sur le frais.
class FeeControlGroupRow extends Equatable {
  /// Niveau du groupe. **`null` est une valeur légitime**, pas une absence de
  /// donnée à masquer : `school_level_id` est nullable au grand-livre, et les
  /// créances qui n'en portent pas forment un groupe qui se voit. Les taire
  /// ferait fondre le total de l'école sans que rien ne l'explique.
  final String? schoolLevelId;

  final FeeControlBreakdown breakdown;

  /// Reste dû du groupe, **par devise**. Jamais un total unique : additionner
  /// des francs et des dollars écrirait un montant qui n'existe pas.
  final MoneyBag remaining;

  const FeeControlGroupRow({
    required this.schoolLevelId,
    required this.breakdown,
    required this.remaining,
  });

  /// Part d'élèves en ordre, prête à afficher — cf. [FeeControlBreakdown].
  int get settledPercent => breakdown.settledPercent;

  @override
  List<Object?> get props => [schoolLevelId, breakdown, remaining];
}

/// Ce que le tableau de bord répond pour un frais : la position de l'ensemble,
/// et le classement des groupes qui la composent.
class FeeControlDashboardSummary extends Equatable {
  /// Position de tout le périmètre interrogé (l'école, ou le cycle filtré).
  ///
  /// **Invariant :** c'est exactement la somme des [groups]. Le tableau de bord
  /// ne compte jamais deux populations différentes dans le même écran.
  final FeeControlBreakdown total;

  /// Reste dû du périmètre, par devise.
  final MoneyBag remaining;

  /// Les groupes, **ce qui décroche en tête** (cf.
  /// [FeeControlDashboardProjector.project]).
  final List<FeeControlGroupRow> groups;

  const FeeControlDashboardSummary({
    required this.total,
    required this.remaining,
    required this.groups,
  });

  static const empty = FeeControlDashboardSummary(
    total: FeeControlBreakdown(),
    remaining: MoneyBag.empty,
    groups: <FeeControlGroupRow>[],
  );

  bool get isEmpty => total.isEmpty;

  int get settledPercent => total.settledPercent;

  @override
  List<Object?> get props => [total, remaining, groups];
}

/// Répartition **pure** de la population d'un frais par groupe d'élèves.
///
/// Ne lit rien, n'appelle rien : on lui donne ce que le grand-livre a rendu, il
/// rend ce que l'écran affiche.
class FeeControlDashboardProjector {
  const FeeControlDashboardProjector._();

  /// Ventile [positions] par niveau, compte les statuts, et classe les groupes
  /// **du plus en retard au plus en règle**.
  ///
  /// C'est l'ordre qui fait l'écran : la question posée est « quelle classe
  /// décroche », pas « où en est l'école ». Un classement alphabétique
  /// obligerait à lire quarante lignes pour trouver les trois qui comptent.
  ///
  /// Le statut de chaque élève est **emprunté** à `LocalFeeChargeAggregate` —
  /// la règle qui sert l'écran de contrôle, jamais une seconde copie. C'est ce
  /// qui rend impossible que les deux écrans du module se contredisent sur le
  /// même élève.
  ///
  /// ⚠️ Un élève qui porte le même frais sur **deux niveaux** (changement en
  /// cours d'année) apparaît dans les deux groupes, et compte deux fois dans le
  /// total. C'est voulu : il doit bel et bien à chacun, et c'est ce qui
  /// maintient l'invariant « le total est la somme des groupes ».
  static FeeControlDashboardSummary project(
    List<LocalFeeLevelAggregate> positions,
  ) {
    if (positions.isEmpty) return FeeControlDashboardSummary.empty;

    final settledBy = <String?, int>{};
    final partialBy = <String?, int>{};
    final noneBy = <String?, int>{};
    final remainingBy = <String?, MoneyBag>{};

    var settled = 0;
    var partial = 0;
    var none = 0;
    var remaining = MoneyBag.empty;

    for (final position in positions) {
      final level = position.schoolLevelId;
      switch (position.status) {
        case StudentChargeStatus.paid:
          settledBy[level] = (settledBy[level] ?? 0) + 1;
          settled++;
        case StudentChargeStatus.partial:
          partialBy[level] = (partialBy[level] ?? 0) + 1;
          partial++;
        case StudentChargeStatus.due:
          noneBy[level] = (noneBy[level] ?? 0) + 1;
          none++;
      }
      final due = position.charge.remaining;
      remainingBy[level] = (remainingBy[level] ?? MoneyBag.empty) + due;
      remaining = remaining + due;
    }

    final levels = <String?>{
      ...settledBy.keys,
      ...partialBy.keys,
      ...noneBy.keys,
    };
    final groups = [
      for (final level in levels)
        FeeControlGroupRow(
          schoolLevelId: level,
          breakdown: FeeControlBreakdown(
            settled: settledBy[level] ?? 0,
            partial: partialBy[level] ?? 0,
            none: noneBy[level] ?? 0,
          ),
          remaining: remainingBy[level] ?? MoneyBag.empty,
        ),
    ]..sort(_byRetardThenSize);

    return FeeControlDashboardSummary(
      total: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
      remaining: remaining,
      groups: groups,
    );
  }

  /// Le plus en retard d'abord, puis le plus nombreux, puis l'identifiant.
  ///
  /// La comparaison des taux se fait **en produits croisés d'entiers**, jamais
  /// sur [FeeControlBreakdown.settledPercent] : celui-ci est borné à [1, 99]
  /// pour l'affichage et rendrait ex æquo deux groupes à 99,4 % et 99,8 %. Pas
  /// de flottant non plus — deux fractions égales doivent l'être exactement.
  ///
  /// L'effectif départage ensuite, le plus grand d'abord : à taux égal, une
  /// classe de quarante élèves pèse plus qu'un groupe de trois. L'identifiant
  /// ferme le tri — arbitraire, mais **stable** : deux projections des mêmes
  /// données rendent toujours le même ordre.
  static int _byRetardThenSize(FeeControlGroupRow a, FeeControlGroupRow b) {
    final aTotal = a.breakdown.total;
    final bTotal = b.breakdown.total;
    if (aTotal > 0 && bTotal > 0) {
      final byRate = (a.breakdown.settled * bTotal).compareTo(
        b.breakdown.settled * aTotal,
      );
      if (byRate != 0) return byRate;
    }
    final bySize = bTotal.compareTo(aTotal);
    if (bySize != 0) return bySize;
    return (a.schoolLevelId ?? '').compareTo(b.schoolLevelId ?? '');
  }
}
