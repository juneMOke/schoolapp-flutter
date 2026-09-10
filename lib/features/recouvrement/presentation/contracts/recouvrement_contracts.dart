import 'package:equatable/equatable.dart';

/// Ce qu'un tableau de bord du Recouvrement interroge : **une sélection** de
/// frais, éventuellement bornée à un cycle.
///
/// Conservée dans l'état sous `lastQuery` pour deux usages qui ne tolèrent pas
/// l'à-peu-près : rejouer **exactement** la même lecture après un échec, et dire
/// à l'écran de quoi le résultat affiché est le résultat — un bandeau qui
/// survivrait au changement de sélection annoncerait la position d'un frais sous
/// le nom d'un autre.
class RecouvrementQuery extends Equatable {
  final String academicYearId;

  /// Natures retenues (`fee_code`), triées, **jamais vides**. L'écran refuse de
  /// décocher la dernière : sans elle, aucun indicateur de la page n'est
  /// calculable (RECOUVREMENT_PLAN.md, invariant n° 8).
  final List<String> feeCodes;

  /// Cycle, ou `null` pour toute l'école.
  final String? schoolLevelGroupId;

  const RecouvrementQuery({
    required this.academicYearId,
    required this.feeCodes,
    this.schoolLevelGroupId,
  });

  /// Normalise la sélection — triée et dédoublonnée — pour que deux clics dans
  /// un ordre différent produisent la **même** requête, donc la même égalité et
  /// le même cache d'écran.
  factory RecouvrementQuery.of({
    required String academicYearId,
    required Iterable<String> feeCodes,
    String? schoolLevelGroupId,
  }) => RecouvrementQuery(
    academicYearId: academicYearId,
    feeCodes: feeCodes.toSet().toList()..sort(),
    schoolLevelGroupId: schoolLevelGroupId,
  );

  @override
  List<Object?> get props => [academicYearId, feeCodes, schoolLevelGroupId];
}
