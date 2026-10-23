import 'package:school_app_flutter/core/helpers/school_time.dart';

/// L'heure **de l'école** d'une vente : `sold_at` est en UTC, et l'afficher tel
/// quel décalerait chaque vente au guichet.
abstract final class BoutiqueSaleTime {
  /// « 14:05 » pour une vente d'aujourd'hui, « 30/08 00:30 » sinon.
  ///
  /// La date n'apparaît que si la vente n'est pas d'aujourd'hui : sur la caisse
  /// du jour elle serait la même sur chaque ligne, et noierait l'heure, qui est
  /// ce qu'on cherche.
  ///
  /// Un horodatage illisible ne fait pas disparaître la vente : le montant et le
  /// payeur restent la raison d'être de la ligne.
  static String of(String soldAt, DateTime now) {
    final parsed = DateTime.tryParse(soldAt);
    if (parsed == null) return soldAt;
    // L'heure de l'école, et « aujourd'hui » aussi : la fenêtre du tableau de
    // bord se découpe à Kinshasa, la ligne doit se lire dans le même temps.
    final wall = SchoolTime.wallClock(parsed);
    final today = SchoolTime.today(now);
    String two(int value) => value.toString().padLeft(2, '0');
    final time = '${two(wall.hour)}:${two(wall.minute)}';
    final isToday =
        wall.year == today.year &&
        wall.month == today.month &&
        wall.day == today.day;
    return isToday ? time : '${two(wall.day)}/${two(wall.month)} $time';
  }
}
