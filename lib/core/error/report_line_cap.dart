import 'package:school_app_flutter/core/error/failures.dart';

/// Le refus de plafond des **documents de période**, décodé une seule fois.
///
/// Trois écrans le lèvent désormais — le rapport de caisse, le registre des
/// inscriptions et la liste de relance — et le serveur en fait un `400` portant
/// `REPORT_LINE_CAP` avec ses deux chiffres **à part**, jamais dans la prose :
/// les lire dans le message casserait à la première reformulation.
///
/// Le commentaire qui vivait sur le bouton du rapport de caisse annonçait cette
/// promotion : « le jour où cet écran-là dira la même chose, la lecture des
/// chiffres montera d'un cran ». C'est ce jour.
class ReportLineCap {
  const ReportLineCap._();

  /// Le code du serveur, partagé par toutes les pièces de période.
  static const String detailCode = 'REPORT_LINE_CAP';

  /// Les deux chiffres du refus, ou `null` si ce n'en est pas un.
  static ({int lines, int cap})? of(Failure failure) {
    if (failure is! ApiErrorDetails) return null;
    if (failure.detailCode != detailCode) return null;

    final lines = _asInt(failure.details?['lines']);
    final cap = _asInt(failure.details?['cap']);
    if (lines == null || cap == null) return null;
    return (lines: lines, cap: cap);
  }

  /// Un entier du corps d'erreur, quelle que soit la façon dont il a traversé
  /// le JSON — `int`, `num` ou chaîne. Le contrat ne promet pas la forme, et un
  /// message perdu pour un `7213` arrivé en texte serait une régression muette.
  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}
