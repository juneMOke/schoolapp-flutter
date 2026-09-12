import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_ranking_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';

/// Un cycle et ses niveaux, tels que « Où en est chaque niveau » les montre.
class RecouvrementCycleNode extends Equatable {
  /// Cycle du référentiel, ou `null` pour le groupe final : les lignes que le
  /// référentiel ne sait rattacher à aucun cycle — créance sans niveau, ou
  /// niveau pas encore descendu sur l'appareil.
  final String? cycleId;

  /// La somme de ses niveaux, jamais un recomptage des élèves : c'est ce qui
  /// garde vrai « le total de la page est la somme de ses groupes » (D5), y
  /// compris pour l'élève à cheval sur deux niveaux, qui compte dans chacun.
  final FeeControlBreakdown breakdown;

  /// Les niveaux, dans l'ordre du référentiel.
  final List<RecouvrementGroupRow> levels;

  const RecouvrementCycleNode({
    required this.cycleId,
    required this.breakdown,
    required this.levels,
  });

  bool get isUnplaced => cycleId == null;

  @override
  List<Object?> get props => [cycleId, breakdown, levels];
}

/// Range les niveaux du classement sous leur cycle, dans l'ordre de l'école.
///
/// Le projecteur classe les niveaux du plus en retard au plus en règle — c'est
/// l'ordre dont la lecture « écart » de fin de page a besoin. Cette section-ci
/// montre l'école telle qu'elle est organisée : elle reprend les MÊMES lignes,
/// les regroupe et les ordonne, **sans rien recompter**. Deux sections ne
/// peuvent donc pas se contredire sur un niveau.
///
/// **Pur** : le référentiel arrive par [FeeControlDashboardLabels], seul à le
/// connaître.
class RecouvrementCycleTree {
  const RecouvrementCycleTree._();

  /// Les cycles connus d'abord, dans leur ordre d'affichage ; le groupe des
  /// lignes non rattachées ferme la marche.
  ///
  /// **Aucune ligne ne se perd** : un niveau qu'on ne sait pas ranger se range
  /// là, et la somme des cycles reste celle des niveaux.
  static List<RecouvrementCycleNode> build(
    List<RecouvrementGroupRow> groups,
    FeeControlDashboardLabels labels,
  ) {
    if (groups.isEmpty) return const <RecouvrementCycleNode>[];

    final byCycle = <String?, List<RecouvrementGroupRow>>{};
    for (final group in groups) {
      final levelId = group.schoolLevelId;
      final cycleId = levelId == null ? null : labels.groupIdOf(levelId);
      (byCycle[cycleId] ??= <RecouvrementGroupRow>[]).add(group);
    }

    final placed = [
      for (final entry in byCycle.entries)
        if (entry.key != null) _node(entry.key, entry.value, labels),
    ]..sort((a, b) => _byCycleOrder(a.cycleId!, b.cycleId!, labels));

    final unplaced = byCycle[null];
    return [...placed, if (unplaced != null) _node(null, unplaced, labels)];
  }

  static RecouvrementCycleNode _node(
    String? cycleId,
    List<RecouvrementGroupRow> levels,
    FeeControlDashboardLabels labels,
  ) {
    final sorted = [...levels]..sort((a, b) => _byLevelOrder(a, b, labels));
    var settled = 0;
    var partial = 0;
    var none = 0;
    for (final level in sorted) {
      settled += level.breakdown.settled;
      partial += level.breakdown.partial;
      none += level.breakdown.none;
    }
    return RecouvrementCycleNode(
      cycleId: cycleId,
      breakdown: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
      levels: List.unmodifiable(sorted),
    );
  }

  /// Le rang du référentiel d'abord. Un niveau qu'il ne connaît pas vient après
  /// ceux qu'il connaît, et la ligne sans niveau ferme la marche. L'identifiant
  /// départage : deux projections des mêmes lignes rendent le même ordre.
  static int _byLevelOrder(
    RecouvrementGroupRow a,
    RecouvrementGroupRow b,
    FeeControlDashboardLabels labels,
  ) {
    final aId = a.schoolLevelId;
    final bId = b.schoolLevelId;
    if (aId == null || bId == null) {
      if (aId == bId) return 0;
      return aId == null ? 1 : -1;
    }
    final byRank = _byRank(labels.levelOrderOf(aId), labels.levelOrderOf(bId));
    return byRank != 0 ? byRank : aId.compareTo(bId);
  }

  static int _byCycleOrder(
    String a,
    String b,
    FeeControlDashboardLabels labels,
  ) {
    final byRank = _byRank(labels.cycleOrderOf(a), labels.cycleOrderOf(b));
    return byRank != 0 ? byRank : a.compareTo(b);
  }

  /// Un rang connu passe avant un rang inconnu.
  static int _byRank(int? a, int? b) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1;
    }
    return a.compareTo(b);
  }
}
