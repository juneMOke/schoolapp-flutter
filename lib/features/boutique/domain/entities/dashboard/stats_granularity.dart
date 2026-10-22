/// Le pas de la série « recettes dans le temps ».
///
/// Le serveur le choisit (`HOUR` quand la fenêtre est d'un jour), le client le
/// lit : il ne le déduit jamais de la largeur de sa fenêtre, sans quoi un
/// serveur qui changerait de règle ferait étiqueter des jours comme des heures.
enum StatsGranularity {
  hour('HOUR'),
  day('DAY');

  const StatsGranularity(this.wire);

  final String wire;

  /// Une valeur inconnue retombe sur le jour : c'est le pas le plus large, et
  /// un libellé de jour sur une barre d'heure se voit — l'inverse non.
  static StatsGranularity fromWire(Object? wire) =>
      wire == StatsGranularity.hour.wire
      ? StatsGranularity.hour
      : StatsGranularity.day;
}
