import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Résultat du calcul de la classe cible (cycle + niveau du référentiel
/// courant).
class TargetSchoolLevelResolution extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const TargetSchoolLevelResolution({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [schoolLevelGroupId, schoolLevelId];
}

/// Calcule la classe cible d'une réinscription à partir du LIBELLÉ de la
/// classe de l'année précédente (`previousSchoolLevelLabel`/
/// `previousSchoolLevelGroupLabel`) et du référentiel courant
/// (`schoolLevelGroups`, cycles + niveaux triés par `displayOrder`).
///
/// Matching par LIBELLÉ, pas par id : les ids du référentiel `ref_school_*`
/// ne sont PAS stables d'une année sur l'autre (rejoués à chaque pull), donc
/// comparer `previousSchoolLevelId` à un id de l'année courante échoue
/// systématiquement. On compare les NOMS à la place — insensible à la casse
/// et aux accents (cf. [SearchNormalizationHelper], déjà utilisé pour la
/// recherche) — un niveau de l'année courante « correspond » si son libellé
/// CONTIENT celui de l'année précédente.
///
/// Dérivation pure, sans I/O — calquée sur le patron `periodeDecoupageFromCount`
/// (academics) plutôt que sur un usecase `Either<Failure,T>`, faute de tout
/// mode d'échec possible.
///
/// Règles, dans cet ordre :
/// 1. Année précédente NON validée → redouble : même classe (même
///    `displayOrder`, même cycle) que l'année précédente.
/// 2. Sinon, niveau suivant (premier `displayOrder` strictement supérieur)
///    dans le MÊME cycle.
/// 3. Sinon (fin de cycle) : premier niveau (plus petit `displayOrder`) du
///    cycle suivant (premier `displayOrder` de cycle strictement supérieur).
/// 4. Défaut : si la classe précédente est inconnue/introuvable dans le
///    référentiel courant (ex. Première inscription, ou libellé sans
///    correspondance), ou si plus aucun cycle/niveau ne suit (fin du
///    dernier cycle), premier niveau du premier cycle du référentiel — ou
///    la classe précédente elle-même en fin de cursus, faute de mieux.
TargetSchoolLevelResolution? resolveTargetSchoolLevel({
  required List<SchoolLevelGroupBundle> schoolLevelGroups,
  required String? previousSchoolLevelLabel,
  required String? previousSchoolLevelGroupLabel,
  required bool validatedPreviousYear,
}) {
  final sortedGroups = [...schoolLevelGroups]
    ..sort((a, b) => a.group.displayOrder.compareTo(b.group.displayOrder));

  TargetSchoolLevelResolution? firstLevelOfFirstGroup() {
    for (final bundle in sortedGroups) {
      if (bundle.levels.isEmpty) continue;
      final sortedLevels = [...bundle.levels]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return TargetSchoolLevelResolution(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelId: sortedLevels.first.id,
      );
    }
    return null;
  }

  // `currentLabel` contient `normalizedTarget` (le libellé N-1), insensible
  // casse/accents. `normalizedTarget` vide ne matche jamais (contrairement à
  // SearchNormalizationHelper.contains, pensé pour un champ de recherche où
  // un terme vide doit tout laisser passer — ici on veut l'inverse : pas de
  // libellé précédent = pas de correspondance possible).
  bool labelContains(String currentLabel, String normalizedTarget) {
    if (normalizedTarget.isEmpty) return false;
    return SearchNormalizationHelper.normalize(
      currentLabel,
    ).contains(normalizedTarget);
  }

  final normalizedPreviousLevelLabel = SearchNormalizationHelper.normalize(
    previousSchoolLevelLabel?.trim() ?? '',
  );
  if (normalizedPreviousLevelLabel.isEmpty) {
    return firstLevelOfFirstGroup();
  }

  final normalizedPreviousGroupLabel = SearchNormalizationHelper.normalize(
    previousSchoolLevelGroupLabel?.trim() ?? '',
  );

  // Restreint la recherche du niveau au cycle dont le libellé correspond,
  // quand on en a un — évite qu'un même libellé de niveau (ex. « 1ère
  // année ») ne matche le mauvais cycle. Sans correspondance de cycle (ou
  // pas de libellé de cycle du tout), on cherche le niveau dans tous les
  // cycles.
  final matchedGroup = normalizedPreviousGroupLabel.isEmpty
      ? null
      : sortedGroups
            .where(
              (bundle) => labelContains(
                bundle.group.name,
                normalizedPreviousGroupLabel,
              ),
            )
            .firstOrNull;
  final candidateBundles = matchedGroup != null ? [matchedGroup] : sortedGroups;

  SchoolLevelGroupBundle? previousBundle;
  SchoolLevel? previousLevel;
  for (final bundle in candidateBundles) {
    final match = bundle.levels
        .where(
          (level) => labelContains(level.name, normalizedPreviousLevelLabel),
        )
        .firstOrNull;
    if (match != null) {
      previousBundle = bundle;
      previousLevel = match;
      break;
    }
  }
  if (previousBundle == null || previousLevel == null) {
    return firstLevelOfFirstGroup();
  }

  if (!validatedPreviousYear) {
    return TargetSchoolLevelResolution(
      schoolLevelGroupId: previousBundle.group.id,
      schoolLevelId: previousLevel.id,
    );
  }

  final sortedSameGroupLevels = [...previousBundle.levels]
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  final nextInSameGroup = sortedSameGroupLevels
      .where((level) => level.displayOrder > previousLevel!.displayOrder)
      .firstOrNull;
  if (nextInSameGroup != null) {
    return TargetSchoolLevelResolution(
      schoolLevelGroupId: previousBundle.group.id,
      schoolLevelId: nextInSameGroup.id,
    );
  }

  final nextGroup = sortedGroups
      .where(
        (bundle) =>
            bundle.group.displayOrder > previousBundle!.group.displayOrder &&
            bundle.levels.isNotEmpty,
      )
      .firstOrNull;
  if (nextGroup != null) {
    final sortedNextLevels = [...nextGroup.levels]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return TargetSchoolLevelResolution(
      schoolLevelGroupId: nextGroup.group.id,
      schoolLevelId: sortedNextLevels.first.id,
    );
  }

  // Fin du dernier cycle du référentiel : rien de plus haut, on reste sur la
  // classe précédente.
  return TargetSchoolLevelResolution(
    schoolLevelGroupId: previousBundle.group.id,
    schoolLevelId: previousLevel.id,
  );
}
