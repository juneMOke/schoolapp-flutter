/// Le temps **de l'école**, et non celui de la tablette.
///
/// Toutes les lectures d'argent qui découpent des journées le font dans le
/// fuseau de l'établissement : la caisse serveur agrège par
/// `CAST(paid_at AT TIME ZONE 'Africa/Kinshasa' AS DATE)`. Le poste, lui, n'a
/// que son horloge système — et rien ne garantit qu'elle soit réglée sur ce
/// fuseau. Une tablette laissée en UTC compose « aujourd'hui 23 h 30 » en un
/// instant qui, relu à Kinshasa, tombe le **lendemain** : le versement change
/// de journée de caisse sans que personne ne l'ait demandé.
///
/// Ces fonctions composent donc les instants à partir de l'heure murale de
/// l'école, jamais de l'heure locale du poste. Le résultat est un instant UTC —
/// la seule forme que `paid_at` accepte.
///
/// ⚠️ **Kinshasa n'observe pas l'heure d'été** : le décalage est une constante,
/// pas une règle saisonnière. C'est ce qui permet de s'en tenir à une
/// [Duration] plutôt que d'embarquer une base de fuseaux horaires.
class SchoolTime {
  const SchoolTime._();

  /// Décalage fixe d'`Africa/Kinshasa` : UTC+1 toute l'année.
  static const Duration offset = Duration(hours: 1);

  /// L'heure **murale** de l'école à cet instant.
  ///
  /// Le `DateTime` rendu porte les champs de calendrier de Kinshasa ; son drapeau
  /// UTC n'a plus de sens à ce stade et ne doit pas être relu comme un instant.
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// Le **jour** de l'école à cet instant, ramené à minuit.
  ///
  /// C'est la valeur à donner à un sélecteur de date (`value`, `firstDate`,
  /// `lastDate`) : seuls les champs année/mois/jour y sont lus.
  static DateTime today(DateTime instant) {
    final wall = wallClock(instant);
    return DateTime(wall.year, wall.month, wall.day);
  }

  /// Le même jour de calendrier, un an plus tôt.
  ///
  /// Borne de repli quand l'année académique ne dit pas sa date de rentrée :
  /// elle laisse rattraper une saisie oubliée sans permettre d'écrire dans une
  /// année que l'école a déjà close.
  static DateTime oneYearBefore(DateTime day) =>
      DateTime(day.year - 1, day.month, day.day);

  /// Compose l'instant UTC dont la lecture **à Kinshasa** est exactement
  /// « [day], à l'heure qu'il est maintenant ».
  ///
  /// C'est la règle A1 : le caissier choisit un jour, jamais une heure. L'heure
  /// reste celle du guichet, ce qui laisse le cas courant — aujourd'hui —
  /// rigoureusement identique à ce que produisait l'horodatage automatique.
  ///
  /// [day] n'est lu que par ses champs de calendrier ; [now] peut être local ou
  /// UTC, il est normalisé.
  static DateTime composeInstant({
    required DateTime day,
    required DateTime now,
  }) {
    final wall = wallClock(now);
    return DateTime.utc(
      day.year,
      day.month,
      day.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
      // Jusqu'à la microseconde : sans elle, un versement daté d'aujourd'hui ne
      // reproduirait pas EXACTEMENT l'horodatage automatique qu'il remplace, et
      // la garde de non-régression ne garderait qu'à la milliseconde près.
      wall.microsecond,
    ).subtract(offset);
  }
}
