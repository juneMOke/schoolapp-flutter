import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Les libellés des niveaux de l'année, par identifiant : le TICKET d'une
/// vente walk-in porte un niveau déclaré, et l'imprimer par son identifiant
/// ne dirait rien à personne.
Map<String, String> boutiqueLevelLabels(AcademicYearContext? year) => {
  for (final bundle
      in year?.schoolLevelGroups ?? const <SchoolLevelGroupBundle>[])
    for (final level in bundle.levels) level.id: level.name,
};
