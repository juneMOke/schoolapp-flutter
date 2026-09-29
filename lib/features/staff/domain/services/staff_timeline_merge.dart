import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// La frise d'un agent telle que la tablette doit la montrer : celle de la
/// fiche, corrigée par ce que le poste sait de plus récent — ses gestes pas
/// encore accusés, **et** ceux accusés que la fiche ne porte pas encore.
///
/// La fiche et les contrats descendent par deux flux : entre l'accusé d'un
/// geste et la descente suivante de la fiche, sa frise est en retard. Une
/// période posée disparaîtrait alors de l'écran, une période corrigée y
/// reviendrait.
///
/// Une pose refusée par le serveur n'y entre pas : elle n'est en vigueur
/// nulle part. La page agent la montre à part, avec son refus.
///
/// Calculée à la lecture, jamais écrite dans la fiche : la frise de la fiche
/// appartient au serveur, et une descente l'écrase. Y poser un contrat en
/// attente le ferait disparaître au premier pull, puis revenir à l'accusé.
abstract final class StaffTimelineMerge {
  /// [server] : la frise de la fiche. [local] : les contrats de cet agent
  /// rangés sur la tablette (tous états).
  static List<StaffContractPeriod> merge(
    List<StaffContractPeriod> server,
    List<StaffContract> local,
  ) {
    final hidden = {
      for (final contract in local)
        if (contract.isCorrected) contract.id,
    };
    final known = {for (final period in server) period.contractId};
    final merged = [
      for (final period in server)
        if (!hidden.contains(period.contractId)) period,
      for (final contract in local)
        if (!contract.isCorrected &&
            contract.syncState != StaffSyncState.failed &&
            !known.contains(contract.id))
          contract.asPeriod,
    ]..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return merged;
  }
}
