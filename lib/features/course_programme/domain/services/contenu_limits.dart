import 'dart:convert';

import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';

/// Le plafond du contenu rédigé d'un chapitre — proposé par le back
/// (200 blocs, 64 Ko de JSON), à confirmer au contrat P0. La tablette refuse
/// la saisie au-delà, avant le 422 du serveur.
class ContenuLimits {
  ContenuLimits._();

  static const int maxBlocs = 200;
  static const int maxBytes = 64 * 1024;

  /// Le poids des blocs tels qu'ils partiront (UTF-8), au plus près du fil.
  static int weightOf(List<ChapitreBloc> blocs) =>
      utf8.encode(jsonEncode([for (final b in blocs) b.toJson()])).length;

  static bool tooHeavy(List<ChapitreBloc> blocs) => weightOf(blocs) > maxBytes;
}
