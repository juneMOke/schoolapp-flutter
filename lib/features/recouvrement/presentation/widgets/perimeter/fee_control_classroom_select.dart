import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le champ **Classe** du contrôle des frais (spec v2, §4.6 A) : un seul
/// `EteeloSelectInput` avec recherche, options « {classe} · {cycle} » rangées
/// par cycle — écart assumé à l'ancienne cascade niveau → classe — puis la
/// rubrique « Non affectés », en dernier (arbitrage du 2026-11-22).
class FeeControlClassroomSelect extends StatelessWidget {
  final List<OfflineClassroom> classrooms;

  /// Cycles et niveaux de l'année, pour nommer et ranger les classes.
  final List<SchoolLevelGroupBundle> groups;

  /// Une classe, [feeControlUnassigned], ou `null` (rien de choisi).
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const FeeControlClassroomSelect({
    super.key,
    required this.classrooms,
    required this.groups,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Les classes dans l'ordre du référentiel : cycle, niveau, puis nom.
  static List<OfflineClassroom> ordered(
    List<OfflineClassroom> classrooms,
    List<SchoolLevelGroupBundle> groups,
  ) {
    final groupRank = <String, int>{};
    final levelRank = <String, int>{};
    for (final g in groups) {
      groupRank[g.group.id] = g.group.displayOrder;
      for (final l in g.levels) {
        levelRank[l.id] = l.displayOrder;
      }
    }
    int rank(Map<String, int> m, String? id) =>
        id == null ? 1 << 20 : m[id] ?? 1 << 20;
    return [...classrooms]..sort((a, b) {
      final byGroup = rank(
        groupRank,
        a.schoolLevelGroupId,
      ).compareTo(rank(groupRank, b.schoolLevelGroupId));
      if (byGroup != 0) return byGroup;
      final byLevel = rank(
        levelRank,
        a.schoolLevelId,
      ).compareTo(rank(levelRank, b.schoolLevelId));
      if (byLevel != 0) return byLevel;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycleName = {for (final g in groups) g.group.id: g.group.name};
    String labelOf(OfflineClassroom c) {
      final cycle = cycleName[c.schoolLevelGroupId];
      return cycle == null ? c.name : '${c.name} · $cycle';
    }

    return EteeloSelectInput<String>(
      label: l10n.recouvrementClassLabel,
      placeholder: l10n.recouvrementClassPlaceholder,
      value: value,
      enabled: enabled,
      searchable: true,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: [
        for (final c in ordered(classrooms, groups))
          EteeloSelectItem<String>(
            value: c.id,
            label: labelOf(c),
            searchTerms: c.name,
          ),
        EteeloSelectItem<String>(
          value: feeControlUnassigned,
          label: l10n.recouvrementUnassigned,
        ),
      ],
    );
  }
}
