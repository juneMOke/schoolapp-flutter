import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Les trois fenêtres du tableau de bord de la boutique.
///
/// **Glissantes, et qui finissent aujourd'hui** — à ne pas confondre avec les
/// fenêtres calendaires de l'historique (« depuis lundi »). Le tableau de bord
/// répond à « combien vend-on ? », pas à « que dit l'arrêté de la semaine ? » :
/// « 7 jours » veut dire les sept derniers jours, aujourd'hui compris.
///
/// Le serveur ne connaît pas ce vocabulaire : il reçoit `from` / `to`, et c'est
/// [windowAt] qui les calcule.
enum DashboardPeriod {
  today(1, 'TODAY'),

  /// Le défaut : assez pour voir une semaine de rentrée, pas trop pour noyer
  /// le jour.
  sevenDays(7, 'SEVEN_DAYS'),
  thirtyDays(30, 'THIRTY_DAYS');

  const DashboardPeriod(this.dayCount, this.storageKey);

  static const DashboardPeriod defaultPeriod = DashboardPeriod.sevenDays;

  /// Le nombre de jours de la fenêtre, aujourd'hui compris.
  final int dayCount;

  /// La valeur mémorisée sur le poste. Un renommage de constante ne doit pas
  /// faire oublier le choix de l'utilisateur.
  final String storageKey;

  /// La fenêtre qui finit le jour **de l'école** à [now].
  ///
  /// Le jour de l'école, jamais celui de la tablette : un poste réglé en UTC
  /// changerait de fenêtre une heure trop tôt, et le tableau de bord ne
  /// compterait pas la même journée que la caisse serveur.
  DashboardWindow windowAt(DateTime now) {
    final today = SchoolTime.today(now);
    return DashboardWindow(
      from: DateTime(today.year, today.month, today.day - (dayCount - 1)),
      to: today,
    );
  }

  /// Relit une valeur mémorisée ; `null` si elle ne désigne rien.
  static DashboardPeriod? fromStorage(String? key) {
    for (final period in values) {
      if (period.storageKey == key) return period;
    }
    return null;
  }
}
