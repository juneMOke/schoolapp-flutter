import 'package:equatable/equatable.dart';

/// Une barre de la série : un jour (`2026-10-15`) ou une heure
/// (`2026-10-21T07`) de la fenêtre, et ce qui s'y est vendu.
///
/// La série est **dense** : un seau par pas, zéros et dimanches compris. C'est
/// l'écran qui décide de retirer un dimanche vide ou des heures creuses.
class BoutiqueStatsBucket extends Equatable {
  /// La clé servie, telle quelle. Elle est l'identité du seau : c'est sur elle
  /// que se fusionnent les tickets provisoires.
  final String key;

  /// En centimes, dans la devise du bloc qui porte le seau.
  final int total;

  const BoutiqueStatsBucket({required this.key, required this.total});

  /// Le jour du seau (minuit), `null` si la clé ne se lit pas.
  DateTime? get day {
    if (key.length < 10) return null;
    return DateTime.tryParse(key.substring(0, 10));
  }

  /// L'heure du seau (`T07` → 7), `null` pour un seau de jour.
  int? get hour {
    final t = key.indexOf('T');
    if (t < 0 || t + 3 > key.length) return null;
    return int.tryParse(key.substring(t + 1, t + 3));
  }

  BoutiqueStatsBucket plus(int cents) =>
      BoutiqueStatsBucket(key: key, total: total + cents);

  @override
  List<Object?> get props => [key, total];
}
