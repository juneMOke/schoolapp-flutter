import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';

/// Les règles de la liste des signataires, celles du serveur (V212) : il les
/// applique et fait foi ; l'écran s'en sert pour guider la saisie.
abstract final class ReportSignatoryRules {
  /// Le PDF tient quatre blocs côte à côte.
  static const int maxSignatories = 4;
  static const int captionMaxLength = 40;
  static const int nameMaxLength = 100;
  static const int functionMaxLength = 60;

  static bool isCaptionValid(String caption) {
    final trimmed = caption.trim();
    return trimmed.isNotEmpty && trimmed.length <= captionMaxLength;
  }

  static bool isFunctionValid(String function) {
    final trimmed = function.trim();
    return trimmed.isNotEmpty && trimmed.length <= functionMaxLength;
  }

  static bool isNameValid(String? name) =>
      (name?.trim().length ?? 0) <= nameMaxLength;

  /// Une liste enregistrable : au plus quatre lignes, chacune lisible, « la
  /// personne qui a clôturé » seulement au premier rang.
  static bool isListValid(List<ReportSignatory> list) =>
      list.length <= maxSignatories &&
      list.indexed.every(
        (entry) =>
            isCaptionValid(entry.$2.caption) &&
            isFunctionValid(entry.$2.function) &&
            isNameValid(entry.$2.name) &&
            (entry.$1 == 0 || !entry.$2.filledByCloser),
      );

  /// Les rangs 1..n dans l'ordre de la liste ; « la personne qui a
  /// clôturé » ne survit qu'au premier rang.
  static List<ReportSignatory> renumbered(List<ReportSignatory> list) => [
    for (final (index, s) in list.indexed)
      s.copyWith(
        rank: index + 1,
        filledByCloser: index == 0 && s.filledByCloser,
      ),
  ];

  /// Les deux listes s'impriment pareil, une fois rognées.
  static bool sameList(List<ReportSignatory> a, List<ReportSignatory> b) {
    final left = trimmed(a);
    final right = trimmed(b);
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  /// Les textes tels que le serveur les garde : rognés, un nom blanc vaut
  /// `null`.
  static List<ReportSignatory> trimmed(List<ReportSignatory> list) => [
    for (final s in renumbered(list))
      ReportSignatory(
        rank: s.rank,
        caption: s.caption.trim(),
        name: (s.name?.trim().isEmpty ?? true) ? null : s.name!.trim(),
        function: s.function.trim(),
        filledByCloser: s.filledByCloser,
      ),
  ];
}
