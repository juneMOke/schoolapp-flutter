import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Les cinq fenêtres du tableau de bord de la boutique — **les mêmes que celles
/// du tableau de bord des inscriptions** : Aujourd'hui, Cette semaine, Ce mois,
/// Année, Période précise.
///
/// **Calendaires, et qui finissent aujourd'hui** : « Cette semaine » part du
/// lundi, « Ce mois » du 1er, « Année » de l'ouverture de l'année scolaire. Un
/// directeur qui passe d'un tableau de bord à l'autre doit compter la même
/// semaine partout.
///
/// Le serveur ne connaît pas ce vocabulaire : il reçoit `from` / `to`, et c'est
/// [windowAt] qui les calcule. La période précise n'en calcule pas — ses bornes
/// sont saisies à l'écran.
enum DashboardPeriod {
  today('TODAY'),

  /// Le défaut : assez pour voir une semaine de vente, pas trop pour noyer le
  /// jour.
  week('WEEK'),
  month('MONTH'),
  year('YEAR'),

  /// Jamais mémorisée : une plage précise répond à une question ponctuelle, et
  /// la retrouver des semaines plus tard ferait lire des chiffres figés comme
  /// ceux du jour.
  custom(null);

  const DashboardPeriod(this.storageKey);

  static const DashboardPeriod defaultPeriod = DashboardPeriod.week;

  /// La valeur mémorisée sur le poste, `null` si la période ne se mémorise pas.
  /// Un renommage de constante ne doit pas faire oublier le choix de
  /// l'utilisateur.
  final String? storageKey;

  /// Les clés des anciennes fenêtres glissantes, ramenées à leur plus proche
  /// voisine calendaire : le choix de l'utilisateur survit à la refonte.
  static const Map<String, DashboardPeriod> _legacyKeys = {
    'SEVEN_DAYS': DashboardPeriod.week,
    'THIRTY_DAYS': DashboardPeriod.month,
  };

  /// La fenêtre qui finit le jour **de l'école** à [now].
  ///
  /// Le jour de l'école, jamais celui de la tablette : un poste réglé en UTC
  /// changerait de fenêtre une heure trop tôt, et le tableau de bord ne
  /// compterait pas la même journée que la caisse serveur.
  ///
  /// [yearStart] n'est lu que par [year]. Inconnu, la fenêtre remonte au plus
  /// loin que le serveur accepte : il filtre de toute façon sur l'année
  /// scolaire, une borne trop large ne compte rien de plus.
  ///
  /// Lève sur [custom] : ses bornes ne se calculent pas.
  DashboardWindow windowAt(DateTime now, {DateTime? yearStart}) {
    final today = SchoolTime.today(now);
    final from = switch (this) {
      DashboardPeriod.today => today,
      // Par soustraction sur le quantième : `DateTime` normalise un jour
      // négatif en remontant le mois.
      DashboardPeriod.week => DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - DateTime.monday),
      ),
      DashboardPeriod.month => DateTime(today.year, today.month),
      DashboardPeriod.year => _yearFrom(today, yearStart),
      DashboardPeriod.custom => throw StateError(
        'DashboardPeriod.custom : la période précise n\'a pas de fenêtre '
        'calculée, ses bornes sont saisies.',
      ),
    };
    return DashboardWindow(from: from, to: today);
  }

  /// L'ouverture de l'année, bornée à ce que le serveur accepte — et jamais
  /// après aujourd'hui, ce qui ferait une fenêtre à l'envers.
  static DateTime _yearFrom(DateTime today, DateTime? yearStart) {
    final earliest = DashboardWindow.earliestFrom(today);
    final start = yearStart == null
        ? earliest
        : DateTime(yearStart.year, yearStart.month, yearStart.day);
    if (start.isBefore(earliest)) return earliest;
    if (start.isAfter(today)) return today;
    return start;
  }

  /// Relit une valeur mémorisée ; `null` si elle ne désigne rien.
  static DashboardPeriod? fromStorage(String? key) {
    if (key == null) return null;
    for (final period in values) {
      if (period.storageKey == key) return period;
    }
    return _legacyKeys[key];
  }
}
