import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un cycle offert au filtre du tableau de bord.
class FeeControlCycleOption {
  final String id;
  final String name;

  const FeeControlCycleOption({required this.id, required this.name});
}

/// Nomme — et range — les groupes du tableau de bord à partir du référentiel
/// académique.
///
/// Le projecteur ne rend que des identifiants — il est pur, et le référentiel
/// n'est pas de son ressort. C'est ici que les identifiants deviennent lisibles,
/// et surtout **ici qu'un identifiant qu'on ne sait pas nommer reste visible** :
/// une ligne muette vaut mieux qu'une ligne effacée, dont l'absence ferait
/// mentir le total.
class FeeControlDashboardLabels {
  /// `schoolLevelId` → nom du niveau.
  final Map<String, String> _levelNames;

  /// `schoolLevelId` → nom de son cycle.
  final Map<String, String> _groupNames;

  /// `schoolLevelId` → identifiant de son cycle.
  final Map<String, String> _groupIds;

  /// `schoolLevelId` → rang d'affichage du niveau dans son cycle.
  final Map<String, int> _levelOrder;

  /// Identifiant de cycle → nom du cycle.
  final Map<String, String> _cycleNames;

  /// Identifiant de cycle → rang d'affichage du cycle.
  final Map<String, int> _cycleOrder;

  const FeeControlDashboardLabels._(
    this._levelNames,
    this._groupNames,
    this._groupIds,
    this._levelOrder,
    this._cycleNames,
    this._cycleOrder,
  );

  factory FeeControlDashboardLabels.from(List<SchoolLevelGroupBundle> bundles) {
    final levelNames = <String, String>{};
    final groupNames = <String, String>{};
    final groupIds = <String, String>{};
    final levelOrder = <String, int>{};
    final cycleNames = <String, String>{};
    final cycleOrder = <String, int>{};
    for (final bundle in bundles) {
      cycleNames[bundle.group.id] = bundle.group.name;
      cycleOrder[bundle.group.id] = bundle.group.displayOrder;
      for (final level in bundle.levels) {
        levelNames[level.id] = level.name;
        groupNames[level.id] = bundle.group.name;
        groupIds[level.id] = bundle.group.id;
        levelOrder[level.id] = level.displayOrder;
      }
    }
    return FeeControlDashboardLabels._(
      levelNames,
      groupNames,
      groupIds,
      levelOrder,
      cycleNames,
      cycleOrder,
    );
  }

  /// Cycles offerts au filtre, dans l'ordre d'affichage du référentiel.
  static List<FeeControlCycleOption> cycles(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final sorted = [...bundles]
      ..sort((a, b) => a.group.displayOrder.compareTo(b.group.displayOrder));
    return [
      for (final bundle in sorted)
        FeeControlCycleOption(id: bundle.group.id, name: bundle.group.name),
    ];
  }

  /// Cycle d'un niveau, `null` si le référentiel ne le connaît pas.
  ///
  /// L'écran nominatif exige un cycle **et** un niveau, alors que le tableau de
  /// bord peut porter sur toute l'école : le cycle se retrouve donc par le
  /// niveau, jamais par le filtre — qui peut valoir « tous ».
  String? groupIdOf(String schoolLevelId) => _groupIds[schoolLevelId];

  /// Nom d'un cycle, `null` si le référentiel ne le connaît pas.
  String? cycleNameOf(String cycleId) => _cycleNames[cycleId];

  /// Rang d'affichage d'un cycle (`displayOrder` du référentiel), `null` s'il
  /// est inconnu.
  int? cycleOrderOf(String cycleId) => _cycleOrder[cycleId];

  /// Rang d'affichage d'un niveau dans son cycle, `null` s'il est inconnu.
  int? levelOrderOf(String schoolLevelId) => _levelOrder[schoolLevelId];

  /// Nom d'un niveau pour une ligne du tableau de bord.
  ///
  /// [withGroup] préfixe par le cycle. Vrai quand une liste à plat porte sur
  /// toute l'école : « 1ère année » existe en primaire **et** en secondaire, et
  /// deux lignes homonymes ne se départageraient plus. Quand un cycle est
  /// filtré — ou que la ligne se lit déjà sous son cycle —, le préfixe ne
  /// dirait que ce que l'écran affiche déjà.
  ///
  /// Deux absences, deux messages — parce qu'elles appellent deux gestes
  /// différents :
  ///  - `null` : la créance ne porte aucun niveau (créance *ad hoc*, ou
  ///    descendue d'un serveur qui ne renseignait pas la colonne) ;
  ///  - identifiant inconnu : le référentiel des niveaux n'est pas descendu sur
  ///    cet appareil, et une synchronisation le réparerait.
  String labelFor(
    String? schoolLevelId,
    AppLocalizations l10n, {
    required bool withGroup,
  }) {
    if (schoolLevelId == null) return l10n.feeControlDashboardLevelUnknown;
    final level = _levelNames[schoolLevelId];
    if (level == null) return l10n.feeControlDashboardLevelMissing;
    if (!withGroup) return level;
    final group = _groupNames[schoolLevelId];
    return group == null ? level : '$group · $level';
  }
}
