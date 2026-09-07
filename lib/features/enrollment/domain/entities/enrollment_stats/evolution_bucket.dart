import 'package:equatable/equatable.dart';

/// Une barre du rythme d'inscription.
///
/// ## Les libellés viennent du serveur, et c'est le point
///
/// [shortLabel] pour l'axe (« S36 », « sept. »), [longLabel] pour l'infobulle
/// (« semaine du 31 août au 6 septembre 2026 »). Le client ne les dérive
/// **jamais** de [key] : la règle de découpage — des tranches de sept jours
/// depuis le 1er, la dernière tronquée — vit côté serveur, et le libellé en
/// découle. Deux implémentations divergeraient.
///
/// ⚠️ **[key] n'est pas toujours une date.** Ce qui tombe hors de l'axe est
/// replié dans une barre de tête ou de queue, de clé `out-of-axis-before` /
/// `out-of-axis-after` — une seule date d'inscription mal saisie ramenait
/// sinon l'axe à 1900 avec quinze cents barres. Ne parsez pas [key], ne la
/// triez pas comme une date : elle identifie la barre, elle ne la date pas.
class EvolutionBucket extends Equatable {
  /// Identité technique de la barre. Se renvoie au serveur pour recadrer,
  /// jamais ne s'affiche et jamais ne se parse.
  final String key;

  /// Libellé court, pour l'axe.
  final String shortLabel;

  /// Libellé en toutes lettres, pour l'infobulle.
  final String longLabel;

  final int value;

  /// La barre en relief — celle de la période en cours.
  final bool isCurrent;

  const EvolutionBucket({
    required this.key,
    required this.shortLabel,
    required this.longLabel,
    required this.value,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, shortLabel, longLabel, value, isCurrent];
}
