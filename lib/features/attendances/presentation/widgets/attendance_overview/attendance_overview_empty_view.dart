import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Etat vide du tableau de bord de presence (Disciplines > Tableau de bord).
///
/// S'appuie sur le widget partage [EteeloEmptyResult] et propose, le cas
/// echeant, une action pour saisir des presences. L'action n'est affichee
/// que si [onTakeAttendance] est fourni.
class AttendanceOverviewEmptyView extends StatelessWidget {
  /// Declenche la prise de presence ; si null, aucune action n'est affichee.
  final VoidCallback? onTakeAttendance;

  const AttendanceOverviewEmptyView({super.key, this.onTakeAttendance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EteeloEmptyResult(
      medallionIcon: Icons.event_available_outlined,
      label: l10n.attendanceOverviewEmptyTitle,
      description: l10n.attendanceOverviewEmptyDescription,
      fullWidthCard: true,
      autofocusPrimaryAction: onTakeAttendance != null,
      primaryAction: onTakeAttendance == null
          ? null
          : EteeloButton.primary(
              label: l10n.attendanceOverviewEmptyAction,
              icon: Icons.how_to_reg_outlined,
              onPressed: onTakeAttendance,
              fullWidth: false,
            ),
    );
  }
}
