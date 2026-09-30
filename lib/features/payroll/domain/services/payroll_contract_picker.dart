import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Quel contrat paie un agent pour un mois.
abstract final class PayrollContractPicker {
  /// Une période qui compte : ni corrigée, ni refusée par le serveur.
  static bool isLive(StaffContract contract) =>
      !contract.isCorrected && contract.syncState != StaffSyncState.failed;

  /// Le contrat en vigueur au **dernier jour** de [month] (A2, sans prorata).
  ///
  /// Un agent figure au livre dès qu'une période vivante recoupe le mois
  /// (E5) : si aucune n'est encore en vigueur au dernier jour — un CDD fini le
  /// 15 —, c'est la dernière période commencée dans le mois qui paie.
  /// `null` : aucune période ne recoupe le mois.
  static StaffContract? pick(Iterable<StaffContract> contracts, String month) {
    final lastDay = PayrollMonth.lastDay(month);
    StaffContract? inForce;
    StaffContract? overlapping;
    for (final contract in contracts.where(isLive)) {
      if (!PayrollMonth.overlaps(
        month,
        contract.effectiveFrom,
        contract.endsOn,
      )) {
        continue;
      }
      if (_later(contract, overlapping)) overlapping = contract;
      final endsOn = contract.endsOn;
      final coversLastDay =
          contract.effectiveFrom.compareTo(lastDay) <= 0 &&
          (endsOn == null || endsOn.compareTo(lastDay) >= 0);
      if (coversLastDay && _later(contract, inForce)) inForce = contract;
    }
    return inForce ?? overlapping;
  }

  static bool _later(StaffContract contract, StaffContract? current) =>
      current == null ||
      contract.effectiveFrom.compareTo(current.effectiveFrom) > 0;
}
