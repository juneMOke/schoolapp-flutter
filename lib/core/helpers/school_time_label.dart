import 'package:school_app_flutter/core/helpers/school_time.dart';

/// L'horodatage d'une ligne de liste — un versement, une vente — lu à l'heure
/// **de l'école** (cf. [SchoolTime]).
///
/// Les instants arrivent en UTC ; les relire avec `toLocal()` les mettrait à
/// l'heure du poste, et un versement de 23 h 30 changerait de jour sur une
/// tablette réglée ailleurs qu'à Kinshasa.
abstract final class SchoolTimeLabel {
  /// « 14:05 » aujourd'hui, « 30/08 00:30 » cette année, « 30/08/2025 00:30 »
  /// avant.
  ///
  /// La date n'apparaît que si elle apprend quelque chose : sur la caisse du
  /// jour elle serait la même sur chaque ligne, et noierait l'heure, qui est
  /// ce qu'on cherche. L'année, de même, ne sert qu'à distinguer deux « 30/08 »
  /// d'une fenêtre qui chevauche le 1er janvier.
  ///
  /// « Aujourd'hui » se juge aussi à Kinshasa : la fenêtre des tableaux de bord
  /// s'y découpe, la ligne doit se lire dans le même temps.
  static String compact(DateTime instant, DateTime now) {
    final wall = SchoolTime.wallClock(instant);
    final today = SchoolTime.today(now);
    String two(int value) => value.toString().padLeft(2, '0');
    final time = '${two(wall.hour)}:${two(wall.minute)}';
    final dayMonth = '${two(wall.day)}/${two(wall.month)}';
    if (wall.year != today.year) return '$dayMonth/${wall.year} $time';
    final isToday = wall.month == today.month && wall.day == today.day;
    return isToday ? time : '$dayMonth $time';
  }
}
