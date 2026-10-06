/// Bornes que le serveur impose au sujet et à la création d'une évaluation
/// (`SujetSyncRequest`, `CreateEvaluationCommand`). Les respecter à la saisie
/// évite un 400 qui laisserait l'écriture refusée sur la tablette.
abstract final class SujetLimits {
  static const int dureeMinutesMax = 600;
  static const int titreMaxLength = 160;
  static const int programmeMaxLines = 50;
  static const int programmeLineMaxLength = 500;
  static const int consignesMaxLength = 2000;
  static const int questionsMax = 100;
  static const int questionTextMaxLength = 4000;

  /// Points et maximum : deux décimales au plus.
  static double roundPoints(double value) =>
      (value * 100).roundToDouble() / 100;
}
