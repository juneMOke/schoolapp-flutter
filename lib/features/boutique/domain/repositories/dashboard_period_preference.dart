import 'package:school_app_flutter/core/entities/dashboard_period.dart';

/// La période du tableau de bord, retenue **par utilisateur** d'une visite à
/// l'autre : un directeur qui suit le mois ne doit pas refaire le geste à chaque
/// ouverture.
///
/// Ne lève jamais : une préférence perdue coûte un geste, pas un écran.
abstract class DashboardPeriodPreference {
  /// `null` : aucun choix encore fait, ou lecture impossible.
  Future<DashboardPeriod?> read();

  Future<void> write(DashboardPeriod period);
}
