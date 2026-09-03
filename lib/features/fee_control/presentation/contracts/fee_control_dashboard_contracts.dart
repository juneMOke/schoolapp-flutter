import 'package:equatable/equatable.dart';

/// Ce qu'un tableau de bord interroge : un frais, éventuellement borné à un
/// cycle.
///
/// Conservée dans l'état sous `lastQuery` pour deux usages qui ne tolèrent pas
/// l'à-peu-près : rejouer **exactement** la même lecture après un échec, et
/// dire à l'écran de quoi le résultat affiché est le résultat — un bandeau qui
/// survit au changement de critères annoncerait la position d'un frais sous le
/// nom d'un autre.
class FeeControlDashboardQuery extends Equatable {
  final String academicYearId;

  /// Nature du frais (`fee_code`), jamais un libellé : l'écran est école-wide,
  /// et deux niveaux nomment la même nature différemment.
  final String feeCode;

  /// Cycle, ou `null` pour toute l'école.
  final String? schoolLevelGroupId;

  const FeeControlDashboardQuery({
    required this.academicYearId,
    required this.feeCode,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [academicYearId, feeCode, schoolLevelGroupId];
}

/// Ce que le tableau de bord transmet à l'écran nominatif quand on lui demande
/// « qui, précisément ? ».
///
/// Le tableau de bord pose la question, l'écran voisin donne les noms : le
/// passage doit conserver **exactement** le périmètre lu, sinon la liste ne
/// répondrait pas de la synthèse qui l'a ouverte.
class FeeControlIntent extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;

  /// Classe visée, `null` pour tout le niveau — selon qu'on parte d'une ligne
  /// de classe ou de la ligne du niveau.
  final String? classroomId;

  final String feeCode;

  const FeeControlIntent({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.classroomId,
    required this.feeCode,
  });

  /// Reconstruit l'intention depuis `extra` de la route. `null` dès qu'il n'y a
  /// rien à reconstruire : l'écran s'ouvre alors vierge, comme par le menu.
  static FeeControlIntent? fromRouteExtra(Object? extra) =>
      extra is FeeControlIntent ? extra : null;

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    classroomId,
    feeCode,
  ];
}
