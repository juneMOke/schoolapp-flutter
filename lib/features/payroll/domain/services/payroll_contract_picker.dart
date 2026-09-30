import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Quel contrat paie un agent pour un mois.
abstract final class PayrollContractPicker {
  /// Une période qui compte : ni corrigée, ni refusée par le serveur.
  static bool isLive(StaffContract contract) =>
      !contract.isCorrected && contract.syncState != StaffSyncState.failed;

  /// Le contrat qui paie [month] (A2, sans prorata) : parmi les périodes
  /// vivantes qui recoupent le mois, **la dernière commencée** — celle qui est
  /// en vigueur au dernier jour qu'elle couvre. Un agent passé permanent le 15
  /// est payé en permanent tout le mois ; un CDD fini le 15 est payé sur ce
  /// contrat. Le même choix que `ContractInForce` du serveur.
  /// `null` : aucune période ne recoupe le mois.
  static StaffContract? pick(Iterable<StaffContract> contracts, String month) {
    StaffContract? latest;
    for (final contract in contracts.where(isLive)) {
      if (PayrollMonth.overlaps(
            month,
            contract.effectiveFrom,
            contract.endsOn,
          ) &&
          _later(contract, latest)) {
        latest = contract;
      }
    }
    return latest;
  }

  /// La plus récente ; à date d'effet égale, départagée par l'identifiant —
  /// jamais par l'ordre de lecture, que le serveur ne partage pas.
  static bool _later(StaffContract contract, StaffContract? current) {
    if (current == null) return true;
    final byDate = contract.effectiveFrom.compareTo(current.effectiveFrom);
    return byDate > 0 || (byDate == 0 && contract.id.compareTo(current.id) > 0);
  }
}
