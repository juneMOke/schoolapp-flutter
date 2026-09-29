import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';

/// Lit la frise des contrats d'un agent : quel contrat est en vigueur un jour
/// donné.
///
/// Calculé sur le poste, hors ligne compris, à partir de la frise que porte la
/// fiche : un contrat « à compter du 1er novembre » prend effet ce jour-là sans
/// qu'aucune écriture n'ait lieu.
class StaffContractTimeline {
  StaffContractTimeline._();

  /// La période en vigueur le jour [day] (`YYYY-MM-DD`), ou `null` : aucun
  /// contrat posé, pas encore commencé, ou terminé sans successeur.
  ///
  /// Les jours se comparent en chaînes : `YYYY-MM-DD` s'ordonne comme les
  /// dates, sans fuseau à interpréter.
  static StaffContractPeriod? currentAt(
    List<StaffContractPeriod> periods,
    String day,
  ) {
    StaffContractPeriod? current;
    for (final period in periods) {
      if (period.effectiveFrom.compareTo(day) > 0) continue;
      final endsOn = period.endsOn;
      if (endsOn != null && endsOn.compareTo(day) < 0) continue;
      if (current == null ||
          period.effectiveFrom.compareTo(current.effectiveFrom) > 0) {
        current = period;
      }
    }
    return current;
  }
}
