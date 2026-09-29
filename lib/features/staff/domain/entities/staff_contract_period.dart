import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une période de la frise des contrats d'un agent, **sans montant** — ce que
/// porte la fiche, lisible sous `hr.staff.read`. Les montants vivent à part,
/// sous `hr.pay.read`.
class StaffContractPeriod extends Equatable {
  final String contractId;

  /// `null` pour un statut que ce poste ne connaît pas encore.
  final StaffContractKind? kind;
  final StaffPayMode? payMode;

  /// Jour d'effet, `YYYY-MM-DD`.
  final String effectiveFrom;

  /// Dernier jour prévu, `YYYY-MM-DD`, ou `null` (jusqu'à la période suivante).
  final String? endsOn;

  const StaffContractPeriod({
    required this.contractId,
    required this.kind,
    required this.effectiveFrom,
    this.payMode,
    this.endsOn,
  });

  /// Vacataire payé à l'heure : le Pointage lui ouvre la saisie d'heures.
  bool get isHourlyVacataire =>
      kind == StaffContractKind.vacataire && payMode == StaffPayMode.hourly;

  @override
  List<Object?> get props => [contractId, kind, payMode, effectiveFrom, endsOn];
}
