import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

/// Rapprochement des libellés du référentiel géographique avec ce qui a été
/// saisi ou stocké ailleurs (ville, district, commune, quartier).
///
/// Une valeur enregistrée avant une retouche du référentiel (« Ngaliema » contre
/// « NGALIEMA », « Kimbanséké » contre « Kimbanseke ») doit retrouver son
/// option : on compare d'abord à l'identique, puis sur une clé débarrassée de la
/// casse, des accents, des espaces et de la ponctuation.
class GeoLabelMatcher {
  GeoLabelMatcher._();

  /// [value] rogné, ou `null` s'il n'est pas une chaîne non vide.
  static String? nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// L'option de [options] qui correspond à [raw], ou `null`.
  static String? resolve(Iterable<String> options, String? raw) {
    final candidate = nonEmpty(raw);
    if (candidate == null) return null;

    for (final option in options) {
      if (option == candidate) return option;
    }

    final candidateKey = key(candidate);
    for (final option in options) {
      if (key(option) == candidateKey) return option;
    }
    return null;
  }

  /// [base] en liste non modifiable, précédée de [include] s'il n'y figure pas.
  ///
  /// Sert à garder sélectionnable une valeur déjà enregistrée que le
  /// référentiel ne connaît plus : la retirer de la liste effacerait la saisie
  /// au premier affichage.
  static List<String> withOptional(List<String> base, String? include) {
    final value = include?.trim() ?? '';
    if (value.isEmpty || base.contains(value)) {
      return List<String>.unmodifiable(base);
    }
    return List<String>.unmodifiable(<String>[value, ...base]);
  }

  /// Clé de comparaison : minuscules sans accents, lettres et chiffres seuls.
  static String key(String value) {
    return SearchNormalizationHelper.normalize(
      value,
    ).replaceAll(_nonAlphanumeric, '');
  }

  static final RegExp _nonAlphanumeric = RegExp('[^a-z0-9]');
}
