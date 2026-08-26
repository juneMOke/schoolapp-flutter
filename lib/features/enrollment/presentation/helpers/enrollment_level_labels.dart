import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Libellés de classe d'un dossier listé, tels qu'un écran de détail les
/// affiche dans son sur-titre.
typedef EnrollmentLevelLabels = ({String levelName, String levelGroupName});

const EnrollmentLevelLabels _noLabels = (levelName: '', levelGroupName: '');

/// Résout `(niveau, cycle)` pour [summary] — **la LIGNE d'abord, les critères
/// ensuite**.
///
/// Historiquement la seule source d'un niveau à l'affichage était
/// [searchedLevelId], c'est-à-dire le critère de la dernière recherche. Une
/// recherche **par identité** n'en transporte aucun : Facturation affichait
/// alors « Facturation · - » et Documents laissait tomber le segment de classe
/// de son sur-titre, alors que la ligne trouvée sait parfaitement de quel
/// niveau est l'élève.
///
/// Ordre de résolution, du plus sûr au plus faible :
/// 1. les libellés portés par la **ligne** (résolus sur le référentiel par le
///    `LEFT JOIN` du DAO) ;
/// 2. le référentiel interrogé sur le niveau **de la ligne**, qui comble un
///    cycle manquant sans jamais l'emprunter à un autre élève — `enrollments`
///    a un `school_level_group_id` nullable, donc un dossier peut connaître son
///    niveau sans porter son cycle ;
/// 3. le référentiel interrogé sur le niveau **cherché**, qui reste la seule
///    source pour un résumé venu du réseau (le DTO serveur ne porte aucun
///    niveau).
///
/// Les deux libellés se complètent indépendamment : un cycle trouvé ne
/// disqualifie pas un niveau déjà connu, et réciproquement.
EnrollmentLevelLabels resolveEnrollmentLevelLabels(
  EnrollmentSummary summary, {
  required List<SchoolLevelGroupBundle> bundles,
  String? searchedLevelId,
}) {
  var levelName = summary.schoolLevelName?.trim() ?? '';
  var groupName = summary.schoolLevelGroupName?.trim() ?? '';
  if (levelName.isNotEmpty && groupName.isNotEmpty) {
    return (levelName: levelName, levelGroupName: groupName);
  }

  for (final levelId in [summary.schoolLevelId, searchedLevelId]) {
    final found = lookupLevelLabels(bundles, levelId);
    if (levelName.isEmpty) levelName = found.levelName;
    if (groupName.isEmpty) groupName = found.levelGroupName;
    if (levelName.isNotEmpty && groupName.isNotEmpty) break;
  }

  return (levelName: levelName, levelGroupName: groupName);
}

/// `(niveau, cycle)` du niveau [levelId] dans le référentiel, vides s'il est
/// absent ou inconnu — le référentiel peut n'être pas encore descendu.
EnrollmentLevelLabels lookupLevelLabels(
  List<SchoolLevelGroupBundle> bundles,
  String? levelId,
) {
  final id = levelId?.trim() ?? '';
  if (id.isEmpty) return _noLabels;

  for (final bundle in bundles) {
    for (final level in bundle.levels) {
      if (level.id == id) {
        return (
          levelName: level.name.trim(),
          levelGroupName: bundle.group.name.trim(),
        );
      }
    }
  }
  return _noLabels;
}
