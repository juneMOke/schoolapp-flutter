import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';

/// Une fenêtre de jours **de l'école**, bornes incluses — la forme exacte du
/// `from` / `to` des tableaux de bord servis (`GET /boutique/stats`,
/// `GET /hr/attendance-stats`).
///
/// Les deux bornes sont des jours (minuit, champs de calendrier seuls) : une
/// heure n'a pas de sens ici, le serveur découpe dans le fuseau de l'école.
class DashboardWindow extends Equatable {
  /// La plus large fenêtre que ces routes acceptent, bornes comprises —
  /// au-delà, un 400.
  static const int maxDayCount = 366;

  final DateTime from;
  final DateTime to;

  DashboardWindow({required DateTime from, required DateTime to})
    : from = DateTime(from.year, from.month, from.day),
      to = DateTime(to.year, to.month, to.day);

  /// Le premier jour le plus ancien d'une fenêtre qui finit à [to] et que le
  /// serveur accepte encore.
  static DateTime earliestFrom(DateTime to) =>
      DateTime(to.year, to.month, to.day - (maxDayCount - 1));

  /// Le dernier jour le plus lointain d'une fenêtre qui part de [from].
  static DateTime latestTo(DateTime from) =>
      DateTime(from.year, from.month, from.day + (maxDayCount - 1));

  /// Le nombre de jours, bornes comprises.
  int get dayCount =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
      1;

  /// Une seule journée : le serveur découpe alors heure par heure.
  bool get isSingleDay => dayCount == 1;

  /// Le premier jour de la fenêtre **précédente**, de même largeur — celle
  /// contre laquelle le serveur calcule les `previous*`.
  DateTime get previousFrom =>
      DateTime(from.year, from.month, from.day - dayCount);

  /// Le premier instant de la fenêtre, en UTC : minuit **à Kinshasa** le jour
  /// [from].
  DateTime get startInstant =>
      SchoolTime.instantAt(day: from, hour: 0, minute: 0);

  /// Le premier instant **après** la fenêtre, en UTC : minuit à Kinshasa le
  /// lendemain de [to]. Borne exclusive.
  DateTime get endInstantExclusive => SchoolTime.instantAt(
    day: DateTime(to.year, to.month, to.day + 1),
    hour: 0,
    minute: 0,
  );

  /// Vrai si [instant], lu à Kinshasa, tombe dans la fenêtre.
  bool containsInstant(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(startInstant) && utc.isBefore(endInstantExclusive);
  }

  @override
  List<Object?> get props => [from, to];
}
