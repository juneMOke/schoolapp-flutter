import 'package:school_app_flutter/core/money/exchange_rate.dart';

/// Un taux du fil, en **micro-unités** — `taux × 1 000 000`.
///
/// Le serveur sérialise un `numeric(18,6)` en nombre JSON. On le porte en `int`
/// dès la frontière, pour la raison qui vaut sur tout le socle monétaire : **un
/// flottant qui traverse la couche métier finit par arrondir de l'argent**.
/// Même conversion que le pull des taux de change
/// (`exchange_rate_pull_models.dart`), afin que les deux chemins ne divergent
/// pas d'un centième sur le même taux.
///
/// **Un taux nul, négatif ou illisible est écarté**, jamais replié sur zéro :
/// « au taux de 0 » se lirait comme une conversion observée, alors que c'est une
/// absence de donnée. Les appelants traitent `null` comme « pas de croisement
/// annonçable ».
int? tillRateToMicros(Object? raw) {
  if (raw is! num) return null;
  final micros = (raw * ExchangeRate.scale).round();
  return micros > 0 ? micros : null;
}
