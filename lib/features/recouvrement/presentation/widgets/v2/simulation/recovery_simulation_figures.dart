import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_texts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_verdict.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les classes qui passeraient sous le seuil, dans l'ordre du serveur.
List<RecoverySimulationRow> recoveryUnmanageableRows(
  RecoverySimulation simulation,
  int unmanageableBelow,
) => [
  for (final row in simulation.rows)
    if (RecoveryVerdict.of(row, unmanageableBelow) ==
        RecoveryVerdict.unmanageable)
      row,
];

/// Les quatre pavés (`RecMini`) : effectif, visés, restant, ingérables.
List<EteeloKpiCardData> recoverySimulationCards({
  required RecoverySimulation simulation,
  required String targetedDescription,
  required int unmanageableBelow,
  required AppLocalizations l10n,
}) {
  final kept = recoveryKeptPercent(
    simulation.remainingHeadcount,
    simulation.headcount,
  );
  final below =
      simulation.headcount > 0 &&
      RecoveryVerdict.ofCounts(
            simulation.remainingHeadcount,
            simulation.headcount,
            unmanageableBelow,
          ) ==
          RecoveryVerdict.unmanageable;
  final unmanageable = recoveryUnmanageableRows(simulation, unmanageableBelow);
  final remainingAccent = below ? AppColors.error : AppColors.vertSavane;
  return [
    _card(
      label: l10n.recoverySimulationHeadcount,
      value: simulation.headcount,
      accent: AppColors.bleuArdoise,
      soft: AppColors.bleuArdoiseSoft,
      icon: Icons.groups_outlined,
      subline: l10n.recoverySimulationHeadcountSub,
    ),
    _card(
      label: l10n.recoverySimulationTargeted,
      value: simulation.targetedStudents,
      accent: AppColors.error,
      soft: AppColors.feeStatusDueSoft,
      icon: Icons.person_remove_outlined,
      subline: targetedDescription,
    ),
    _card(
      label: l10n.recoverySimulationRemaining,
      value: simulation.remainingHeadcount,
      accent: remainingAccent,
      soft: below ? AppColors.feeStatusDueSoft : AppColors.feeStatusPaidSoft,
      icon: Icons.how_to_reg_outlined,
      subline: l10n.recoverySimulationRemainingSub(kept),
    ),
    _card(
      label: l10n.recoverySimulationUnmanageable,
      value: unmanageable.length,
      accent: AppColors.feeStatusPartial,
      soft: AppColors.feeStatusPartialSoft,
      icon: Icons.warning_amber_rounded,
      subline: _names(unmanageable, l10n),
    ),
  ];
}

/// « 2ème humanités, 3ème humanités… » ou « aucune sous le seuil ».
String _names(List<RecoverySimulationRow> rows, AppLocalizations l10n) {
  if (rows.isEmpty) return l10n.recoverySimulationUnmanageableNone;
  final first = rows.first.classroomName;
  final two = rows.length == 1
      ? first
      : l10n.recoverySimulationUnmanageableTwo(first, rows[1].classroomName);
  return rows.length > 2 ? l10n.recoverySimulationUnmanageableMore(two) : two;
}

EteeloKpiCardData _card({
  required String label,
  required int value,
  required Color accent,
  required Color soft,
  required IconData icon,
  required String subline,
}) => EteeloKpiCardData(
  label: label,
  value: value,
  accent: accent,
  accentSoft: soft,
  icon: icon,
  subline: subline,
  filledBackground: DashboardTones.pave(DashboardTones.paveAccentSur(accent)),
);

/// La note de pied (`FinNote`) : ce que le renvoi ferait perdre et ce qu'il
/// abandonnerait, **par devise, jamais additionnés**. Muette quand personne
/// n'est visé : il n'y aurait rien à chiffrer.
class RecoverySimulationNote extends StatelessWidget {
  final RecoverySimulation simulation;

  const RecoverySimulationNote({super.key, required this.simulation});

  @override
  Widget build(BuildContext context) {
    if (simulation.targetedStudents <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final missing = recoveryAmountsText(simulation.abandonedOutstanding, l10n);
    final cost = recoveryAllZero(simulation.lostCollected)
        ? l10n.recoverySimulationNoteNothingLost(missing)
        : l10n.recoverySimulationNoteWithLoss(
            recoveryAmountsText(simulation.lostCollected, l10n),
            missing,
          );
    return EteeloNotice.tinted(
      message: '${l10n.recoverySimulationNoteLead} $cost',
      icon: Icons.info_outline,
      ink: AppColors.textSecondary,
      background: ColorMix.tint(AppColors.surfaceAlt, AppColors.bleuArdoise, 4),
      border: ColorMix.tint(AppColors.border, AppColors.bleuArdoise, 12),
    );
  }
}
