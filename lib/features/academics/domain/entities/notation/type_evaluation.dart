/// Type d'une évaluation : interrogation, devoir ou examen.
///
/// `unknown` est un repli de résilience pour toute valeur backend absente ou
/// inconnue.
enum TypeEvaluation { interro, devoir, examen, unknown }

extension TypeEvaluationX on TypeEvaluation {
  static TypeEvaluation fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'INTERRO' => TypeEvaluation.interro,
        'DEVOIR' => TypeEvaluation.devoir,
        'EXAMEN' => TypeEvaluation.examen,
        _ => TypeEvaluation.unknown,
      };

  String toApiValue() => switch (this) {
    TypeEvaluation.interro => 'INTERRO',
    TypeEvaluation.devoir => 'DEVOIR',
    TypeEvaluation.examen => 'EXAMEN',
    TypeEvaluation.unknown => 'UNKNOWN',
  };
}
