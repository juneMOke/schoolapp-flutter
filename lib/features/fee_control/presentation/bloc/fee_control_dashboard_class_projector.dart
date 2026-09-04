import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_level_aggregate.dart';

/// Une classe d'un niveau déplié, ou les élèves qu'aucune classe ne porte.
class FeeControlClassRow extends Equatable {
  /// `null` désigne les **non répartis** : le rendu les nomme, le projecteur
  /// n'a pas à connaître la langue.
  final String? classroomId;

  /// Nom de la classe, tel que le référentiel local le porte. `null` pour les
  /// non répartis.
  final String? name;

  final FeeControlBreakdown breakdown;
  final MoneyBag remaining;

  const FeeControlClassRow({
    required this.classroomId,
    required this.name,
    required this.breakdown,
    required this.remaining,
  });

  int get settledPercent => breakdown.settledPercent;

  bool get isUnassigned => classroomId == null;

  @override
  List<Object?> get props => [classroomId, name, breakdown, remaining];
}

/// Ventile les élèves **déjà chargés** d'un niveau entre ses classes.
///
/// Aucune lecture du grand-livre ici : les positions du niveau sont en mémoire
/// depuis l'interrogation du frais, et déplier n'est qu'une répartition. C'est
/// ce qui rend le dépliage instantané et sans coût pour la base.
class FeeControlDashboardClassProjector {
  const FeeControlDashboardClassProjector._();

  /// [positions] : les élèves du niveau déplié, et eux seuls.
  /// [classrooms] : les classes du niveau, pour leurs noms et leur ordre.
  /// [rosters] : `classroomId → membres`, composés (transferts locaux compris).
  ///
  /// Les classes **vides du frais** sont écartées : une classe dont aucun élève
  /// ne porte le frais n'a pas de position à montrer, et une ligne à « 0 sur
  /// 0 » ne dirait rien qu'on puisse lire.
  ///
  /// Les élèves qu'aucun roster ne réclame forment une ligne finale. **Sans
  /// elle, la somme des classes serait inférieure au niveau** sans que rien ne
  /// l'explique — et sur un tableau de recouvrement, des élèves qui manquent à
  /// l'appel sans raison visible, c'est le pire des silences.
  static List<FeeControlClassRow> project({
    required List<LocalFeeLevelAggregate> positions,
    required List<OfflineClassroom> classrooms,
    required Map<String, List<ClassroomMember>> rosters,
  }) {
    if (positions.isEmpty) return const <FeeControlClassRow>[];

    final byStudent = <String, LocalFeeLevelAggregate>{
      for (final position in positions) position.studentId: position,
    };

    final rows = <FeeControlClassRow>[];
    final placed = <String>{};

    for (final classroom in classrooms) {
      final members = rosters[classroom.id] ?? const <ClassroomMember>[];
      final concerned = <LocalFeeLevelAggregate>[];
      for (final member in members) {
        final position = byStudent[member.studentId];
        if (position == null) continue;
        // `placed` avant le filtre du frais : un élève inscrit dans une classe
        // est réparti, qu'il porte ce frais ou non. Le compter « non réparti »
        // parce qu'il ne doit rien serait faux.
        if (!placed.add(member.studentId)) continue;
        concerned.add(position);
      }
      if (concerned.isEmpty) continue;
      rows.add(_rowOf(classroom.id, classroom.name, concerned));
    }

    final unassigned = [
      for (final position in positions)
        if (!placed.contains(position.studentId)) position,
    ];
    if (unassigned.isNotEmpty) {
      rows.add(_rowOf(null, null, unassigned));
    }
    return rows;
  }

  static FeeControlClassRow _rowOf(
    String? classroomId,
    String? name,
    List<LocalFeeLevelAggregate> positions,
  ) {
    var settled = 0;
    var partial = 0;
    var none = 0;
    var remaining = MoneyBag.empty;
    for (final position in positions) {
      switch (position.status) {
        case StudentChargeStatus.paid:
          settled++;
        case StudentChargeStatus.partial:
          partial++;
        case StudentChargeStatus.due:
          none++;
      }
      remaining = remaining + position.charge.remaining;
    }
    return FeeControlClassRow(
      classroomId: classroomId,
      name: name,
      breakdown: FeeControlBreakdown(
        settled: settled,
        partial: partial,
        none: none,
      ),
      remaining: remaining,
    );
  }
}
